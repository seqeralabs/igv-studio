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

1. Build and push the Docker image:

```bash
docker build -t your-registry/igv-studio:latest .
docker push your-registry/igv-studio:latest
```

2. In Seqera Platform, create a new Studio with:
   - **Image**: `your-registry/igv-studio:latest`
   - **Tool**: Web Application
   - **Description**: IGV Genomics Viewer

3. Launch the Studio and access IGV webapp through the provided URL

### Local Development

1. Clone this repository
2. Start the local environment:

```bash
docker-compose up --build
```

3. Open http://localhost:8080 in your browser

## Supported Data Formats

IGV webapp supports a wide range of genomic file formats:

### Sequence Data

- FASTA (.fa, .fasta)
- 2bit (.2bit)

### Alignment Data

- BAM (.bam) + index (.bai)
- SAM (.sam)
- CRAM (.cram) + index (.crai)

### Variant Data

- VCF (.vcf, .vcf.gz) + index (.tbi)
- BCF (.bcf)

### Annotation Data

- BED (.bed)
- GFF (.gff, .gff3)
- GTF (.gtf)
- BigBed (.bb)

### Coverage Data

- BigWig (.bw, .bigwig)
- Wiggle (.wig)
- TDF (.tdf)

## Data Loading Options

### 1. Local Files

- Use "Local File" button in IGV to upload files from your computer
- Supports drag-and-drop functionality
- Files are processed entirely in the browser (no server upload)

### 2. URL-based Loading

- Load data directly from web URLs
- Requires CORS-enabled servers for cross-origin access
- Supports cloud storage (AWS S3, Google Cloud Storage, etc.)

### 3. Sample Data

IGV includes built-in sample datasets for testing:

- Human genome (hg38, hg19)
- Mouse genome (mm10)
- Various annotation tracks

## CORS Configuration

For loading data from external servers, ensure CORS headers are properly configured:

### Required Headers

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, HEAD, OPTIONS
Access-Control-Allow-Headers: Range, Content-Type
Access-Control-Expose-Headers: Content-Length, Content-Range, Content-Type
```

### Example nginx Configuration

```nginx
location ~* \.(bam|bai|vcf|bed|gff|bigwig|bw)$ {
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, HEAD, OPTIONS';
    add_header 'Access-Control-Expose-Headers' 'Content-Length, Content-Range';
    add_header 'Accept-Ranges' 'bytes';
}
```

### Cloud Storage Examples

#### AWS S3

Configure bucket CORS policy:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": ["Content-Length", "Content-Range"]
  }
]
```

#### Google Cloud Storage

```bash
gsutil cors set cors-config.json gs://your-bucket-name
```

## Fusion Data Link Integration

### Automatic Data Discovery

IGV Studio automatically discovers genomic data files from Seqera Platform Fusion-mounted data links. When you launch a Studio session with data links mounted, the container will:

1. **Scan** `/workspace/data/` for mounted buckets
2. **Detect** genomic files (BAM, VCF, BED, FASTA, BigWig, etc.)
3. **Auto-configure** IGV with your data as pre-loaded tracks
4. **Organize** tracks by data link source for easy navigation

### Supported Auto-Discovery

**File Types Automatically Detected:**

- **Alignments**: BAM, SAM, CRAM (+ .bai, .csi indices)
- **Variants**: VCF, VCF.GZ, BCF (+ .tbi, .csi indices)
- **Annotations**: BED, GFF, GTF, BigBed (+ .tbi indices)
- **Coverage**: BigWig, Wiggle files
- **Reference**: FASTA (+ .fai indices)
- **Segmentation**: SEG files
- **Mutations**: MAF files

**Index File Detection:**
The system automatically pairs data files with their indices:

- `sample.bam` → `sample.bam.bai`
- `variants.vcf.gz` → `variants.vcf.gz.tbi`
- `genome.fa` → `genome.fa.fai`

### Custom User Configurations

Users can provide custom IGV configurations by placing a JSON file in their data link bucket. The system looks for these filename patterns:

- `igv-config.json` (recommended)
- `igvConfig.json`
- `igv.json`
- `.igv-config.json`
- `config/igv.json`

#### Custom Config Example

Place this in your bucket as `igv-config.json`:

```json
{
  "tracks": [
    {
      "name": "My RNA-seq Data",
      "url": "/workspace/data/my-project/rnaseq.bw",
      "type": "wig",
      "color": "rgb(255, 0, 0)",
      "height": 150,
      "min": 0,
      "max": 100
    },
    {
      "name": "Project Variants",
      "url": "/workspace/data/my-project/variants.vcf.gz",
      "indexURL": "/workspace/data/my-project/variants.vcf.gz.tbi",
      "type": "variant",
      "displayMode": "EXPANDED"
    }
  ],
  "genomes": [
    {
      "id": "my-custom-genome",
      "name": "My Custom Reference",
      "fastaURL": "/workspace/data/my-project/reference.fa",
      "indexURL": "/workspace/data/my-project/reference.fa.fai"
    }
  ],
  "locus": "chr1:1,000,000-2,000,000",
  "reference": {
    "id": "my-custom-genome"
  }
}
```

### Data Organization in IGV

**Track Naming:**

- Auto-discovered tracks: `DataLinkName - FileName`
- User-defined tracks: Use provided names

**Track Grouping:**

- Tracks are organized by data link source
- Each bucket appears as a separate track group
- User configs can override default organization

**Example Studio View:**

```
IGV Browser
├── biopharmaX-project-a/
│   ├── Project A - sample1 (alignment)
│   ├── Project A - variants (variants)
│   └── Project A - coverage (wig)
├── reference-genomes/
│   └── Reference - hg38-custom (genome)
└── User Defined Tracks/
    ├── My RNA-seq Data (wig)
    └── Project Variants (variant)
```

## Architecture

### Docker Build

Uses a multi-stage build for a lean final image:

| Stage | Base Image       | Purpose                                           |
| ----- | ---------------- | ------------------------------------------------- |
| 1     | `node:18-slim`   | Build IGV webapp (`npm install && npm run build`) |
| 2     | `connect-client` | Seqera Platform integration                       |
| 3     | `ubuntu:20.04`   | Runtime with nginx only                           |

The final image contains no Node.js runtime—only the compiled static files.

### Container Structure

```
/opt/igv-webapp/          # IGV webapp static files (built from source)
/etc/nginx/               # nginx configuration
/usr/local/bin/start.sh   # Startup script with Fusion wait logic
```

### Startup Process

1. `connect-client` initializes Seqera integration and mounts data links
2. `start.sh` waits for Fusion to populate `/workspace/data/` (up to 2 min timeout)
3. Discovery scripts scan for genomic files and generate IGV config
4. nginx starts serving IGV webapp on `CONNECT_TOOL_PORT`

> **Note:** Fusion creates mount directories immediately but populates files asynchronously. The startup script waits for actual files before running discovery.

### Security Features

- CORS headers for cross-origin data access
- Content security headers (X-Frame-Options, etc.)
- No server-side data storage (client-side only processing)

## Customization

### Custom IGV Configuration

To customize the IGV webapp configuration, modify the Dockerfile to include your config files:

```dockerfile
# Copy custom IGV configuration
COPY igvConfig.js /opt/igv-webapp/js/igvConfig.js
```

### Additional Genomic Tools

Extend the container to include additional bioinformatics tools:

```dockerfile
# Install samtools, bcftools, etc.
RUN apt-get update && apt-get install -y samtools bcftools tabix
```

### Custom Data Sources

Pre-configure data sources by modifying the IGV webapp configuration:

```javascript
// Custom genome and track definitions
var customGenomes = {
  mygenome: {
    id: "mygenome",
    name: "My Custom Genome",
    fastaURL: "https://myserver.com/genome.fa",
    indexURL: "https://myserver.com/genome.fa.fai",
  },
};
```

## Troubleshooting

### Common Issues

#### IGV Not Loading

- Check browser console for JavaScript errors
- Verify nginx is running: `docker-compose logs`
- Confirm port mapping in docker-compose.yml

#### Data Loading Fails

- Verify CORS headers on your data server
- Check file permissions and accessibility
- Ensure index files are available for large datasets

#### Studio Connection Issues

- Confirm `CONNECT_TOOL_PORT` environment variable is set
- Check Seqera Platform network connectivity
- Verify image registry access

### Debug Mode

Enable debug logging by modifying `start.sh`:

```bash
# Add debug output
set -x
nginx -T  # Test and dump configuration
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test locally with docker-compose
4. Submit a pull request

## License

This project builds on several open-source components:

- [IGV.js](https://github.com/igvteam/igv.js) - MIT License
- [IGV-webapp](https://github.com/igvteam/igv-webapp) - MIT License
- nginx - BSD-2-Clause License

## Support

For issues related to:

- **IGV functionality**: [IGV Support Forum](https://groups.google.com/forum/#!forum/igv-help)
- **Seqera Platform**: [Seqera Documentation](https://docs.seqera.io/)
- **This container**: Open an issue in this repository

## Related Resources

- [IGV User Guide](https://igv.org/doc/webapp/)
- [Seqera Studios Documentation](https://docs.seqera.io/platform/latest/studios/)
- [IGV.js API Documentation](https://github.com/igvteam/igv.js/wiki)
- [Genomic File Formats Guide](https://genome.ucsc.edu/FAQ/FAQformat.html)
