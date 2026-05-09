#! /usr/bin/env nix-shell
#! nix-shell -i bash -p curl gcc python3 jq

set -euo pipefail

export NIXPKGS_BRANCH="${NIXPKGS_BRANCH:-trunk}"

[[ ! -s result.html ]] &&
  curl -L \
   -A "nixpkgs-failure-notify (reach sigmanificient)" \
   -o result.html \
   "https://hydra.nixos.org/jobset/nixpkgs/${NIXPKGS_BRANCH}/latest-eval?full=1"

mkdir -p "results/${NIXPKGS_BRANCH}"
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

# --argstr doesn't work for some reason
nix eval --json --impure --expr "
  import ./filter-maintained-packages.nix {
    branch = \"${NIXPKGS_BRANCH}\";
  }" > "results/${NIXPKGS_BRANCH}/concerned-failures.json"
rm result.html
