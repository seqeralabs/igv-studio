# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IGV Web App Studio is a containerized [IGV (Integrative Genomics Viewer)](https://igv.org/) web application for Seqera Platform Studios. It provides genomic data visualization with automatic discovery of Fusion-mounted data links.

## Build and Run Commands

```bash
# Build Docker image
./build.sh [TAG]                  # e.g., ./build.sh 1.0.0
REGISTRY=your.registry ./build.sh # Build with registry prefix

# Local development
docker-compose up --build         # Build and run on localhost:8080

# Standalone build (for testing without Seqera Platform)
docker build -f Dockerfile.standalone -t igv-studio:standalone .
docker run -p 8080:8080 -v ./test-data:/workspace/data igv-studio:standalone

# Debug data discovery
DEBUG=1 /usr/local/bin/discover-data-links.sh
```

## Architecture

### Multi-Stage Docker Build

The Dockerfile uses a 3-stage build to keep the final image lean:

```
Stage 1: node:18-slim     → npm install && npm run build (IGV webapp)
Stage 2: connect-client   → Seqera Platform integration
Stage 3: ubuntu:20.04     → Runtime with nginx (no Node.js needed)
```

**Why multi-stage?** IGV webapp has no pre-built releases. Source code requires Node.js to build, but the output (`dist/`) is static files that nginx serves directly.

### Container Startup Flow

1. `connect-client` initializes Seqera integration and mounts data links
2. `start.sh` waits for Fusion to populate `/workspace/data/` (up to 2 min)
3. Discovery scripts run if data files are found:
   - `discover-data-links.sh` → scans for genomic files → `/tmp/discovered-tracks.json`
   - `generate-igv-config.sh` → merges with template → `/opt/igv-webapp/js/igvwebConfig.js`
4. nginx starts serving IGV webapp on `CONNECT_TOOL_PORT`

**Timing note:** Fusion mounts directories immediately but populates files asynchronously. The wait loop checks for actual files, not just directory existence.

### Key Files

| File                       | Purpose                                                        |
| -------------------------- | -------------------------------------------------------------- |
| `Dockerfile`               | Seqera Platform image (uses connect-client)                    |
| `Dockerfile.standalone`    | Testing image (no Seqera deps)                                 |
| `discover-data-links.sh`   | Scans `/workspace/data/` for genomic files, outputs JSON       |
| `generate-igv-config.sh`   | Converts discovered JSON to IGV JavaScript config              |
| `igvwebConfig.template.js` | Base IGV configuration template                                |
| `nginx.conf`               | CORS-enabled nginx config with `CONNECT_TOOL_PORT_PLACEHOLDER` |

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
- Standalone: Uses `PORT` env var, defaults to 8080
- nginx.conf uses `CONNECT_TOOL_PORT_PLACEHOLDER` which gets sed-replaced at startup

## Testing

Mount test data to `/workspace/data/` to test auto-discovery:

```bash
docker run -p 8080:8080 \
  -v /path/to/genomic/data:/workspace/data/my-datalink:ro \
  igv-studio:standalone
```

Verify discovery output:

```bash
# Inside container
cat /tmp/discovered-tracks.json | jq .
```
