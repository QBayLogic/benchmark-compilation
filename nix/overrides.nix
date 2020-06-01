pkgs: new: old:
with new; with pkgs.haskell.lib;
let
  l = repo: path: cabalExtras:
      doJailbreak
      (old.callCabal2nixWithOptions repo path cabalExtras {});
  c = owner: repo: rev: sha256: cabalExtras:
        dontCheck
          (doJailbreak (old.callCabal2nixWithOptions repo (pkgs.fetchFromGitHub {
            inherit owner repo rev sha256;
           }) cabalExtras {}));
  # overcabal = pkgs.haskell.lib.overrideCabal;
  # hubsrc    =      repo: rev: sha256:       pkgs.fetchgit { url = "https://github.com/" + repo; rev = rev; sha256 = sha256; };
  # overc     = old:                    args: overcabal old (oldAttrs: (oldAttrs // args));
  # overhub   = old: repo: rev: sha256: args: overc old ({ src = hubsrc repo rev sha256; }       // args);
  # overhage  = old: version:   sha256: args: overc old ({ version = version; sha256 = sha256; } // args);
in {
  # async-timer           = dontCheck (overrideCabal old.async-timer  (old: { broken = false; }));
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
  # lens                  = dontCheck (doJailbreak (overrideCabal old.lens_4_19_2 (old: {})));
  # md5                   = dontCheck (overrideCabal old.md5          (old: {}));
  # newtype               = dontCheck (doJailbreak   old.newtype);

  # common          = new.callCabal2nix "common" ../common {};
}
