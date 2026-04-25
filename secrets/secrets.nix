let
  minimal-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJcbO0qdMXLqVo1um8dsJ5AsNop6f82DuHVgHfhmpV1";
  bwh-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENvcZL6L6QpDotsU6xgClQ4f16NhUOoCIFr7lOXOLVk";

  minimal-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIW9TVyWzguSLNoL/PRKtYlCY0Weh1s5NZLPmSLikVHb";
  vultr-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII+XW58VGYhubgLiluoQIvN7gJoLlOxCMQmq6ff6Gk+U";
  bwh-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpzIcG2uFa8DIdHFgp9bHp9msFExzUYsilAmUnBTQuO";
in {
  "caddy-env.age".publicKeys = [ minimal-user vultr-host bwh-host bwh-user ];
  "vless-uuid.age".publicKeys = [ minimal-user minimal-host vultr-host bwh-host bwh-user ];
  "reality-public-key.age".publicKeys = [ minimal-user minimal-host vultr-host bwh-host bwh-user ];
  "reality-private-key.age".publicKeys = [ minimal-user minimal-host vultr-host bwh-host bwh-user ];
  "rootDomain.age".publicKeys = [ minimal-user minimal-host vultr-host bwh-host bwh-user ];
  "bwh-domain.age".publicKeys = [ minimal-user minimal-host vultr-host bwh-host bwh-user ];
  "vultr-domain.age".publicKeys = [ minimal-user minimal-host vultr-host bwh-host bwh-user ];
  "clash-api-secret.age".publicKeys = [ minimal-user minimal-host vultr-host bwh-host bwh-user ];
}

# vim: sts=2 sw=2 et ai
