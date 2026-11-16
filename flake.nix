{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    driftwm.url = "github:malbiruk/driftwm";
    driftwm.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, driftwm, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      modules = [
        driftwm.nixosModules.default
        ./local/configuration.nix
        ./acer.nix
      ];
    };
  };
}
