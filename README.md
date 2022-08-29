# NixOS module for cloudflared

DISCLAIMER: I am a Cloudflare employee, but this was made on my spare
time and is not official Cloudflare software.

## Usage example

In a flake:

```nix
{
  inputs.cloudflared.url = github:piperswe/nix-cloudflared;

  outputs = { self, nixpkgs, cloudflared }: {
    nixosConfigurations.my-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        cloudflared.nixosModules.cloudflared
        ({ ... }: {
          services.cloudflared.enable = true;

          # Insert other NixOS configuration here
        })
      ];
    };
  };
}
```

To run in a container with isolated network and filesystem (configure the
"public hostnames" on the Zero Trust Dashboard to point to `192.168.100.2`
instead of `localhost`):

```nix
{
  inputs.cloudflared.url = github:piperswe/nix-cloudflared;

  outputs = { self, nixpkgs, cloudflared }: {
    nixosConfigurations.my-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        cloudflared.nixosModules.cloudflared
        ({ ... }: {
          # Enable NAT for containers
          networking.nat = {
            enable = true;
            internalInterfaces = [ "ve-+" ];
            # Replace with your real external network interface name
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
            config = { config, pkgs, ... }: {
              imports = [ cloudflared.nixosModules.cloudflared ];
              services.cloudflared.enable = true;
              services.rsyslogd = rsyslogdConfig;
              system.stateVersion = "22.05";
            };
          };

          # Insert other NixOS configuration here
        })
      ];
    };
  };
}
```
