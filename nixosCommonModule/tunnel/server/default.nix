{
  lib,
  ...
}: {

  imports = [
    ./caddy.nix
    ./xray.nix
  ];

  options.tunnel.server.enable = lib.mkEnableOption "tunnel server";

}