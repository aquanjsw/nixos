{
  lib,
  config,
  ...
}:
{

  options.tunnel.client.sing-box.settings = lib.mkOption {
    readOnly = true;
    default =
      let
        secrets = config.age.secrets;
      in
      {

        log = {
          disabled = false;
          level = "info";
          timestamp = true;
        };

        dns = {
          strategy = "ipv4_only"; # CERNET's IPv6 connectivity is terrible

          servers = [
            {
              type = "udp";
              tag = "remote";
              server = "1.1.1.1";
              detour = "proxy";
            }
            {
              type = "local";
              tag = "local";
            }
            {
              type = "tailscale";
              tag = "ts-dns";
              endpoint = "ts-ep";
            }
          ];

          rules = [
            {
              action = "predefined";
              rcode = "NOERROR"; # SUCCESS
              rule_set = [
                "geosite-category-ads-all"
              ];
            }
            {
              action = "route";
              server = "local";
              rule_set = [
                "geosite-cn"
                "geosite-ieee"
              ];
              domain_suffix = [
                ".lan"
              ];
            }

            {
              ip_accept_any = true;
              server = "ts-dns";
            }
            # Use this in v1.14.0+
            # {
            #   server = "ts-dns";
            #   preferred_by = "ts-dns";
            #   action = "route";
            # }

          ];
        };

        route = {
          final = "proxy";
          default_domain_resolver = "local";
          auto_detect_interface = true;

          rule_set = [
            {
              tag = "geosite-private";
              type = "remote";
              format = "binary";
              url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-private.srs";
              download_detour = "proxy";
            }
            {
              tag = "geosite-category-ads-all";
              type = "remote";
              format = "binary";
              url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs";
              download_detour = "proxy";
            }
            {
              tag = "geosite-cn";
              type = "remote";
              format = "binary";
              url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs";
              download_detour = "proxy";
            }
            {
              tag = "geosite-ieee";
              type = "remote";
              format = "binary";
              url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-ieee.srs";
              download_detour = "proxy";
            }
            {
              tag = "geoip-cn";
              type = "remote";
              format = "binary";
              url = "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs";
              download_detour = "proxy";
            }
          ];

          rules = [
            {
              action = "sniff";
            }
            {
              protocol = "dns";
              action = "hijack-dns";
            }
            {
              action = "reject";
              rule_set = [
                "geosite-category-ads-all"
              ];
            }
            {
              action = "route";
              process_name = [
                "leigod.exe"
                "leishenSdk.exe"
              ];
              outbound = "direct";
            }
            {
              action = "route";
              process_name = [
                "frpc"
                "frpc.exe"
              ];
              outbound = "proxy";
            }
            {
              action = "route";
              domain_suffix = [
                "zi0.cc"
                "googleapis.com"
                "googleapis.cn"
                "google.cn"
                "gvt2.com"
                "gstatic.com"
              ];
              outbound = "proxy";
            }
            {
              action = "route";
              rule_set = [
                "geosite-private"
                "geosite-cn"
                "geosite-ieee"
                "geoip-cn"
              ];
              domain_suffix = [
                "hf-mirror.com"
                config.domain
              ];
              ip_is_private = true;
              outbound = "direct";
            }
            {
              action = "route";
              preferred_by = [ "ts-ep" ];
              outbound = "ts-ep";
            }
          ];

        };

        experimental = {
          cache_file = {
            enabled = true;
          };
          clash_api = {
            external_controller = ":9090";
            secret = {
              _secret = secrets.clash-api-secret.path;
            };
          };
        };

        inbounds = [
          {
            type = "mixed";
            listen = "::0";
            listen_port = 7890;
          }
          {
            type = "tun";
            address = [
              "172.19.0.1/30"
              "fdfe:dcba:9876::1/126"
            ];
            auto_route = true;
            auto_redirect = true;
            strict_route = true;
            mtu = 1380; # Seems more stable than default 9000 in CERNET...?
          }
        ];

        outbounds = [
          {
            type = "direct";
            tag = "direct";
          }
          {
            type = "vless";
            tag = "proxy";
            server = config.domain;
            server_port = 443;
            uuid = {
              _secret = secrets.vless-uuid.path;
            };
            flow = "xtls-rprx-vision";
            tls = {
              enabled = true;
              server_name = config.domain;
              reality = {
                enabled = true;
                public_key = {
                  _secret = secrets.reality-public-key.path;
                };
                short_id = "";
              };
              utls = {
                enabled = true;
              };
            };
          }
        ];

        endpoints = [
          {
            type = "tailscale";
            tag = "ts-ep";
            auth_key = {
              _secret = secrets.tailscale-auth-key.path;
            };
          }
        ];
      };
  };

  options.tunnel.client.sing-box.enable = lib.mkEnableOption "sing-box client";

  config = {

    age.secrets =
      let
        path = config.paths.secrets;
      in
      {
        clash-api-secret.file = path + "/clash-api-secret.age";
        tailscale-auth-key.file = path + "/tailscale-auth-key.age";
      };

    services.sing-box = lib.mkIf config.tunnel.client.sing-box.enable {
      enable = true;
      settings = config.tunnel.client.sing-box.settings;
    };

    tunnel.subscription.sing-box.settings = config.tunnel.client.sing-box.settings;

    web-app.subscription.sing-box = lib.mkIf config.web-app.enable {
      configPath = config.tunnel.subscription.sing-box.path;
      urlPath = "sing-box.json";
    };
  };
}
