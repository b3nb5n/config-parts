{ inputs, lib, config, ... }@flakeArgs:
let
  flakeLib = import ./lib.nix flakeArgs;

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
      type = let options = flakeLib.options.mkNullableOptions optionArgs;
      in submodule { inherit options; };
    };

    homeConfigurationArgs = lib.mkOption {
      default = { };
      type = lazyAttrsOf (submodule ({ name, ... }:
        let
          output = flakeLib.homeManager.parseOutputName name;

          outputUser = output.outputUser;
          outputHost = output.outputHost or null;
        in {
          options = flakeLib.options.mkOptions optionArgs;

          imports = [
            (flakeLib.config.mkGlobalModule config.flake.homeConfigurationArgs')
            (flakeLib.homeManager.mkHostPkgsModule outputHost)
          ];

          config = {
            _constructor = lib.mkIf (inputs ? "home-manager")
              (lib.mkDefault inputs.home-manager.lib.homeManagerConfiguration);

            modules = [{
              _module.args = output // { outputName = name; };
              home.username = lib.mkDefault outputUser;
            }];
          };
        }));
    };
  };

  config.flake.homeConfigurations = let
    mkConfig = args: args._constructor (flakeLib.config.filter args);
    mkConfigs = lib.attrsets.mapAttrs (_name: mkConfig);
  in mkConfigs config.flake.homeConfigurationArgs;
}
