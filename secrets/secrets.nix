let
  minimal-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJcbO0qdMXLqVo1um8dsJ5AsNop6f82DuHVgHfhmpV1";
  minimal-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIW9TVyWzguSLNoL/PRKtYlCY0Weh1s5NZLPmSLikVHb";

  bwh-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENvcZL6L6QpDotsU6xgClQ4f16NhUOoCIFr7lOXOLVk";
  bwh-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpzIcG2uFa8DIdHFgp9bHp9msFExzUYsilAmUnBTQuO";

  users = [ minimal-user bwh-user ];
in {
  "caddy-env.age".publicKeys = users ++ [ bwh-host ];
  "vless-uuid.age".publicKeys = users ++ [ minimal-host bwh-host ];
  "reality-public-key.age".publicKeys = users ++ [ minimal-host bwh-host ];
  "reality-private-key.age".publicKeys = users ++ [ minimal-host bwh-host ];
  "clash-api-secret.age".publicKeys = users ++ [ minimal-host bwh-host ];
  "domain.age".publicKeys = users ++ [ minimal-host bwh-host ];
  "inbound-password.age".publicKeys = users ++ [ minimal-host bwh-host ];
}

# vim: sts=2 sw=2 et ai
