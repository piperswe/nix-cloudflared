{ config, pkgs, lib, ... }:
with lib;
{
  options.services.cloudflared = {
    enable = mkEnableOption "cloudflared";
    package = mkOption {
      type = types.package;
      default = pkgs.cloudflared;
      defaultText = literalExpression "pkgs.cloudflared";
      description = "The cloudflared package to use";
    };
    tokenFile = mkOption {
      type = types.path;
      default = "/var/lib/cloudflared/token";
      description = ''
        The path to a file containing the tunnel's token. This token can be
        obtained by creating a tunnel on the Cloudflare Zero Trust Dashboard
        (under Access -> Tunnels). The dashboard will give you connector
        commands that look something like
        `sudo cloudflared service install <long token>`. Save just the token to
        the file pointed to by this option.

        This is not a string option since this token is a secret and shouldn't
        be saved in the store. If someone gets their hands on this token, they
        can run a tunnel that impersonates your real tunnel!

        You may want to change ownership of this file to the cloudflared user
        and group and restrict its permissions to 400 to ensure it can only be
        read by cloudflared (and root) and can't be tampered with. You can do
        that with the following commands (as root, replacing the path with your
        own):

        chown cloudflared:cloudflared /var/lib/cloudflared/token
        chmod 400 /var/lib/cloudflared/token
      '';
    };
  };
  config = mkIf config.services.cloudflared.enable {
    users.users.cloudflared = {
      group = "cloudflared";
      isSystemUser = true;
    };
    users.groups.cloudflared = { };

    systemd.services.cloudflared = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ] ++ (optional config.services.resolved.enable "systemd-resolved.service");
      serviceConfig = {
        ExecStart = pkgs.writeShellScript "start-cloudflared" ''
          set -euxo pipefail
          # Ideally, cloudflared would read the token directly from the token
          # file. Sadly, it doesn't have that functionality and just spits the
          # token right into the command line (viewable through ps). I've filed
          # an internal bug for this, but until it gets fixed we can use this
          # wrapper script.
          token=\"$(cat ${config.services.cloudflared.tokenFile})\"
          exec ${config.services.cloudflared.package}/bin/cloudflared tunnel --no-autoupdate run --token=\"$token\"
        '';
        Restart = "always";
        User = "cloudflared";
        Group = "cloudflared";
      };
    };
  };
}
