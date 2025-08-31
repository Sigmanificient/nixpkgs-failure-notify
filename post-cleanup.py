from collections import defaultdict
import sys

SUPPORTED_SYSTEMS = tuple(
    f"{arch}-{sys}"
    for sys in ("linux", "darwin")
    for arch in ("x86_64", "aarch64")
)


header = next(sys.stdin) # discard first line
sys.stdout.write("job," + ",".join(SUPPORTED_SYSTEMS) + "\n")


def remove_system_suffix(jobname: str) -> str:
    jobname = jobname.replace("&quot;", "")
    return min(
        (jobname.removesuffix(f".{sys}") for sys in SUPPORTED_SYSTEMS),
        key=len
    )


packages = defaultdict(lambda: { k: '' for k in SUPPORTED_SYSTEMS })

for line in sys.stdin:
    (
        status,
        id,
        job,
        finished_at,
        pkg_name,
        system
    ) = line.rstrip("\n").split(',')

# status:
# D -> Dependency fail
# F -> Failure
# S -> Succeeded
# O -> Output size limit exceeded
    if status[0] != 'F' or system not in SUPPORTED_SYSTEMS:
        continue

    name = remove_system_suffix(job)

    packages[name][system] = id


for pkg, failures in packages.items():
    print(','.join((pkg, *failures.values())))
