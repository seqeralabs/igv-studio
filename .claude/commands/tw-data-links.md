# Seqera Platform Data Links (tw data-links)

Browse, download, and manage cloud storage data through Seqera Platform.

## Prerequisites

```bash
export TOWER_ACCESS_TOKEN=$(op read "op://Employee/Seqera Platform Prod/password")
```

## Common Commands

### List Data Links

```bash
tw data-links list -w <workspace>
```

Example:

```bash
tw data-links list -w scidev/testing
```

### Browse Data Link Contents

Browse by name (if unique):

```bash
tw data-links browse -w <workspace> --name "<data-link-name>" -p "<path>"
```

Browse by URI with credentials:

```bash
tw data-links browse -w <workspace> --uri "s3://<bucket>" -c "<credentials-name>" -p "<path>"
```

Example:

```bash
tw data-links browse -w scidev/testing \
  --uri "s3://scidev-playground-eu-west-2" \
  -c "aws-scidev-playground" \
  -p ".studios/checkpoints/xSIFxRaKs9YMiQ6q"
```

### Download Files

```bash
tw data-links download -w <workspace> \
  --uri "s3://<bucket>" \
  -c "<credentials-name>" \
  -o <output-dir> \
  "<path/to/file>"
```

Example:

```bash
mkdir -p /tmp/downloads
tw data-links download -w scidev/testing \
  --uri "s3://scidev-playground-eu-west-2" \
  -c "aws-scidev-playground" \
  -o /tmp/downloads \
  ".studios/checkpoints/xSIFxRaKs9YMiQ6q/.command.log"
```

### Upload Files

```bash
tw data-links upload -w <workspace> \
  --uri "s3://<bucket>" \
  -c "<credentials-name>" \
  "<local-path>" \
  --path "<remote-path>"
```

### Add Custom Data Link

```bash
tw data-links add -w <workspace> \
  --name "<name>" \
  --provider <aws|google|azure> \
  --uri "s3://<bucket>" \
  --credentials "<credentials-name>"
```

Example:

```bash
tw data-links add -w scidev/testing \
  --name "my-custom-bucket" \
  --provider aws \
  --uri "s3://my-bucket-name" \
  --credentials "aws-scidev-playground"
```

### Delete Data Link

```bash
tw data-links delete -w <workspace> --id "<data-link-id>"
```

## List Available Credentials

To find credential names for use with `--credentials`:

```bash
tw credentials list -w <workspace>
```

## Options Reference

| Option              | Description                         |
| ------------------- | ----------------------------------- |
| `-w, --workspace`   | Workspace (e.g., `scidev/testing`)  |
| `-n, --name`        | Data link name                      |
| `--uri`             | Data link URI (e.g., `s3://bucket`) |
| `-c, --credentials` | Credentials identifier              |
| `-p, --path`        | Path within the data link           |
| `-i, --id`          | Data link ID                        |
| `-o, --output-dir`  | Output directory for downloads      |
| `-f, --filter`      | Filter files by prefix              |

## Troubleshooting

### "Data link not found"

The bucket may not be registered as a data link. Use `--uri` with `--credentials` instead:

```bash
tw data-links browse --uri "s3://bucket" -c "credentials-name" -p "path"
```

### "Multiple DataLink items found"

Use `--id` instead of `--name` when there are duplicates:

```bash
tw data-links browse --id "v1-user-xxxxx" -p "path"
```

### "Unauthorized"

Check that `TOWER_ACCESS_TOKEN` is set and valid:

```bash
echo $TOWER_ACCESS_TOKEN | head -c 10
```

## Complete Workflow: IGV Test Data

Create a data link, upload test genomic data, and mount it in a studio:

### 1. Create the Data Link

```bash
tw data-links add -w scidev/testing \
  --name "igv-test-data" \
  --provider aws \
  --uri "s3://scidev-playground-eu-west-2/igv-test-data" \
  --credentials "aws-scidev-playground"
```

### 2. Upload Test Files

```bash
# Upload VCF and index
tw data-links upload -w scidev/testing \
  --uri "s3://scidev-playground-eu-west-2" \
  -c "aws-scidev-playground" \
  test-data/sample.vcf.gz \
  --path "igv-test-data/sample.vcf.gz"

tw data-links upload -w scidev/testing \
  --uri "s3://scidev-playground-eu-west-2" \
  -c "aws-scidev-playground" \
  test-data/sample.vcf.gz.tbi \
  --path "igv-test-data/sample.vcf.gz.tbi"

# Upload BED file
tw data-links upload -w scidev/testing \
  --uri "s3://scidev-playground-eu-west-2" \
  -c "aws-scidev-playground" \
  test-data/features.bed \
  --path "igv-test-data/features.bed"
```

### 3. Verify Upload

```bash
tw data-links browse -w scidev/testing \
  --name "igv-test-data"
```

### 4. Launch Studio with Data Link

```bash
tw studios add \
  --name "IGV Studio - Test Data" \
  --workspace "scidev/testing" \
  --custom-template "<IMAGE_URL>" \
  --compute-env "seqera_aws_london_fusion_nvme" \
  --mount-data "igv-test-data" \
  --auto-start
```

The data will be available at `/workspace/data/igv-test-data/` inside the container.

### 5. IGV Auto-Discovery

IGV Studio will automatically:

1. Wait for Fusion to populate `/workspace/data/`
2. Scan for genomic files (BAM, VCF, BED, FASTA, BigWig, etc.)
3. Generate IGV configuration with discovered tracks
4. Display tracks organized by data link name
