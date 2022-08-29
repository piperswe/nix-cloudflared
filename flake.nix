{
  description = "A NixOS module for cloudflared";

  outputs = { self }: rec {
    nixosModules.cloudflared = import ./module.nix;
    nixosModules.default = nixosModules.cloudflared;
  };
}
