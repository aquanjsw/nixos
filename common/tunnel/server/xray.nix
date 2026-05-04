{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: lib.mkIf config.tunnel.server.enable {

  services.xray.enable = true;
  services.xray.settings = let 
    secrets = config.age.secrets;
  in

  {
    log = {
      loglevel = "warning";
    };
    inbounds = [
      {
        port = 443;
        protocol = "vless";
        settings = {
          clients = [
            {
              id = { _secret = secrets.vless-uuid.path; };
              flow = "xtls-rprx-vision";
            }
          ];
          decryption = "none";
        };
        streamSettings = {
          network = "raw";
          security = "reality";
          realitySettings = {
            show = false;
            dest = 1443;
            serverNames = [
              config.domain
              "beszel.${config.domain}"
            ];
            privateKey = { _secret = secrets.reality-private-key.path; };
            shortIds = [ "" ];
          };
        };
      }
    ];
    outbounds = [
      {
        protocol = "freedom";
      }
    ];
  };

}
