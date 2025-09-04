#! /usr/bin/env nix-shell
#! nix-shell -i bash -p curl gcc python3 jq

set -euo pipefail

[[ ! -s result.html ]] && \
  curl -L \
   -A "nixpkgs-failure-notify (reach sigmanificient)" \
   -o result.html \
   https://hydra.nixos.org/jobset/nixpkgs/trunk/latest-eval?full=1

mkdir -p results
grep -Po "Evaluation (\d+) of jobset" result.html \
  | cut -f 2 -d ' ' \
  | head -n 1 >> results/job_id

TMP_DIR=$(mktemp -d)

if ! command -v fhp >/dev/null 2>&1; then
  gcc fast-hydra-parser.c -O2 -o "$TMP_DIR/fhp"

  fhp_cmd="$TMP_DIR/fhp"
else
  fhp_cmd=fhp
fi

if ! command -v hydra-to-csv 2>&1; then
  hydra_to_cvs_cmd="python python_hydra_parser/src/hydra_parser/__init__.py"
else
  hydra_to_cvs_cmd="hydra-to-csv"
fi

$fhp_cmd result.html | $hydra_to_cvs_cmd
./filter-maintained-packages.nix > results/concerned-failures.json
