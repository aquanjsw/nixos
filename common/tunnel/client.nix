{
  lib, 
  config, 
  inputs, 
  ... 
}: {

  imports = [ 
    inputs.agenix.nixosModules.default
  ];

  options.tunnel.client.config = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = let 

      secrets = config.age.secrets;
    in
    
    {
      log = {
        disabled = false;
        level = "error";
        timestamp = true;
      };
      dns = {
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
          {
            type = "fakeip";
            tag = "fakeip";
            inet4_range = "198.18.0.0/15";
            inet6_range = "fc00::/18";
          }
        ];
        rules = [
          {
            action = "route";
            server = "lan";
            rule_set = [
              "geosite-lan"
            ];
          }
          {
            query_type = [
              "A"
              "AAAA"
            ];
            action = "route";
            server = "fakeip";
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
                  "zaelggk.com"
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
          users = [
            {
              username = "rag";
              password = { _secret = secrets.inbound-password.path; };
            }
          ];
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
          server = "zaelggk.com";
          server_port = 443;
          uuid = { _secret = secrets.vless-uuid.path; };
          flow = "xtls-rprx-vision";
          tls = {
            enabled = true;
            server_name = "zaelggk.com";
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
          type = "urltest";
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
