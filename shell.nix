# This nix-shell script can be used to get a complete development environment
# for the Crystal compiler.
#
# You can choose which llvm version use and, on Linux, choose to use musl.
#
# $ nix-shell --pure
# $ nix-shell --pure --arg llvm 10
# $ nix-shell --pure --arg llvm 10 --arg musl true
# $ nix-shell --pure --arg llvm 9
# $ nix-shell --pure --arg llvm 9 --argstr system i686-linux
# ...
# $ nix-shell --pure --arg llvm 6
#
# If needed, you can use https://app.cachix.org/cache/crystal-ci to avoid building
# packages that are not available in Nix directly. This is mostly useful for musl.
#
# $ nix-env -iA cachix -f https://cachix.org/api/v1/install
# $ cachix use crystal-ci
# $ nix-shell --pure --arg musl true
#

{llvm ? 18, musl ? false, system ? builtins.currentSystem}:

let
  nixpkgs = import (builtins.fetchTarball {
    name = "nixpkgs-24.05";
    url = "https://github.com/NixOS/nixpkgs/archive/24.05.tar.gz";
    sha256 = "1lr1h35prqkd1mkmzriwlpvxcb34kmhc9dnr48gkm8hh089hifmx";
  }) {
    inherit system;
  };

  pkgs = if musl then nixpkgs.pkgsMusl else nixpkgs;
  llvmPackages = pkgs."llvmPackages_${toString llvm}";

  genericBinary = { url, sha256 }:
    pkgs.stdenv.mkDerivation rec {
      name = "crystal-binary";
      src = builtins.fetchTarball { inherit url sha256; };

      # Extract only the compiler binary
      buildCommand = ''
        mkdir -p $out/bin

        # Darwin packages use embedded/bin/crystal
        [ ! -f "${src}/embedded/bin/crystal" ] || cp ${src}/embedded/bin/crystal $out/bin/

        # Linux packages use lib/crystal/bin/crystal
        [ ! -f "${src}/lib/crystal/bin/crystal" ] || cp ${src}/lib/crystal/bin/crystal $out/bin/
      '';
    };

  # Hashes obtained using `nix-prefetch-url --unpack <url>`
  latestCrystalBinary = genericBinary ({
    x86_64-darwin = {
      url = "https://github.com/crystal-lang/crystal/releases/download/1.14.0/crystal-1.14.0-1-darwin-universal.tar.gz";
      sha256 = "sha256:09mp3mngj4wik4v2bffpms3x8dksmrcy0a7hs4cg8b13hrfdrgww";
    };

    aarch64-darwin = {
      url = "https://github.com/crystal-lang/crystal/releases/download/1.14.0/crystal-1.14.0-1-darwin-universal.tar.gz";
      sha256 = "sha256:09mp3mngj4wik4v2bffpms3x8dksmrcy0a7hs4cg8b13hrfdrgww";
    };

    x86_64-linux = {
      url = "https://github.com/crystal-lang/crystal/releases/download/1.14.0/crystal-1.14.0-1-linux-x86_64.tar.gz";
      sha256 = "sha256:0p5b22ivggf9xlw91cbhib7n4lzd8is1shd3480jjp14rn1kiy5z";
    };
  }.${pkgs.stdenv.system});

  boehmgc = pkgs.boehmgc.override {
    enableLargeConfig = true;
  };

  stdLibDeps = with pkgs; [
      boehmgc gmp libevent libiconv libxml2 libyaml openssl pcre2 zlib
    ] ++ lib.optionals stdenv.isDarwin [ libiconv ];

  tools = [ pkgs.hostname pkgs.git llvmPackages.bintools ] ++ pkgs.lib.optional (!llvmPackages.lldb.meta.broken) llvmPackages.lldb;
in

pkgs.stdenv.mkDerivation rec {
  name = "crystal-dev";

  buildInputs = tools ++ stdLibDeps ++ [
    latestCrystalBinary
    pkgs.pkg-config
    llvmPackages.libllvm
    pkgs.libffi
  ];

  LLVM_CONFIG = "${llvmPackages.libllvm.dev}/bin/llvm-config";

  MACOSX_DEPLOYMENT_TARGET = "10.11";
}
