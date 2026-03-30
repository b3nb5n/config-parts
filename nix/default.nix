{
  flakeModules = {
    homeManager = import ./home-manager.nix;
    nixos = import ./nixos.nix;
  };
}
