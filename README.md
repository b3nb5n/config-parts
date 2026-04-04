# Config Parts

_Modularly construct NixOS and Home Manager configurations._

`config-parts` provides [flake-parts](https://github.com/hercules-ci/flake-parts) 
modules that represent the arguments to `nixpkgs.lib.nixosSystem` and
`home-manager.lib.homeManagerConfiguration`. The configurations are then
created by applying the constructors to the provided arguments.

`config-parts` aims to be a minimal mirror of each constructor's
arguments. It is _very_ lightweight.

## Install

Add `config-parts` to the inputs of your `flake.nix`

```nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    # `config-parts` has no inputs! No need to add any `follows` attributes.
    config-parts.url = "github:b3nb5n/config-parts";
  };
}
```

## Nixos

```nix
{ inputs, config, ... }: {
  # Import the nixos module.
  imports = [ inputs.config-parts.flakeModules.nixos ];

  flake.nixosConfigurationArgs."<host>" = {
    # Put the arguments you would normally pass to
    # `nixpkgs.lib.nixosSystem` here.

    system = "x86_64-linux";

    modules = [
      # `config-parts` passes the argument `outputName` with the value of `<host>`.
      ({ outputName, ... }: {
        system.stateVersion = "25.11";
        networking.hostName = outputName;
      })
    ];
  };

  # `config-parts` constructs the configuration from its args.
  #
  # flake.nixosConfigurations."<host>" = inputs.nixpkgs.lib.nixosSystem
  #   config.flake.nixosConfigurationArgs."<host>";
}
```

## Home Manager

```nix
{ inputs, config, ... }: {
  # Import the home manager module.
  imports = [ inputs.config-parts.flakeModules.home-manager ];

  flake.homeConfigurationArgs."<user>@<host>" = {
    # Put the arguments you would normally pass to
    # `home-manager.lib.homeManagerConfiguration` here.

    pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };

    modules = [
      # In addition to `outputName`, `config-parts` passes the arguments
      # `outputUser` and `outputHost` with the values of `<user>` and `<host>`.
      # If the output name doesn't include a `<host>`, `outputHost` is null.
      ({ outputUser, outputHost, ... }: {
        home = {
          stateVersion = "25.11";
          username = outputUser;
          homeDirectory = "/home/${outputUser}";
        };
      })
    ];
  };

  # `config-parts` constructs the configuration from its args.
  #
  # flake.homeConfigurations."<user>@<host>" =
  #   inputs.home-manager.lib.homeManagerConfiguration
  #     config.flake.homeConfigurationArgs."<user>@<host>";
}
```

## Global Arguments

Use the `<output>'` attribute to set modules to be merged into all arguments.

```nix
{ lib, config, self, ... }: {
  flake = {
    nixosConfigurationArgs' = [{
      # These modules will be be included in all nixos configurations.
      modules = [
        ({ outputName, ... }: {
          nixpkgs.config.allowUnfree = true; 
          networking.hostName = lib.mkDefault outputName;
        })
      ];
    }];

    homeConfigurationArgs' = [
      # The `config-parts` arguments are also passed to these global modules.
      ({ outputUser, outputHost, ... }: {
        # Inherit the host configuration's `pkgs` by default.
        pkgs = lib.mkIf (outputHost != null && self.nixosConfigurations ? ${outputHost})
          (lib.mkDefault self.nixosConfigurations.${outputHost}.pkgs);

        modules = [{ home.username = lib.mkDefault outputUser; }];
      })
    ];
  };
}
```

## Overriding the Constructor

`config-parts` gets it's inputs by name from the inputs of _your_ flake.
If you use a non-standard input name you must pass the constructor explicitly.

```nix
{ inputs, ... }: {
  flake = {
    # Use the `_constructor` argument to set function applied to the arguments
    # to construct the configuration.
    nixosConfigurationArgs.host._constructor =
      inputs.nixpkgs-unstable.lib.nixosSystem;

    # Use a global argument to set a default `_consturctor` for all configurations
    homeConfigurationArgs' = [{
      _constructor = lib.mkDefault inputs.hm.lib.homeManagerConfiguration;
    }];
  };
}
```

## Supported Configurations

| Configuration | Module | Output | Input | Constructor |
| --- | --- | --- | --- | --- |
| NixOS | `nixos` | `nixosConfigurationArgs` |  `nixpkgs` | `lib.nixosSystem` |
| Home Manager | `homeManager` | `homeConfigurationArgs` | `home-manager` | `lib.homeManagerConfiguration` |

