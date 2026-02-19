# Wave Build Troubleshooting

## Build Context Too Large

**Error**: `OutOfMemoryError: Array allocation too large`

**Fix**: Create minimal build directory or update `.dockerignore`:

```bash
# Option 1: Minimal directory
mkdir -p /tmp/igv-build
cp Dockerfile *.sh *.conf *.js *.json /tmp/igv-build/
wave -f /tmp/igv-build/Dockerfile --context /tmp/igv-build ...
```

```
# Option 2: .dockerignore
.git
test-data
*.md
node_modules
```

## Timeout Issues

Increase timeout for large builds:

```bash
--await 30m
```

## Authentication Errors

### 401 Unauthorized on Push

The `--freeze` option requires push permissions to `--build-repo`. Use temporary URL instead:

```bash
wave -f Dockerfile --context . --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

### Token Invalid

Verify token is set:

```bash
echo $TOWER_ACCESS_TOKEN | head -c 10
```

## npm Errors (git not found)

**Error**: `npm error enoent git`

**Fix**: Add git to Dockerfile builder stage:

```dockerfile
RUN apt-get update && apt-get install -y curl unzip git
```

## Architecture Mismatch

**Error**: `CannotPullContainerError: no matching manifest for linux/amd64`

**Fix**: Always use `--platform linux/amd64`:

```bash
wave -f Dockerfile --context . --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## GitHub Registry Permission Denied

**Error**: `permission_denied` when pushing to ghcr.io

**Fix**: Refresh GitHub token with packages scope:

```bash
gh auth refresh -h github.com -s write:packages
```
