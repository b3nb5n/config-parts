{ inputs, lib, config, ... }@flakeArgs:
let
  flakeLib = import ./lib.nix flakeArgs;
  inherit (flakeLib) argsLib hmLib;

  inherit (lib.types)
    unspecified uniq bool nullOr listOf lazyAttrsOf functionTo submodule
    deferredModule;

  optionArgs = {
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
in {
  options.flake = {
    homeConfigurationArgs' = lib.mkOption {
      default = { };
      type = submodule { options = argsLib.mkGlobalOptions optionArgs; };
    };

    homeConfigurationArgs = lib.mkOption {
      default = { };
      type = lazyAttrsOf (submodule ({ name, ... }: {
        options = argsLib.mkOptions optionArgs;

        config = lib.mkMerge [
          (argsLib.filterExcluded config.flake.homeConfigurationArgs')

          {
            _constructor = lib.mkIf (inputs ? "home-manager")
              (lib.mkDefault inputs.home-manager.lib.homeManagerConfiguration);

            modules = [{ _module.args = hmLib.parseOutputName name; }];
          }
        ];
      }));
    };
  };

  config.flake.homeConfigurations = let
    mkConfig = args: args._constructor (argsLib.filter args);
    mkConfigs = lib.attrsets.mapAttrs (_name: mkConfig);
  in mkConfigs config.flake.homeConfigurationArgs;
}
