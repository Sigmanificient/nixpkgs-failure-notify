import json
import subprocess
import os

with open("results/concerned-failures.json") as f:
    rows = json.load(f)

with open("previous.json") as f:
    known_fails = [r[0] for r in json.load(f)]


SUPPORTED_SYSTEMS = tuple(
    f"{arch}-{sys}"
    for sys in ("linux", "darwin")
    for arch in ("x86_64", "aarch64")
)

repo = os.getenv("GH_REPOSITORY")
assert repo is not None

gh_token = os.getenv("GH_TOKEN")
assert gh_token is not None


for row in rows:
    pkg = row[0]
    if pkg in known_fails:
        continue

    failures = [
        f"- [ ] `{plat}`: [log](https://hydra.nixos.org/build/{build_id}/log)"
        for plat, build_id in zip(SUPPORTED_SYSTEMS, row[1:])
        if build_id
    ]

    if not failures:
        continue

    body = (
        "@Sigmanificient\n\n"
        + f"Build failures for `{pkg}`:\n\n"
        + "\n".join(failures)
    )

    title = f"{pkg} build failures"

    print(f"Creating issue: {title}")
    subprocess.run([
        "gh", "issue", "create",
        "--repo", repo,
        "--title", title,
        "--body", body
        ], check=True, env={"GITHUB_TOKEN": gh_token}
    )
