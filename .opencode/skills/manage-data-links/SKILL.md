---
name: manage-data-links
description: Browse, download, upload, and manage cloud storage data through Seqera Platform data links. Use when working with S3/GCS/Azure storage, mounting data to studios, or transferring genomic files.
compatibility: Requires tw CLI and TOWER_ACCESS_TOKEN.
metadata:
  author: Seqera/edmundmiller
  version: "1.0"
---

# Seqera Platform Data Links

Browse, download, upload, and manage cloud storage data through Seqera Platform.

## Prerequisites

```bash
export TOWER_ACCESS_TOKEN=$(op read "op://Employee/Seqera Platform Prod/password")
```

## Common Commands

### List Data Links

```bash
tw data-links list -w <workspace>
```

### Browse Contents

By name (if unique):
```bash
tw data-links browse -w <workspace> --name "<data-link-name>" -p "<path>"
```

By URI with credentials:
```bash
tw data-links browse -w <workspace> --uri "s3://<bucket>" -c "<credentials-name>" -p "<path>"
```

### Download Files

```bash
tw data-links download -w <workspace> \
  --uri "s3://<bucket>" \
  -c "<credentials-name>" \
  -o <output-dir> \
  "<path/to/file>"
```

### Upload Files

```bash
tw data-links upload -w <workspace> \
  --uri "s3://<bucket>" \
  -c "<credentials-name>" \
  "<local-path>" \
  --path "<remote-path>"
```

### Add Data Link

```bash
tw data-links add -w <workspace> \
  --name "<name>" \
  --provider <aws|google|azure> \
  --uri "s3://<bucket>" \
  --credentials "<credentials-name>"
```

### Delete Data Link

```bash
tw data-links delete -w <workspace> --id "<data-link-id>"
```

## Options Reference

| Option | Description |
|--------|-------------|
| `-w, --workspace` | Workspace (e.g., `scidev/testing`) |
| `-n, --name` | Data link name |
| `--uri` | Data link URI (e.g., `s3://bucket`) |
| `-c, --credentials` | Credentials identifier |
| `-p, --path` | Path within the data link |
| `-i, --id` | Data link ID |
| `-o, --output-dir` | Output directory for downloads |
| `-f, --filter` | Filter files by prefix |

## List Available Credentials

```bash
tw credentials list -w <workspace>
```

See [references/TROUBLESHOOTING.md](references/TROUBLESHOOTING.md) for common issues.
See [references/IGV-WORKFLOW.md](references/IGV-WORKFLOW.md) for complete IGV data setup.
