---
name: wave-build
description: Build Docker/OCI containers using Seqera Wave cloud build service. Use when building containers, Docker images, or when user mentions Wave, cloud builds, or needs to build without local Docker.
compatibility: Requires wave CLI, TOWER_ACCESS_TOKEN, and optionally 1Password CLI (op) for token retrieval.
metadata:
  author: Seqera/edmundmiller
  version: "1.0"
---

# Build Containers with Wave CLI

Build Docker/OCI containers using Seqera Wave cloud build service - no local Docker required.

## Prerequisites

```bash
export TOWER_ACCESS_TOKEN=$(op read "op://Employee/Seqera Platform Prod/password")
```

## Quick Start

### Basic Build (Temporary URL ~24h)

```bash
wave -f Dockerfile --context . --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

### Persistent Image (Recommended for Production)

```bash
wave -f Dockerfile \
  --context . \
  --build-repo cr.seqera.io/seqera-services/igv-studio \
  --platform linux/amd64 \
  --freeze \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

### With Layer Cache (Faster Rebuilds)

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

## Build from Conda

### From Packages

```bash
wave --conda-package bioconda::samtools=1.17 \
  --conda-package bioconda::bcftools=1.17 \
  --freeze \
  --build-repo cr.seqera.io/seqera-services/my-tools \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

### From Environment File

```bash
wave --conda-file environment.yml \
  --freeze \
  --build-repo cr.seqera.io/seqera-services/my-env \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

## Augment Existing Image

Add files to an existing image:

```bash
wave -i ubuntu:22.04 \
  --layer ./my-files/ \
  --freeze \
  --build-repo cr.seqera.io/seqera-services/my-ubuntu \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

## Mirror/Copy Images

Copy an image to another registry:

```bash
wave -i quay.io/biocontainers/samtools:1.17--h00cdaf9_0 \
  --mirror \
  --build-repo cr.seqera.io/seqera-services/samtools \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

## Options Reference

| Option | Description |
|--------|-------------|
| `-f <file>` | Dockerfile to build |
| `--context <dir>` | Build context directory |
| `--build-repo` | Registry for built images |
| `--cache-repo` | Registry for layer cache |
| `--platform` | Target platform (e.g., `linux/amd64`) |
| `--freeze` | Create persistent/immutable image |
| `--await [timeout]` | Wait for build (default 15min, e.g., `--await 30m`) |
| `-i <image>` | Base image to augment |
| `--layer <dir>` | Directory to add as layer |
| `--conda-package` | Conda package(s) to install |
| `--conda-file` | Conda environment file |
| `--mirror` | Copy image to build-repo |

## Output

Without `--freeze`: `wave.seqera.io/wt/abc123/ubuntu:latest` (temporary ~24h)

With `--freeze`: `cr.seqera.io/seqera-services/my-image:1a2b3c4d` (persistent)

See [references/TROUBLESHOOTING.md](references/TROUBLESHOOTING.md) for common issues.
