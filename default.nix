let
  fetchFromGitHub  =
    if (builtins ? "fetchTarball")
    then
      { owner, repo, rev, sha256 }: builtins.fetchTarball {
        inherit sha256;
        url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
      }
    else
      (import <nixpkgs> {}).fetchFromGitHub;
  srcFromGithubPin = name: fetchFromGitHub (builtins.fromJSON (builtins.readFile (./nix/pins + "/${name}.json")));
in
let
  default-compiler = import ./nix/default-compiler.nix;
in
let
  nixpkgsSrc       = srcFromGithubPin "nixpkgs";
  clashSrc         = srcFromGithubPin "clash";
  hintSrc          = srcFromGithubPin "hint";
in
let
  pkgs             = (import nixpkgsSrc {}).pkgs;
in
{ compiler         ? default-compiler
, buildFlags       ? []
}:
with pkgs.lib;
let
  ghcOrig          = pkgs.haskell.packages."${compiler}";   # :: nixpkgs/pkgs/development/haskell-modules/make-package-set.nix
in
let
  ghcOverrides =
    ghcVer: new: old:
      with pkgs.haskell.lib;
      ({
        ghc8101 =
          { hint = new.callCabal2nix "hint" hintSrc {};
            lens = old.lens_4_19_2;
            singletons = old.singletons_2_7;
            cabal-install = overrideCabal old.cabal-install (drv: {
              postUnpack = "sourceRoot+=/cabal-install; echo source root reset to $sourceRoot";
              version = "3.2.0.0-git";
              editedCabalFile = null;
              src = pkgs.fetchgit {
                url = "git://github.com/haskell/cabal.git";
                rev = "9bd4cc0591616aeae78e17167338371a2542a475";
                sha256 = "005q1shh7vqgykkp72hhmswmrfpz761x0q0jqfnl3wqim4xd9dg0";
              };
            });
          }
            //
          (flip genAttrs (x: doJailbreak old.${x})
            [ "ed25519"
              "first-class-families"
              "system-fileio"
            ]);
      }).${ghcVer};

  clashPkgs =
    let
      clashPkg =
        with pkgs.haskell.lib;
        pkgSet: name:
        overrideCabal (pkgSet.callCabal2nix name (clashSrc + "/${name}") {})
          (drv: {
            doCheck   = false;
            doHaddock = false;
            jailbreak = true;
          } // optionalAttrs (buildFlags != []) {
            inherit buildFlags;
          });
    in
    pkgSet:
      flip genAttrs (clashPkg pkgSet)
        [ "clash-ghc"
          "clash-lib"
          "clash-prelude"
        ];
in
let
  ghc =
    ghcOrig.override {
      overrides =
        new: old:
        ghcOverrides compiler new old
        // clashPkgs new;
    };

### Attributes available for direct building:
##
##  nix-build -A foo
##
in {
  inherit srcFromGithubPin;
  inherit (ghc) clash-ghc clash-lib clash-prelude;

  "${compiler}" = pkgs.haskell.compiler.${compiler};
  ghc           = pkgs.haskell.compiler.${compiler};

  shell = ghc.shellFor {
    packages    = p: [p.clash-ghc];
    withHoogle  = true;

    ## Extra packages to provide.
    buildInputs =
      with ghc;
      [ cabal-install
        pkgs.jq
      ];
  };
}
