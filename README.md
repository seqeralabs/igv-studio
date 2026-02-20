# IGV Web App Studio for Seqera Platform

A containerized [IGV (Integrative Genomics Viewer)](https://igv.org/) web application designed to run as a Seqera Platform Studio. Visualize and analyze genomic data directly within your Seqera workspace.

## Features

- **Full IGV Web App** — complete genomics visualization
- **Auto-Discovery** — automatically detects and loads genomic files from Fusion-mounted data links
- **Git Integration** — deploy via Seqera Platform's studio git integration, no manual Docker builds
- **CORS + Range Requests** — access external data sources and indexed files (BAM, VCF, etc.)

## Deploy to Seqera Platform

> **First time?** Your workspace needs one-time setup for studio git integration (ECR repo, credentials, compute environment). See [docs/workspace-setup.md](docs/workspace-setup.md).

Once workspace setup is done:

1. Go to your workspace → **Studios** → **Add Studio**
2. Select **Import from Git repository**
3. Enter this repository URL, select `main` branch
4. Choose an AWS Batch compute environment
5. Optionally mount data links with your genomic data
6. Click **Create**

Wave builds the image automatically. The studio will be ready in a few minutes.

## Local Development

```bash
docker-compose up --build
# Open http://localhost:8080
```

## Supported Data Formats

- **Sequence**: FASTA, 2bit
- **Alignments**: BAM + index, SAM, CRAM + index
- **Variants**: VCF (.vcf, .vcf.gz) + index, BCF
- **Annotations**: BED, GFF, GTF, BigBed
- **Coverage**: BigWig, Wiggle, TDF

## Fusion Data Link Integration

### Automatic Data Discovery

When you launch with data links mounted, the studio will:

1. **Scan** `/workspace/data/` for mounted buckets
2. **Detect** genomic files (BAM, VCF, BED, FASTA, BigWig, etc.)
3. **Auto-configure** IGV with your data as pre-loaded tracks
4. **Organize** tracks by data link source

### Custom Configurations

Place a custom IGV config in your data link bucket:

- `igv-config.json` (recommended)
- `igvConfig.json`, `igv.json`, `.igv-config.json`, `config/igv.json`

See `.seqera/example-user-config.json` for a template.

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
docs/
└── workspace-setup.md       # One-time workspace setup guide
docker-compose.yml           # Local development setup
```

## Architecture

Multi-stage Docker build:

| Stage | Base Image       | Purpose                                           |
| ----- | ---------------- | ------------------------------------------------- |
| 1     | `node:18-slim`   | Build IGV webapp (`npm install && npm run build`) |
| 2     | `connect-client` | Seqera Platform integration                       |
| 3     | `ubuntu:20.04`   | Runtime with nginx only                           |

At startup: `connect-client` → Fusion data mounts → auto-discovery scripts → nginx serves IGV.

## Troubleshooting

See [docs/workspace-setup.md#troubleshooting](docs/workspace-setup.md#troubleshooting) for deployment errors.

For runtime debugging inside the container:

```bash
DEBUG=1 /usr/local/bin/discover-data-links.sh
nginx -T
```

## License

- [IGV.js](https://github.com/igvteam/igv.js) — MIT
- [IGV-webapp](https://github.com/igvteam/igv-webapp) — MIT

## Related Resources

- [docs/workspace-setup.md](docs/workspace-setup.md) — Workspace setup for studio git integration
- [IGV User Guide](https://igv.org/doc/webapp/)
- [Seqera Studios Docs](https://docs.seqera.io/platform-cloud/studios/)
- [Studio Git Integration](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
