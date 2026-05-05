{
  lib,
  pkgs,
  utils,
  config,
  ...
}: let
  subscriptionDirname = "subscription";
in {

  imports = [
    ./server
    ./client.nix
  ];

  options.tunnel.subscription = {

    name = lib.mkOption {
      default = "config.json";
      readOnly = true;
    };

    path = lib.mkOption {
      default = "/run/${subscriptionDirname}/${config.tunnel.subscription.name}";
      readOnly = true;
    };

  };

  config.systemd.services.subscriptionDeployer = lib.mkIf config.tunnel.server.enable {
    description = "Generate Tunnel Client Subscription";
    after = [ "caddy.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RuntimeDirectory = subscriptionDirname;
      RuntimeDirectoryPreserve = "yes";
      ExecStart = let
        script = pkgs.writeShellScript "gen-tunnel-client-config" ''
          ${utils.genJqSecretsReplacementSnippet
            config.tunnel.client.config
            config.tunnel.subscription.path}
        '';
      in "+${script}";
    };
  };
}