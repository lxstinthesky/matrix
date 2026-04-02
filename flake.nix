{
  description = "Flake to setup server using matrix communication protocol";

  inputs = {

    # stable and unstable nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11"; 
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # partitioning and disk management
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # secret management
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, disko, sops, ... }@inputs: {
    nixosConfigurations = {
      # TODO replace hostname
      matrix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops.nixosModules.sops
          ./nix/configuration.nix
          ./nix/disko.nix
        ];
        specialArgs = { inherit inputs; };
      };
    };

    # Development shell for working with the configuration
    # execute: nix develop or use direnv
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
        git
        dig
        traceroute
        matrix-synapse
        livekit # to generate keys
      ];
    };
    devShells.aarch64-linux.default = nixpkgs.legacyPackages.aarch64-linux.mkShell {
      buildInputs = with nixpkgs.legacyPackages.aarch64-linux; [
        git
        dig
        traceroute
        matrix-synapse
        livekit # to generate keys
      ];
    };
  };
}