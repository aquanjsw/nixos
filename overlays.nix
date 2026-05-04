[
  (self: super: {
    ranger = super.ranger.overrideAttrs ( old: {
      src = super.fetchFromGitHub {
        owner = "ranger";
        repo = "ranger";
        rev = "a8858902ddc7e253e3287dc091775c028ac5665e";
        hash = "sha256-3b9xD8jDiaim0WxHALQpqC/xIa6Lewf30GlUoNsW2qs=";
      };
    });
  })
  (self: super: {
    xray = super.xray.overrideAttrs ( old: {
      version = "26.3.27";
      src = super.fetchFromGitHub {
        owner = "XTLS";
        repo = "Xray-core";
        rev = "v${old.version}";
        hash = "sha256-WTCehvvk/f2/IemzGDq3Y0dM/n0iKAH8CeVyoTimFqQ=";
      };
    });
  })
]