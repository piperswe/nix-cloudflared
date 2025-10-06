{
  description = "A NixOS module for cloudflared";

  outputs =
    { self, nixpkgs }:
    rec {
      nixosModules.cloudflared = import ./module.nix;
      nixosModules.default = nixosModules.cloudflared;

      checks.x86_64-linux.cloudflared =
        let
          module =
            { modulesPath, ... }:
            {
              imports = [
                "${modulesPath}/installer/cd-dvd/iso-image.nix"
              ];
              services.cloudflared.enable = true;
              system.stateVersion = "22.05";
            };
          system = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              nixosModules.cloudflared
              module
            ];
          };
        in
        system.config.system.build.toplevel;
      checks.x86_64-linux.cloudflared-container =
        let
          module =
            { modulesPath, ... }:
            {
              imports = [
                "${modulesPath}/installer/cd-dvd/iso-image.nix"
              ];

              networking.nat = {
                enable = true;
                internalInterfaces = [ "ve-+" ];
                externalInterface = "enp8s0";
              };

              # Create a container for cloudflared
              containers.cloudflared = {
                privateNetwork = true;
                hostAddress = "192.168.100.2";
                localAddress = "192.168.100.12";
                ephemeral = true;
                autoStart = true;
                bindMounts = {
                  "/var/lib/cloudflared" = {
                    hostPath = "/var/lib/cloudflared";
                  };
                };
                config =
                  { config, pkgs, ... }:
                  {
                    imports = [ nixosModules.cloudflared ];
                    services.cloudflared.enable = true;
                    system.stateVersion = "22.05";
                  };
              };
              system.stateVersion = "22.05";
            };
          system = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ module ];
          };
        in
        system.config.system.build.toplevel;
    };
}
