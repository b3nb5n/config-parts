{
  description = "Modularly construct NixOS and Home Manager configurations.";

  outputs = _inputs: {
    flakeModules = {
      home-manager = ./modules/home-manager.nix;
      nixos = ./modules/nixos.nix;
    };
  };
}
