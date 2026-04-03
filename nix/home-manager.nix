{ inputs, lib, config, ... }@flakeArgs:
let
  flakeLib = import ./lib.nix flakeArgs;
  inherit (flakeLib) argsLib hmLib;

  inherit (lib.types)
    unspecified uniq bool nullOr listOf lazyAttrsOf functionTo submodule
    deferredModule;
in {
  options.flake = {
    homeConfigurationArgs' = lib.mkOption {
      default = [ ];
      type = listOf deferredModule;
    };

    homeConfigurationArgs = lib.mkOption {
      default = { };
      type = lazyAttrsOf (submodule ({ name, ... }: {
        imports = config.flake.homeConfigurationArgs';

        options = argsLib.mkOptions {
          _constructor = { type = uniq (functionTo unspecified); };

          # based on definitions from:
          # https://github.com/nix-community/home-manager/blob/master/lib/default.nix

          modules = { type = listOf deferredModule; };
          pkgs = { type = uniq unspecified; };

          check = { type = nullOr bool; };
          extraSpecialArgs = { type = nullOr (lazyAttrsOf (uniq unspecified)); };
          lib = { type = nullOr (uniq unspecified); };
          minimal = { type = nullOr bool; };
        };

        config = rec {
          _module.args = hmLib.parseOutputName name;

          _constructor = lib.mkIf (inputs ? "home-manager")
            (lib.mkDefault inputs.home-manager.lib.homeManagerConfiguration);

          modules = [{ inherit _module; }];
        };
      }));
    };
  };

  config.flake.homeConfigurations = let
    mkConfig = args: args._constructor (argsLib.filter args);
    mkConfigs = lib.attrsets.mapAttrs (_name: mkConfig);
  in mkConfigs config.flake.homeConfigurationArgs;
}
