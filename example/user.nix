{ self, ... }: {
  flake = {
    homeConfigurationArgs' = [
      ({ lib, outputUser, outputHost, ... }: {
        # Inherit the host configuration's `pkgs` by default.
        pkgs = lib.mkIf (outputHost != null && self.nixosConfigurations ? ${outputHost})
          (lib.mkDefault self.nixosConfigurations.${outputHost}.pkgs);

        modules = [
          ({ config, ... }: {
            programs.home-manager.enable = true;

            home = {
              username = lib.mkDefault outputUser;
              homeDirectory = "/home/${config.home.username}";
            };
          })
        ];
      })
    ];

    nixosConfigurationArgs.host.modules = [{
      users.users.user = {
        isNormalUser = true;
        extraGroups = [ "wheel" "video" "audio" ];
      };
    }];

    homeConfigurationArgs."user@host".modules = [{
      home.stateVersion = "25.11";
      programs.zsh.enable = true;
    }];
  };
}
