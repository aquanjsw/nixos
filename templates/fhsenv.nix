{
  pkgs ? import <nixpkgs> {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
  },
}: ( pkgs.buildFHSEnv {
  name = "simple-fhsenv";
  targetPkgs = pkgs: (with pkgs; [
    cudatoolkit
    uv
    stdenv.cc
    libxcb
    libGL
    glib
  ]);
  runScript = "fish";
}).env