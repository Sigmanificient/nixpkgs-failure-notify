#!/usr/bin/env -S nix eval --json -f
let
  nixpkgs = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/master.tar.gz";
  };

  pkgs = import nixpkgs { };

  failures-packed = pkgs.lib.pipe ./results/4-failures-packed.csv [
    builtins.readFile
    (pkgs.lib.strings.splitString "\n")
    builtins.tail
    (builtins.map (pkgs.lib.strings.splitString ","))
  ];

  gh = "Sigmanificient";
in let
  lookupAttrPath = pathStr:
    builtins.foldl'
    (acc: p:
      if acc == null then null
      else if builtins.hasAttr p acc then builtins.getAttr p acc
      else null)
    pkgs
    (pkgs.lib.strings.splitString "." pathStr);

  isPkgMaintainer = pkg: pkgs.lib.any (m: (m.github or "") == gh) pkg;

  getMaintainers = pkg: pkg.meta.maintainers or [];

  isMaintainer = pkg-build-fail: let
    evald = builtins.tryEval (
      pkgs.lib.pipe pkg-build-fail [
        builtins.head
        lookupAttrPath
        getMaintainers
        isPkgMaintainer
      ]
    );

    in evald.success && evald.value;

in builtins.filter isMaintainer failures-packed
