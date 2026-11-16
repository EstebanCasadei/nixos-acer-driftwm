{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    driftwm.url = "github:malbiruk/driftwm";
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
