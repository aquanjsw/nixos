{
  disabledModules = [
    "services/networking/xray.nix"
  ];

  imports = [
    ./xray.nix
  ];
}