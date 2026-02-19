---
name: launch-igv-studio
description: Launch IGV Studio instances on Seqera Platform. Use when deploying IGV Studio, starting genomics visualization studios, or mounting data links to studios.
compatibility: Requires tw CLI, TOWER_ACCESS_TOKEN, and optionally wave CLI for building images.
metadata:
  author: Seqera/edmundmiller
  version: "1.0"
---

# Launch IGV Studio

Launch IGV Studio instances on Seqera Platform with optional data link mounting.

## Prerequisites

```bash
export TOWER_ACCESS_TOKEN=$(op read "op://Employee/Seqera Platform Prod/password")
```

## Quick Start

Build with Wave and launch immediately:

```bash
# Build and capture image URL
IMAGE_URL=$(wave -f Dockerfile --context . --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN")

# Launch studio
tw studios add \
  --name "IGV Studio" \
  --workspace "scidev/testing" \
  --custom-template "$IMAGE_URL" \
  --compute-env "seqera_aws_london_fusion_nvme" \
  --auto-start
```

## Build Options

### Option 1: Wave Temporary URL (~24h)

No registry push permissions required:

```bash
wave -f Dockerfile --context . --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
# Returns: wave.seqera.io/wt/xxxxx/wave/build:yyyyy
```

### Option 2: Wave Persistent Image

Requires push permissions to target registry:

```bash
wave -f Dockerfile --context . --build-repo cr.seqera.io/seqera-services/igv-studio \
  --platform linux/amd64 --freeze --await --tower-token "$TOWER_ACCESS_TOKEN"
```

### Option 3: Docker buildx (Local)

Requires local Docker + registry auth:

```bash
gh auth refresh -h github.com -s write:packages
docker buildx build --platform linux/amd64 -t cr.seqera.io/seqera-services/igv-studio:latest --push .
```

## Launch with Data Links

Mount data links for genomic data access:

```bash
tw studios add \
  --name "IGV Studio - My Project" \
  --workspace "scidev/testing" \
  --custom-template "cr.seqera.io/seqera-services/igv-studio:latest" \
  --compute-env "seqera_aws_london_fusion_nvme" \
  --mount-data "my-data-link-name" \
  --auto-start
```

## Available Compute Environments (scidev/testing)

- `seqera_aws_london_fusion_nvme` - AWS Batch with Fusion + NVMe (recommended)
- `seqera_gcp_finland_fusion` - Google Batch with Fusion
- `seqera_azure_virginia_fusion` - Azure Batch with Fusion

## Manage Studios

```bash
# List studios
tw studios list -w scidev/testing

# View studio details
tw studios view --name "IGV Studio" -w scidev/testing

# Stop studio by session ID
tw studios stop --session-id <SESSION_ID> -w scidev/testing
```

## Image Requirements

- **Connect client**: v0.9.0+ (set via `CONNECT_CLIENT_VERSION` build arg)
- **Architecture**: linux/amd64 for cloud compute environments
- **User**: Must run as root (no `USER` directive) for Fusion loop device setup

See [references/TROUBLESHOOTING.md](references/TROUBLESHOOTING.md) for common issues.
See [references/WORKFLOW.md](references/WORKFLOW.md) for iterative development workflow.
