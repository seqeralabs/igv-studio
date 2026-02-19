# Data Discovery Issues

## How Discovery Works

1. Fusion creates mount directories immediately but populates files asynchronously
2. `start.sh` waits for files to appear (up to 2 min)
3. `discover-data-links.sh` scans for genomic files
4. `generate-igv-config.sh` creates IGV configuration

## Timing Issue

Fusion mounts directories immediately but populates files asynchronously. The wait loop checks for actual files, not just directory existence:

```bash
# In start.sh
WAIT_TIMEOUT=60
WAITED=0
while [ ! -d "/workspace/data" ] || [ -z "$(ls -A /workspace/data 2>/dev/null)" ]; do
    if [ $WAITED -ge $WAIT_TIMEOUT ]; then
        echo "No data links mounted after ${WAIT_TIMEOUT}s, using default config"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
done
```

## Verify Discovery

```bash
# Check Fusion mount
ls -la /workspace/data/

# Check discovery output
cat /tmp/discovered-tracks.json | jq .

# Check generated config
cat /opt/igv-webapp/js/igvwebConfig.js

# Re-run discovery with debug
DEBUG=1 /usr/local/bin/discover-data-links.sh
```

## Supported File Types

Discovery scans for:
- **Alignments**: BAM, SAM, CRAM + indices (.bai, .csi)
- **Variants**: VCF, VCF.GZ, BCF + indices (.tbi, .csi)
- **Annotations**: BED, GFF, GTF, BigBed
- **Coverage**: BigWig, Wiggle
- **Reference genomes**: FASTA, 2bit + indices (.fai)

## User Config Detection

Also detects user-provided configs:
- `igv-config.json`
- `igvConfig.json`
- `igv.json`
- `.igv-config.json`
- `config/igv.json`
