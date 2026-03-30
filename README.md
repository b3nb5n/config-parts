# Config Parts

_Modularly construct nixos and home manager configurations._

`config-parts` provides flake parts modules that represent the arguments to the
standard constructors for the supported configurations and constructs 

`config-parts` aims to be a minimal mirror of each constructor's
arguments. It is _very_ lightweight.

## Install

Add `config-parts` to the inputs of your `flake.nix`

```nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    config-parts = {
      url = "github:b3nb5n/config-parts";

      # `config-parts` has no inputs! No need to add any `follows` attributes.
      # inputs = {};
    };
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
        boot.loader.systemd-boot.enable = true;

        # `config-parts` defaults `networking.hostName` to `outputName`.
        # networking.hostName = outputName;
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
  imports = [ inputs.config-parts.flakeModules.homeManager ];

  flake.homeConfigurationArgs."<user>@<host>" = {
    # Put the arguments you would normally pass to
    # `home-manager.lib.homeManagerConfiguration` here.

    # `config-parts` defaults `pkgs` to the `pkgs` attribute of the
    # corresponding `<host>` configuration.
    #
    # If the output name doesn't include a `<host>` or the `<host>`
    # configuration isn't in the flake you must provide `pkgs` manually.
    # 
    # pkgs = config.flake.nixosConfigurations."<host>".pkgs;

    modules = [
      # In addition to `outputName`, `config-parts` passes the arguments
      # `outputUser` and `outputHost` with the values of `<user>` and `<host>`.
      #
      # `outputHost` is only passed if the output includes a `<host>`.
      # Shared modules should provide a default.
      ({ outputUser, outputHost ? null, ... }: {
        home = {
          stateVersion = "25.11";
          homeDirectory = "/home/${outputUser}";

          # `config-parts` defaults `home.username` to `outputUser`.
          # username = outputUser;
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

```nix
{ lib, config, ... }: {
  flake = {
    # Use the `<output>'` attribute to set arguments for all configurations.
    nixosConfigurationArgs' = {
      check = false;
      modules = [{ nixpkgs.config.allowUnfree = true; }];
    };

    nixosConfigurationArgs."<host>" = {
      # Use `lib.mkForce` to override global arguments.
      check = lib.mkForce false;
    };
  };
}
```

## Overriding the Constructor

`config-parts` gets it's inputs by name from the inputs of _your_ flake.
If you use a non-standard input name you must pass the constructor explicitly.

```nix
{ inputs, ... }: {
  flake = {
    # Use the `_constructor` argument to set the configuration constructor function.
    nixosConfigurationArgs'._constructor =
      inputs.nixpkgs-unstable.lib.nixosSystem;
  };
}
```

## Supported Configurations

| Configuration | Module | Output | Input | Constructor |
| --- | --- | --- | --- | --- |
| NixOS | `nixos` | `nixosConfigurationArgs` |  `nixpkgs` | `lib.nixosSystem` |
| Home Manager | `homeManager` | `homeConfigurationArgs` | `home-manager` | `lib.homeManagerConfiguration` |

