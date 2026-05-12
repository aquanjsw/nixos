let
  minimal-system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIW9TVyWzguSLNoL/PRKtYlCY0Weh1s5NZLPmSLikVHb";
  minimal-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJcbO0qdMXLqVo1um8dsJ5AsNop6f82DuHVgHfhmpV1";

  bwh-system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpzIcG2uFa8DIdHFgp9bHp9msFExzUYsilAmUnBTQuO";
  bwh-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENvcZL6L6QpDotsU6xgClQ4f16NhUOoCIFr7lOXOLVk";

  lib5-system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC08h/FP6qqvdfr9tdue9SRjB/auHP0c/15+3cp4xmiZ";
  lib5-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF/Nwn3AJ+MltE7EbwkqqhaQRqrhFB7nnwvsPP/TaF+U";

  users = [ minimal-user bwh-user lib5-user ];
  systems = [ minimal-system bwh-system lib5-system ];
in {
  "caddy-env.age".publicKeys = users ++ [ bwh-system ];
  "django-env.age".publicKeys = users ++ [ bwh-system ];

  "vless-uuid.age".publicKeys = users ++ systems;
  "reality-public-key.age".publicKeys = users ++ systems;
  "reality-private-key.age".publicKeys = users ++ systems;
  "clash-api-secret.age".publicKeys = users ++ systems;
  "beszel-agent-env.age".publicKeys = users ++ systems;
}

# vim: sts=2 sw=2 et ai
