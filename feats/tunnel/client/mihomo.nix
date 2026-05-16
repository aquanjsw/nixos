{
  lib,
  config,
  inputs,
  ...
}: {

  options.tunnel.client.mihomo.settings = lib.mkOption {
    readOnly = true;
    default = let
      secrets = config.age.secrets;
    in {
      mixed-port = 7890;
      allow-lan = true;
      bind-address = "*";
      authentication = [
        { _secret = secrets.lan-auth.path; }
      ];
      skip-auth-prefixes = [
        "127.0.0.1/8"
        "::1/128"
        "192.168.0.0/16"
        "100.64.0.0/10"
      ];
      mode = "rule";
      geox-url = {
        geoip = "https://${config.domain}/geoip.dat";
        geosite = "https://${config.domain}/geosite.dat";
        mmdb = "https://${config.domain}/geoip.metadb";
      };
      geo-auto-update = true;
      log-level = "debug";
      ipv6 = false;
      external-controller = ":9090";
      secret = { _secret = secrets.controller-secret.path; };
      external-controller-cors = {
        allow-origin = [ "*" ];
        allow-private-network = true;
      };
      external-ui = "ui";
      external-ui-url = "https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip";
      tcp-concurrent = true;
      profile = {
        store-selected = true;
      };
      tun = {
        enable = true;
        dns-hijack = [ "0.0.0.0:53" ];
        auto-detect-interface = true;
        auto-route = true;
        auto-redirect = true;
        strict-route = true;
        exclude-interface = [
          "tailscale0"
        ];
      };
      sniffer = {
        enable = true;
        force-dns-mapping = true;
      };
      dns = {
        enable = true;
        listen = ":53";
        default-nameserver = [ "114.114.114.114" ];
        enhanced-mode = "redir-host";
        respect-rules = true;
        nameserver = [ "1.1.1.1" ];
        proxy-server-nameserver = [ "system" ];
        nameserver-policy = {
          "geosite:category-ads-all" = "rcode://success";
          "+.ts.net,+.lan,geosite:cn" = "system";
        };
      };
      proxies = [
        {
          name = "proxy";
          type = "vless";
          server = config.domain;
          port = 443;
          uuid = { _secret = secrets.vless-uuid.path; };
          flow = "xtls-rprx-vision";
          tls = true;
          udp = true;
          client-fingerprint = "chrome";
          servername = config.domain;
          reality-opts = {
            public-key = { _secret = secrets.reality-public-key.path; };
          };
        }
      ];
      rule-providers = {
        tailscale = {
          type = "inline";
          behavior = "classical";
          payload = [
            "PROCESS-NAME,tailscale.exe"
            "PROCESS-NAME,tailscaled.exe"
            "PROCESS-NAME,tailscale-ipn.exe"
            "DOMAIN-SUFFIX,ts.net"
          ];
        };
        google = {
          type = "inline";
          behavior = "classical";
          payload = [
            "DOMAIN-SUFFIX,googleapis.com"
            "DOMAIN-SUFFIX,googleapis.cn"
            "DOMAIN-SUFFIX,google.cn"
            "DOMAIN-SUFFIX,gvt2.com"
            "DOMAIN-SUFFIX,gstatic.com"
          ];
        };
        leigod = {
          type = "http";
          behavior = "classical";
          payload = [
            "PROCESS-NAME,leigod.exe"
            "PROCESS-NAME,leishenSdk.exe"
          ];
        };
        frpc = {
          type = "http";
          behavior = "classical";
          payload = [
            "PROCESS-NAME,frpc"
            "PROCESS-NAME,frpc.exe"
          ];
        };
      };
      rules = [
        "IP-CIDR,1.1.1.1/32,proxy,no-resolve"
        "DOMAIN-SUFFIX,lan,DIRECT"
        "RULE-SET,frpc,proxy"
        "GEOSITE,category-ads-all,REJECT"
        "RULE-SET,leigod,DIRECT"
        "RULE-SET,tailscale,DIRECT"
        "RULE-SET,google,proxy"
        "DOMAIN-SUFFIX,cn,DIRECT"
        "DOMAIN-SUFFIX,zi0.cc,proxy"
        "GEOSITE,cn,DIRECT"
        "GEOSITE,ieee,DIRECT"
        "DOMAIN-SUFFIX,hf-mirror.com,DIRECT"
        "GEOIP,LAN,DIRECT"
        "GEOIP,CN,DIRECT"
        "MATCH,proxy"
      ];
    };
  };

  options.tunnel.client.mihomo.enable = lib.mkEnableOption "mihomo client";

  config = {

    age.secrets = let
      path = config.paths.secrets;
    in {
      lan-auth.file = path + "/lan-auth.age";
      controller-secret.file = path + "/controller-secret.age";
    };

    services.mihomo = lib.mkIf config.tunnel.client.mihomo.enable {
      enable = true;
      settings = config.tunnel.client.mihomo.settings;
      tunMode = true;
      processesInfo = true;
    };

    tunnel.subscription.mihomo.settings = config.tunnel.client.mihomo.settings;

    web-app.subscription.mihomo = lib.mkIf config.web-app.enable {
      configPath = config.tunnel.subscription.mihomo.path;
      urlPath = "mihomo.json";
    };
  };
}
