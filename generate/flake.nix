{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-generators, ... }@inputs: {
    packages.x86_64-linux = {
      authelia = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
        format = "proxmox-lxc";
      };
    };
  };
}
