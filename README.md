# IGV Web App Studio for Seqera Platform

A containerized [IGV (Integrative Genomics Viewer)](https://igv.org/) web application designed to run as a Seqera Platform Studio environment. This allows users to visualize and analyze genomic data directly within their Seqera workspace.

## Features

- **Full IGV Web App**: Complete genomics visualization capabilities
- **CORS Support**: Properly configured to access external genomic data sources
- **Range Requests**: Supports indexed files (BAM, VCF, etc.) for efficient data loading
- **Seqera Integration**: Built on Seqera's Studio framework with dynamic port handling
- **Local Testing**: Includes docker-compose setup for development

## Quick Start

### Deploy to Seqera Platform

This repository uses **Seqera Platform's studio git integration** with Wave for automatic Docker image building.

1. In Seqera Platform, create a new Studio
2. Select **Git Repository** as the source
3. Point to this repository URL
4. Platform will automatically build the image via Wave using `.seqera/studio-config.yaml`

No manual Docker build or push required!

### Local Development

1. Clone this repository
2. Start the local environment:

```bash
docker-compose up --build
```

3. Open http://localhost:8080 in your browser

## Repository Structure

```
.seqera/                    # Seqera Platform configuration
├── studio-config.yaml      # Studio git integration config
├── Dockerfile              # Multi-stage Docker build
├── nginx.conf              # CORS-enabled nginx config
├── start.sh                # Container startup script
├── discover-data-links.sh  # Fusion data discovery
├── generate-igv-config.sh  # IGV config generator
└── igvwebConfig.template.js
test-data/                  # Sample data for local testing
docker-compose.yml          # Local development setup
```

## Supported Data Formats

IGV webapp supports a wide range of genomic file formats:

- **Sequence**: FASTA (.fa, .fasta), 2bit (.2bit)
- **Alignments**: BAM (.bam) + index (.bai), SAM (.sam), CRAM (.cram) + index (.crai)
- **Variants**: VCF (.vcf, .vcf.gz) + index (.tbi), BCF (.bcf)
- **Annotations**: BED (.bed), GFF (.gff, .gff3), GTF (.gtf), BigBed (.bb)
- **Coverage**: BigWig (.bw, .bigwig), Wiggle (.wig), TDF (.tdf)

## Fusion Data Link Integration

### Automatic Data Discovery

IGV Studio automatically discovers genomic data files from Seqera Platform Fusion-mounted data links. When you launch a Studio session with data links mounted, the container will:

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

Uses a multi-stage build for a lean final image:

| Stage | Base Image       | Purpose                                           |
| ----- | ---------------- | ------------------------------------------------- |
| 1     | `node:18-slim`   | Build IGV webapp (`npm install && npm run build`) |
| 2     | `connect-client` | Seqera Platform integration                       |
| 3     | `ubuntu:20.04`   | Runtime with nginx only                           |

The final image contains no Node.js runtime—only the compiled static files.

### Startup Process

1. `connect-client` initializes Seqera integration and mounts data links
2. `start.sh` waits for Fusion to populate `/workspace/data/` (up to 2 min timeout)
3. Discovery scripts scan for genomic files and generate IGV config
4. nginx starts serving IGV webapp on `CONNECT_TOOL_PORT`

## Troubleshooting

### Debug Mode

```bash
# Inside container
set -x
DEBUG=1 /usr/local/bin/discover-data-links.sh
nginx -T  # Test and dump configuration
```

## License

- [IGV.js](https://github.com/igvteam/igv.js) - MIT License
- [IGV-webapp](https://github.com/igvteam/igv-webapp) - MIT License
- nginx - BSD-2-Clause License

## Related Resources

- [IGV User Guide](https://igv.org/doc/webapp/)
- [Seqera Studios Documentation](https://docs.seqera.io/platform/latest/studios/)
- [IGV.js API Documentation](https://github.com/igvteam/igv.js/wiki)
