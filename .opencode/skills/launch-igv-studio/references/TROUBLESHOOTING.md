# Launch IGV Studio Troubleshooting

## Wave Build Errors

### OutOfMemoryError: Array allocation too large

Build context too large. Create minimal build directory:

```bash
mkdir -p /tmp/igv-build
cp Dockerfile *.sh *.conf *.js *.json /tmp/igv-build/
wave -f /tmp/igv-build/Dockerfile --context /tmp/igv-build --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

Or ensure `.dockerignore` excludes large directories: `test-data/`, `.git/`.

### 401 Unauthorized on Push

The `--freeze` option requires push permissions. Use temporary URL instead:

```bash
wave -f Dockerfile --context . --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Container Errors

### CannotPullContainerError: no matching manifest for linux/amd64

Image built for wrong architecture. Always use `--platform linux/amd64`:

```bash
wave -f Dockerfile --context . --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

### could not open loop device: permission denied

Connect-client needs root privileges for Fusion loop devices. Ensure Dockerfile does NOT have a `USER` directive - container must run as root.

## GitHub Registry

### permission_denied when pushing to ghcr.io

GitHub token needs `write:packages` scope:

```bash
gh auth refresh -h github.com -s write:packages
```
