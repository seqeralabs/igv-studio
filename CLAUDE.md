# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IGV Web App Studio is a containerized [IGV (Integrative Genomics Viewer)](https://igv.org/) web application for Seqera Platform Studios. It provides genomic data visualization with automatic discovery of Fusion-mounted data links. Deployed via Seqera Platform's studio git integration — Wave builds the Docker image automatically from `.seqera/studio-config.yaml`.

## Build and Run Commands

```bash
# Local development
docker-compose up --build         # Build and run on localhost:8080

# Debug data discovery (inside container)
DEBUG=1 /usr/local/bin/discover-data-links.sh
```

## Deployment

This repo uses **studio git integration**. Platform builds the image via Wave using `.seqera/studio-config.yaml` (kind: dockerfile). No manual Docker build/push needed.

Workspace setup (ECR, credentials, compute env) is documented in [docs/workspace-setup.md](docs/workspace-setup.md).

## Architecture

### Multi-Stage Docker Build

The Dockerfile (`.seqera/Dockerfile`) uses a 3-stage build:

```
Stage 1: node:18-slim     → npm install && npm run build (IGV webapp)
Stage 2: connect-client   → Seqera Platform integration
Stage 3: ubuntu:20.04     → Runtime with nginx (no Node.js needed)
```

**Why multi-stage?** IGV webapp has no pre-built releases. Source code requires Node.js to build, but the output (`dist/`) is static files that nginx serves directly.

### Container Startup Flow

1. `connect-client` initializes Seqera integration and mounts data links
2. `start.sh` waits for Fusion to populate `/workspace/data/` (up to 60s)
3. Discovery scripts run if data files are found:
   - `discover-data-links.sh` → scans for genomic files → `/tmp/discovered-tracks.json`
   - `generate-igv-config.sh` → merges with template → `/opt/igv-webapp/js/igvwebConfig.js`
4. nginx starts serving IGV webapp on `CONNECT_TOOL_PORT`

**Timing note:** Fusion mounts directories immediately but populates files asynchronously. The wait loop checks for actual files, not just directory existence.

### Key Files

| File                              | Purpose                                                        |
| --------------------------------- | -------------------------------------------------------------- |
| `.seqera/studio-config.yaml`      | Studio git integration config for Wave builds                  |
| `.seqera/Dockerfile`              | Multi-stage build (node → connect-client → ubuntu+nginx)       |
| `.seqera/start.sh`               | Container entrypoint: waits for Fusion, runs discovery, starts nginx |
| `.seqera/discover-data-links.sh`  | Scans `/workspace/data/` for genomic files, outputs JSON       |
| `.seqera/generate-igv-config.sh`  | Converts discovered JSON to IGV JavaScript config              |
| `.seqera/igvwebConfig.template.js`| Base IGV configuration template                                |
| `.seqera/nginx.conf`              | CORS-enabled nginx config with `CONNECT_TOOL_PORT_PLACEHOLDER` |

### Fusion Data Link Discovery

The discovery script scans `/workspace/data/<datalink>/` directories for:

- **Alignments**: BAM, SAM, CRAM + indices (.bai, .csi)
- **Variants**: VCF, VCF.GZ, BCF + indices (.tbi, .csi)
- **Annotations**: BED, GFF, GTF, BigBed
- **Coverage**: BigWig, Wiggle
- **Reference genomes**: FASTA, 2bit + indices (.fai)

User-provided IGV configs are also detected: `igv-config.json`, `igvConfig.json`, `igv.json`, `.igv-config.json`, `config/igv.json`

### Port Handling

- Seqera Platform: Uses `CONNECT_TOOL_PORT` environment variable (set by connect-client)
- nginx.conf uses `CONNECT_TOOL_PORT_PLACEHOLDER` which gets sed-replaced at startup

## Testing

```bash
docker-compose up --build    # localhost:8080

# Inside container
cat /tmp/discovered-tracks.json | jq .
```
