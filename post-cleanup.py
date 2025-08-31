import sys

header = next(sys.stdin) # discard first line
sys.stdout.write("status,job,system,")

def remove_system_suffix(jobname: str) -> str:
    return min(
        (jobname.removesuffix(f".{arch}-{sys}")
          for arch in ("x86_64", "aarch64")
          for sys in ("darwin", "linux")
        ),
        key=len
    )


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
    if status[0] != 'F':
        continue

    parts = (id, remove_system_suffix(job), system)
    print(','.join(parts))
