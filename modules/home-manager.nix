flakeArgs@{ inputs, lib, config, ... }:
let
  inherit (lib) mkOption literalExpression;

  inherit (lib.types)
    raw anything bool uniq listOf lazyAttrsOf functionTo submodule
    deferredModule;

  argsLib = import ./args.nix flakeArgs;
in {
  options.flake = {
    homeConfigurationArgs' = mkOption {
      type = listOf deferredModule;
      default = [ ];
      description =
        "Modules to be merged into all home configuration arguments.";
    };

    homeConfigurationArgs = mkOption {
      default = { };
      description = ''
        Arguments to the `_constructor` when creating the home configuration.

        The attribute name of the home configuration's flake output is 
        passed as an argument `outputName` to this module. The parsed
        `outputName` is also passed as arguments `outputUser` and `outputHost`.
      '';

      type = lazyAttrsOf (submodule (moduleArgs@{ name, ... }: {
        imports = config.flake.homeConfigurationArgs';

        options = {
          _constructor = mkOption {
            type = uniq (functionTo raw);
            defaultText = literalExpression
              "imports.home-manager.lib.homeManagerConfiguration";
            description =
              "The function applied to these arguments to create the home configuration.";
          };

          # based on definitions from:
          # https://github.com/nix-community/home-manager/blob/master/lib/default.nix

          check = mkOption {
            type = bool;
            default = true;
            description = ''
              Whether to check that each option has a matching declaration.
              Can be configured modularly via `_module.check`.
            '';
          };

          extraSpecialArgs = mkOption {
            type = lazyAttrsOf anything;
            default = { };
            description = ''
              Extra arguments passed to `specialArgs`.

              This should only be used for special arguments that need to be evaluated
              when resolving module structure (like in imports). For everything else,
              there's `_module.args`.
            '';
          };

          lib = mkOption {
            type = raw;
            default = moduleArgs.config.pkgs.lib;
            defaultText = literalExpression "pkgs.lib";
            description =
              "An instance of nixpkgs lib to use when constructing the configuration.";
          };

          modules = mkOption {
            type = listOf deferredModule;
            description = ''
              Modules to be merged into the home configuration.

              The attribute name of the home configuration's flake output is 
              passed as an argument `outputName` to these modules. The parsed
              `outputName` is also passed as arguments `outputUser` and `outputHost`.
            '';
          };

          pkgs = mkOption {
            type = lib.types.pkgs;
            description =
              "An instance of nixpkgs to use when constructing the configuration.";
          };

          minimal = mkOption {
            type = bool;
            default = false;
            description =
              "Whether the standard `services` and `programs` options should be excluded.";
          };
        };

        config = rec {
          _module.args = let
            components = lib.strings.splitString "@" name;
            component = idx:
              if idx < (builtins.length components) then
                builtins.elemAt components idx
              else
                null;
          in {
            outputName = name;
            outputUser = component 0;
            outputHost = component 1;
          };

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
