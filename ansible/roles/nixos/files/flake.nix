{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { 
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.authelia = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./configuration.nix
        ];
      };
  };
}
