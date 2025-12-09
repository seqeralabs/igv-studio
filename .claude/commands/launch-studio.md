# Launch IGV Studio

Launch an IGV Studio instance on Seqera Platform.

## Prerequisites

1. Get the Tower access token from 1Password:

```bash
export TOWER_ACCESS_TOKEN=$(op read "op://Employee/Seqera Platform Prod/password")
```

## Build and Push Image

**Recommended: Use Wave** (see `/build-wave` skill):

```bash
wave -f Dockerfile --context . --build-repo cr.seqera.io/seqera-services/igv-studio \
  --platform linux/amd64 --freeze --await --tower-token "$TOWER_ACCESS_TOKEN"
```

Alternative with Docker buildx (requires local Docker + ghcr.io auth):

```bash
gh auth refresh -h github.com -s write:packages
docker buildx build --platform linux/amd64 -t cr.seqera.io/seqera-services/igv-studio:latest --push .
```

## Launch Studio

```bash
tw studios add \
  --name "IGV Studio" \
  --workspace "scidev/testing" \
  --custom-template "cr.seqera.io/seqera-services/igv-studio:latest" \
  --compute-env "seqera_aws_london_fusion_nvme" \
  --auto-start
```

## Optional: Mount Data Links

To mount data links for genomic data access:

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

## Check Studio Status

```bash
tw studios list -w scidev/testing
tw studios view --name "IGV Studio" -w scidev/testing
```

## Troubleshooting

### `CannotPullContainerError: no matching manifest for linux/amd64`

The image was built for the wrong architecture. Rebuild with:

```bash
docker buildx build --platform linux/amd64 -t cr.seqera.io/seqera-services/igv-studio:latest --push .
```

### `could not open loop device: open /dev/loop0: permission denied`

The connect-client needs root privileges to set up loop devices for Fusion. Ensure the Dockerfile does NOT have a `USER` directive - the container must run as root.

### `permission_denied` when pushing to ghcr.io

Your GitHub token needs `write:packages` scope:

```bash
gh auth refresh -h github.com -s write:packages
```

## Image Requirements

- **Connect client**: v0.9.0+ (set via `CONNECT_CLIENT_VERSION` build arg)
- **Architecture**: linux/amd64 for cloud compute environments
- **User**: Must run as root (no `USER` directive) for Fusion loop device setup
