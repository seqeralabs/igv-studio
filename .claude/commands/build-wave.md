# Build Studio with Wave

Build the IGV Studio Docker container using Seqera Wave cloud build service.

## Prerequisites

1. Get the Tower access token from 1Password:

```bash
export TOWER_ACCESS_TOKEN=$(op read "op://Employee/Seqera Platform Prod/password")
```

## Build with Wave

Build and push to a container registry using Wave:

```bash
wave -f Dockerfile \
  --context . \
  --build-repo cr.seqera.io/seqera-services/igv-studio \
  --platform linux/amd64 \
  --freeze \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

### Options Explained

| Option                   | Description                                        |
| ------------------------ | -------------------------------------------------- |
| `-f Dockerfile`          | Dockerfile to build                                |
| `--context .`            | Build context directory (current directory)        |
| `--build-repo`           | Registry where the built image will be stored      |
| `--platform linux/amd64` | Target platform (required for cloud compute)       |
| `--freeze`               | Get a persistent/immutable image name              |
| `--await`                | Wait for build to complete (default 15min timeout) |
| `--tower-token`          | Seqera Platform authentication token               |

### Custom Timeout

Override the default 15-minute await timeout:

```bash
wave -f Dockerfile --context . --build-repo cr.seqera.io/seqera-services/igv-studio \
  --platform linux/amd64 --freeze --await 30m --tower-token "$TOWER_ACCESS_TOKEN"
```

### Build with Cache Repository

Speed up rebuilds with a layer cache:

```bash
wave -f Dockerfile \
  --context . \
  --build-repo cr.seqera.io/seqera-services/igv-studio \
  --cache-repo cr.seqera.io/seqera-services/igv-studio-cache \
  --platform linux/amd64 \
  --freeze \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

## Output

Wave returns the built container image URI, e.g.:

```
wave.seqera.io/wt/abc123/cr.seqera.io/seqera-services/igv-studio:abc123def456
```

With `--freeze`, you get a persistent image in your build repo:

```
cr.seqera.io/seqera-services/igv-studio:abc123def456
```

## Troubleshooting

### Authentication Errors

Ensure `TOWER_ACCESS_TOKEN` is set and valid:

```bash
echo $TOWER_ACCESS_TOKEN | head -c 10
```

### Build Context Too Large

Wave uploads the build context. Ensure `.dockerignore` excludes unnecessary files:

```
.git
test-data
*.md
```

### Timeout Issues

Increase the await timeout for larger builds:

```bash
--await 30m
```

## Advantages over Local Docker Build

- **No local Docker daemon required** - builds in Seqera cloud
- **Native linux/amd64** - no emulation overhead on Apple Silicon
- **Consistent environment** - same build infra as Seqera Platform
- **Layer caching** - with `--cache-repo` for faster rebuilds
