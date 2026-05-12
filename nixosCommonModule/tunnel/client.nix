{
  lib,
  config,
  inputs,
  ...
}: {

  options.tunnel.client.config = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = let
      secrets = config.age.secrets;
    in

    {

      log = {
        disabled = false;
        level = "info";
        timestamp = true;
      };

      dns = {
        strategy = "ipv4_only";

        servers = [
          {
            type = "udp";
            tag = "remote";
            server = "1.1.1.1";
            detour = "proxy";
          }
          {
            type = "udp";
            tag = "local";
            server = "223.5.5.5";
          }
          {
            type = "local";
            tag = "lan";
          }
        ];

        rules = [
          {
            action = "route";
            rule_set = [
              "tailscale"
            ];
            server = "lan";
          }
          {
            action = "route";
            server = "lan";
            rule_set = [
              "geosite-lan"
            ];
          }
          {
            action = "route";
            server = "local";
            rule_set = [
              "geosite-cn"
              "mydomain"
              "geosite-ieee"
            ];
          }
        ];
      };

      route = {
        auto_detect_interface = true;
        rules = [
          {
            action = "sniff";
          }
          {
            protocol = "dns";
            action = "hijack-dns";
          }
          {
            action = "route";
            rule_set = [
              "tailscale"
            ];
            outbound = "direct";
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
              "mydomain"
              "geosite-cn"
              "geosite-ieee"
              "geosite-lan"
            ];
            domain_suffix = [
              ".cn"
            ];
            outbound = "direct";
          }
          {
            action = "route";
            ip_is_private = true;
            rule_set = [
              "geoip-cn"
            ];
            outbound = "direct";
          }
        ];
        rule_set = [
          {
            tag = "tailscale";
            type = "inline";
            rules = [
              {
                type = "logical";
                mode = "or";
                rules = [
                  {
                    process_name = [
                      "tailscale.exe"
                      "tailscaled.exe"
                      "tailscale-ipn.exe"
                    ];
                  }
                  {
                    domain_suffix = [
                      ".tail2fa86.ts.net"
                    ];
                  }
                ];
              }
            ];
          }
          {
            tag = "geosite-lan";
            type = "inline";
            rules = [
              {
                domain_suffix = [
                  ".lan"
                ];
              }
            ];
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
          {
            tag = "mydomain";
            type = "inline";
            rules = [
              {
                domain_suffix = [
                  config.domain
                ];
              }
            ];
          }
        ];
        final = "proxy";
        default_domain_resolver = "local";
      };
      experimental = {
        cache_file = {
          enabled = true;
          store_fakeip = true;
        };
        clash_api = {
          external_controller = ":9090";
          secret = { _secret = secrets.clash-api-secret.path; };
        };
      };
      inbounds = [
        {
          type = "mixed";
          listen = "::";
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
          route_exclude_address = [
            "100.64.0.0/10"
            "fd7a:115c:a1e0::/48"
          ];
        }
      ];
      outbounds = [
        {
          type = "direct";
          tag = "direct";
        }
        {
          type = "vless";
          tag = "main";
          server = config.domain;
          server_port = 443;
          uuid = { _secret = secrets.vless-uuid.path; };
          flow = "xtls-rprx-vision";
          tls = {
            enabled = true;
            server_name = config.domain;
            reality = {
              enabled = true;
              public_key = { _secret = secrets.reality-public-key.path; };
              short_id = "";
            };
            utls = {
              enabled = true;
            };
          };
        }
        {
          type = "selector";
          tag = "proxy";
          outbounds = [
            "main"
          ];
        }
      ];
    };

  };

  options.tunnel.client.enable = lib.mkEnableOption "tunnel client";

  config = lib.mkIf config.tunnel.client.enable {
    services.sing-box.enable = true;
    services.sing-box.settings = config.tunnel.client.config;
  };

}
