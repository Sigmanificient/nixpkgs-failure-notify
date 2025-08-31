#! /usr/bin/env nix-shell
#! nix-shell -i bash -p curl gcc python3 jq

set -euo pipefail

curl -L \
   -A "nixpkgs-failure-notify (reach sigmanificient)" \
   -o result.html \
   https://hydra.nixos.org/jobset/nixpkgs/trunk/latest-eval?full=1

mkdir -p results
grep -Po "Evaluation (\d+) of jobset" result.html \
  | cut -f 2 -d ' ' \
  | head -n 1 >> results/job_id

TMP_DIR=$(mktemp -d)

gcc fast-hydra-parser.c -O2 -o "$TMP_DIR/fhp"
"$TMP_DIR/fhp" result.html | python post-cleanup.py

./filter-maintained-packages.nix > results/concerned-failures.json
