# Complete IGV Test Data Workflow

Create a data link, upload test genomic data, and mount it in a studio.

## 1. Create the Data Link

```bash
tw data-links add -w scidev/testing \
  --name "igv-test-data" \
  --provider aws \
  --uri "s3://scidev-playground-eu-west-2/igv-test-data" \
  --credentials "aws-scidev-playground"
```

## 2. Upload Test Files

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

## 3. Verify Upload

```bash
tw data-links browse -w scidev/testing --name "igv-test-data"
```

## 4. Launch Studio with Data Link

```bash
tw studios add \
  --name "IGV Studio - Test Data" \
  --workspace "scidev/testing" \
  --custom-template "<IMAGE_URL>" \
  --compute-env "seqera_aws_london_fusion_nvme" \
  --mount-data "igv-test-data" \
  --auto-start
```

Data available at `/workspace/data/igv-test-data/` inside container.

## 5. IGV Auto-Discovery

IGV Studio automatically:
1. Waits for Fusion to populate `/workspace/data/`
2. Scans for genomic files (BAM, VCF, BED, FASTA, BigWig, etc.)
3. Generates IGV configuration with discovered tracks
4. Displays tracks organized by data link name
