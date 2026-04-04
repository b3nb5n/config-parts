flakeArgs@{ inputs, lib, config, ... }:
let
  inherit (lib) mkOption literalExpression;

  inherit (lib.types)
    raw anything bool str enum uniq nullOr listOf lazyAttrsOf functionTo
    submodule deferredModule;

  argsLib = import ./args.nix flakeArgs;
in {
  options.flake = {
    nixosConfigurationArgs' = mkOption {
      type = listOf deferredModule;
      default = [ ];
      description =
        "Modules to be merged into all nixos configuration arguments.";
    };

    nixosConfigurationArgs = mkOption {
      default = { };
      description = ''
        Arguments to the `_constructor` when creating the nixos configuration.

        The attribute name of the nixos configuration's flake output is 
        passed as an argument `outputName` to this module.
      '';

      type = lazyAttrsOf (submodule ({ name, ... }: {
        imports = config.flake.nixosConfigurationArgs';

        options = {
          _constructor = mkOption {
            type = uniq (functionTo raw);
            defaultText = literalExpression "imports.nixpkgs.lib.nixosSystem";
            description =
              "The function applied to these arguments to create the nixos configuration.";
          };

          # based on definitions from:
          # https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/eval-config.nix

          system = mkOption {
            type = nullOr (enum lib.systems.flakeExposed);
            default = null;
            description = ''
              Specifies the platform on which the configuration should be built.
              Configured modularly by default (see `options.nixpkgs.hostSystem`).
            '';
          };

          pkgs = mkOption {
            type = nullOr (lib.types.pkgs);
            default = null;
            description = ''
              An instance of nixpkgs used when evaluating the configuration.
              Configured modularly by default (see `options.nixpkgs`).
            '';
          };

          baseModules = mkOption {
            type = argsLib.excludedOr (listOf deferredModule);
            default = argsLib.excluded;
            description = "Modules that declare the base nixos options.";
          };

          extraArgs = mkOption {
            type = argsLib.excludedOr (lazyAttrsOf anything);
            default = argsLib.excluded;
            description = "DEPRECATED. Please set `_module.args` instead.";
          };

          specialArgs = mkOption {
            type = lazyAttrsOf anything;
            default = { };
            description = ''
              Externally provided module arguments that can't be modified from
              within a configuration, but can be used in module imports.

              This should only be used for special arguments that need to be evaluated
              when resolving module structure (like in imports). For everything else,
              there's `_module.args`.
            '';
          };

          modules = mkOption {
            type = listOf deferredModule;
            description = ''
              Modules to be merged into the nixos configuration.
              The attribute name of the nixos configuration's flake output is 
              passed as an argument `outputName` to these modules.
            '';
          };

          modulesLocation = mkOption {
            type = nullOr str;
            default = null;
            description = ''
              The source path of the `modules` declaration.
              `config-parts` already tracks the source file of all argument declarations. 
              Setting this option will probably make your error reporting worse.
            '';
          };

          check = mkOption {
            type = argsLib.excludedOr bool;
            default = argsLib.excluded;
            description = "DEPRECATED. Please set `_module.check` instead.";
          };

          prefix = mkOption {
            type = uniq (listOf str);
            default = [ ];
            description =
              "Option attribute path relative to an external root module.";
          };

          lib = mkOption {
            type = argsLib.excludedOr raw;
            default = argsLib.excluded;
            description =
              "An instance of nixpkgs lib to use when constructing the configuration.";
          };

          extraModules = mkOption {
            type = listOf deferredModule;
            default = [ ];
            description = "Extra modules that are neither base modules nor user modules.";
          };
        };

        config = rec {
          _module.args.outputName = name;

          _constructor = lib.mkIf (inputs ? "nixpkgs")
            (lib.mkDefault inputs.nixpkgs.lib.nixosSystem);

          modules = [{ inherit _module; }];
        };
      }));
    };
  };

  config.flake.nixosConfigurations = let
    mkConfig = args: args._constructor (argsLib.filter args);
    mkConfigs = lib.attrsets.mapAttrs (_name: mkConfig);
  in mkConfigs config.flake.nixosConfigurationArgs;
}
