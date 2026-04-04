{
  inputs = {
    nixpkgs.url = "nixpkgs/release-25.11";

    flake-parts.url = "github:hercules-ci/flake-parts";
    config-parts.url = "path:/home/ben/Desktop/config-parts";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.config-parts.flakeModules.nixos
        inputs.config-parts.flakeModules.home-manager

        ./host.nix
        ./user.nix
      ];
    };
}
