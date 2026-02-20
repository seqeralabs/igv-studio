# IGV Web App Studio for Seqera Platform

A containerized [IGV (Integrative Genomics Viewer)](https://igv.org/) web application designed to run as a Seqera Platform Studio environment. Visualize and analyze genomic data directly within your Seqera workspace.

## Features

- **Full IGV Web App**: Complete genomics visualization capabilities
- **CORS Support**: Properly configured to access external genomic data sources
- **Range Requests**: Supports indexed files (BAM, VCF, etc.) for efficient data loading
- **Auto-Discovery**: Automatically detects and loads genomic files from Fusion-mounted data links
- **Git Integration**: Deploy via Seqera Platform's studio git integration — no manual Docker builds

## Deploy to Seqera Platform

### Prerequisites

Before creating the studio, the workspace needs three things configured:

1. **Container repository** — an ECR (or other registry) repo where Wave pushes built images
2. **Registry credentials** — so the compute environment can pull the built image
3. **AWS Batch compute environment** — Studios require AWS Batch (Forge) or AWS Cloud CEs

See [Workspace Setup](#workspace-setup) below for details.

### Create the Studio

1. In Seqera Platform, go to your workspace → **Studios** → **Add Studio**
2. Select **Import from Git repository**
3. Enter this repository URL and select the `main` branch
4. Choose an AWS Batch compute environment
5. Click **Create** — Wave builds the image automatically from `.seqera/studio-config.yaml`

### Workspace Setup

#### 1. Create an ECR Repository

Wave needs a container registry to push built images. Create an ECR repo in the same region as your compute environment:

```bash
aws ecr create-repository \
  --repository-name <your-org>/studios \
  --region <your-region>
```

#### 2. Configure Container Repository in Platform

Go to **Settings → Studios → Container repository** and enter the full ECR path:

```
<account-id>.dkr.ecr.<region>.amazonaws.com/<your-org>/studios
```

> **Note:** Ensure credentials with push/pull permission to this registry are added on the workspace Credentials page. For ECR, an AWS credential with `ecr:*` permissions works.

#### 3. Cross-Account ECR Access

If your compute environment runs in a different AWS account than your ECR repo (common with Forge-provisioned Batch), add a resource policy to the ECR repo:

```bash
aws ecr set-repository-policy \
  --repository-name <your-org>/studios \
  --region <your-region> \
  --policy-text '{
    "Version": "2012-10-17",
    "Statement": [{
      "Sid": "AllowCrossAccountPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<compute-account-id>:root"
      },
      "Action": [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchCheckLayerAvailability"
      ]
    }]
  }'
```

Find the compute account ID from the error message if the first launch fails with `CannotPullImageManifestError`.

#### 4. Compute Environment

Studios need an **AWS Batch** (Forge, on-demand EC2) or **AWS Cloud** compute environment. Seqera Compute CEs don't reliably support Studios yet.

Create via Platform UI or API:
- **Platform:** AWS Batch
- **Provisioning:** Forge, EC2 (on-demand)
- **Instance types:** m5.large or larger
- **Wave + Fusion:** enabled

#### 5. GitHub Credential (private repos only)

If the repo is private, create a [fine-grained GitHub PAT](https://github.com/settings/personal-access-tokens/new) scoped to this repo with **Contents: read-only**, then add it as a GitHub credential in the workspace.

## Local Development

```bash
docker-compose up --build
# Open http://localhost:8080
```

## Repository Structure

```
.seqera/                     # Seqera Platform configuration
├── studio-config.yaml       # Studio git integration config
├── Dockerfile               # Multi-stage Docker build
├── nginx.conf               # CORS-enabled nginx config
├── start.sh                 # Container startup script
├── discover-data-links.sh   # Fusion data discovery
├── generate-igv-config.sh   # IGV config generator
├── igvwebConfig.template.js # Base IGV configuration
└── example-user-config.json # Template for user configs
docker-compose.yml           # Local development setup
test-data/                   # Sample data for local testing
```

## Supported Data Formats

- **Sequence**: FASTA (.fa, .fasta), 2bit (.2bit)
- **Alignments**: BAM (.bam) + index (.bai), SAM (.sam), CRAM (.cram) + index (.crai)
- **Variants**: VCF (.vcf, .vcf.gz) + index (.tbi), BCF (.bcf)
- **Annotations**: BED (.bed), GFF (.gff, .gff3), GTF (.gtf), BigBed (.bb)
- **Coverage**: BigWig (.bw, .bigwig), Wiggle (.wig), TDF (.tdf)

## Fusion Data Link Integration

### Automatic Data Discovery

When you launch a Studio session with data links mounted, the container will:

1. **Scan** `/workspace/data/` for mounted buckets
2. **Detect** genomic files (BAM, VCF, BED, FASTA, BigWig, etc.)
3. **Auto-configure** IGV with your data as pre-loaded tracks
4. **Organize** tracks by data link source for easy navigation

### Custom User Configurations

Place a custom IGV config file in your data link bucket:

- `igv-config.json` (recommended)
- `igvConfig.json`, `igv.json`, `.igv-config.json`, `config/igv.json`

See `.seqera/example-user-config.json` for a template.

## Architecture

### Docker Build

Multi-stage build for a lean final image:

| Stage | Base Image       | Purpose                                           |
| ----- | ---------------- | ------------------------------------------------- |
| 1     | `node:18-slim`   | Build IGV webapp (`npm install && npm run build`) |
| 2     | `connect-client` | Seqera Platform integration                       |
| 3     | `ubuntu:20.04`   | Runtime with nginx only                           |

The final image contains no Node.js runtime — only the compiled static files served by nginx.

### Startup Process

1. `connect-client` initializes Seqera integration and mounts data links
2. `start.sh` waits for Fusion to populate `/workspace/data/` (up to 60s timeout)
3. Discovery scripts scan for genomic files and generate IGV config
4. nginx starts serving IGV webapp on `CONNECT_TOOL_PORT`

## Troubleshooting

### Common Deployment Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `buildRepository must be specified when using freeze mode` | No container repository in workspace settings | Set ECR path in Settings → Studios → Container repository |
| `Missing credentials for container repository` | No registry credential in workspace | Add AWS or container-reg credential with ECR access |
| `CannotPullImageManifestError` | Cross-account ECR pull denied | Add ECR resource policy for the compute account (see [Cross-Account ECR Access](#3-cross-account-ecr-access)) |
| Studio stops during "Provisioning compute resources" | Incompatible compute env type | Use AWS Batch (Forge, EC2) instead of Seqera Compute |

### Debug Mode

```bash
# Inside container
DEBUG=1 /usr/local/bin/discover-data-links.sh
nginx -T  # Test and dump nginx configuration
```

## License

- [IGV.js](https://github.com/igvteam/igv.js) - MIT License
- [IGV-webapp](https://github.com/igvteam/igv-webapp) - MIT License
- nginx - BSD-2-Clause License

## Related Resources

- [IGV User Guide](https://igv.org/doc/webapp/)
- [Seqera Studios Documentation](https://docs.seqera.io/platform-cloud/studios/)
- [Studio Git Integration Docs](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [IGV.js API Documentation](https://github.com/igvteam/igv.js/wiki)
