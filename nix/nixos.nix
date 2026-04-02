{ inputs, lib, config, ... }@flakeArgs:
let
  flakeLib = import ./lib.nix flakeArgs;
  inherit (flakeLib) argsLib;

  inherit (lib.types)
    unspecified uniq bool str enum nullOr listOf lazyAttrsOf functionTo
    submodule deferredModule;

  optionArgs = {
    _constructor = { type = uniq (functionTo unspecified); };

    # based on definitions from:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/eval-config.nix

    modules = { type = listOf deferredModule; };

    system = { type = nullOr (enum lib.systems.flakeExposed); };
    pkgs = { type = nullOr (uniq unspecified); };
    baseModules = { type = nullOr (listOf deferredModule); };
    extraArgs = { type = nullOr (lazyAttrsOf (uniq unspecified)); };
    specialArgs = { type = nullOr (lazyAttrsOf (uniq unspecified)); };
    modulesLocation = { type = nullOr str; };
    check = { type = nullOr bool; };
    prefix = { type = nullOr (listOf str); };
    lib = { type = nullOr (uniq unspecified); };
    extraModules = { type = nullOr (listOf deferredModule); };
  };
in {
  options.flake = {
    nixosConfigurationArgs' = lib.mkOption {
      default = { };
      type = submodule { options = argsLib.mkGlobalOptions optionArgs; };
    };

    nixosConfigurationArgs = lib.mkOption {
      default = { };
      type = lazyAttrsOf (submodule ({ name, ... }: {
        options = argsLib.mkOptions optionArgs;

        config = lib.mkMerge [
          (argsLib.filterExcluded config.flake.nixosConfigurationArgs')

          {
            _constructor = lib.mkIf (inputs ? "nixpkgs")
              (lib.mkDefault inputs.nixpkgs.lib.nixosSystem);

            modules = [{ _module.args.outputName = name; }];
          }
        ];
      }));
    };
  };

  config.flake.nixosConfigurations = let
    mkConfig = args: args._constructor (argsLib.filter args);
    mkConfigs = lib.attrsets.mapAttrs (_name: mkConfig);
  in mkConfigs config.flake.nixosConfigurationArgs;
}
