{
  flake = {
    nixosConfigurationArgs' = [{
      modules = [
        ({ lib, outputName, ... }: {
          networking.hostName = lib.mkDefault outputName;
          nixpkgs.config.allowUnfree = true;
        })
      ];
    }];

    nixosConfigurationArgs.host.modules = [{
      system.stateVersion = "25.11";
      nixpkgs.hostPlatform = "x86_64-linux";
      boot.loader.systemd-boot.enable = true;
      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXOS";
        fsType = "ext4";
      };
    }];
  };
}
