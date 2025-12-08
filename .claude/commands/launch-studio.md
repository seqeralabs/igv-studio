# Launch IGV Studio

Launch an IGV Studio instance on Seqera Platform.

## Instructions

1. Get the Tower access token from 1Password:
```bash
export TOWER_ACCESS_TOKEN=$(op read "op://Employee/Seqera Platform Prod/password")
```

2. Launch the studio with `tw studios add`:
```bash
tw studios add \
  --name "IGV Studio" \
  --workspace "scidev/testing" \
  --custom-template "ghcr.io/edmundmiller/igv-studio:latest" \
  --compute-env "seqera_aws_london_fusion_nvme" \
  --auto-start
```

## Optional: Mount Data Links

To mount data links for genomic data access:
```bash
tw studios add \
  --name "IGV Studio - My Project" \
  --workspace "scidev/testing" \
  --custom-template "ghcr.io/edmundmiller/igv-studio:latest" \
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
