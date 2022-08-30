{
  description = "A NixOS module for cloudflared";

  outputs = { self, nixpkgs }: rec {
    nixosModules.cloudflared = import ./module.nix;
    nixosModules.default = nixosModules.cloudflared;

    checks.x86_64-linux.cloudflared =
      let
        module = { modulesPath, ... }: {
          imports = [
            "${modulesPath}/installer/cd-dvd/iso-image.nix"
          ];
          services.cloudflared.enable = true;
          system.stateVersion = "22.05";
        };
        system = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ nixosModules.cloudflared module ];
        };
      in
      system.config.system.build.toplevel;
  };
}
