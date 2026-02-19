---
name: debug-igv-studio
description: Troubleshoot IGV Studio issues in Seqera Platform. Use when studios fail to start, show errors, data not discovered, or browser console shows 404s.
compatibility: Requires tw CLI, TOWER_ACCESS_TOKEN, browser DevTools access.
metadata:
  author: Seqera/edmundmiller
  version: "1.0"
---

# Debug IGV Studio

Troubleshoot IGV Studio issues in Seqera Platform.

## Quick Diagnosis Checklist

1. **Browser Console** - Check for 404s, JS errors (F12 → Console)
2. **Studio Status** - Is it running? `tw studios list -w scidev/testing`
3. **Container Logs** - Check Seqera Platform UI logs
4. **Data Discovery** - Did Fusion mount data in time?

## Common Issues

### 404 Not Found on JavaScript/CSS files

**Symptom**: Browser console errors like:
```
GET /node_modules/igv/dist/igv.esm.js 404
GET /resources/...js 404
```

**Cause**: Web app source code copied but never built.

**Fix**: Ensure Dockerfile uses multi-stage build. See [references/DOCKERFILE-FIX.md](references/DOCKERFILE-FIX.md).

### CORS Errors

**Symptom**: `Cross-Origin Request Blocked` when loading remote files.

**Cause**: Data server doesn't allow cross-origin requests.

**Fix**: Configure CORS on data server or use Fusion data links (nginx serves with CORS enabled).

### Files Not Auto-Discovered

Check inside container:
```bash
ls -la /workspace/data/           # Fusion mount
cat /tmp/discovered-tracks.json   # Discovery output
DEBUG=1 /usr/local/bin/discover-data-links.sh  # Re-run with debug
```

### Studio Stuck in "Starting"

Causes:
- Container crash (check logs)
- Loop device permission (must run as root)
- Image pull failure (check compute env credentials)

### could not open loop device: permission denied

Container not running as root. Remove any `USER` directive from Dockerfile.

## Debugging Workflow

```bash
# 1. Check existing studios
tw studios list -w scidev/testing

# 2. View studio details
tw studios view --name "IGV Studio" -w scidev/testing

# 3. Check logs in Seqera Platform UI

# 4. Stop broken studio
tw studios stop --session-id <SESSION_ID> -w scidev/testing

# 5. Fix and rebuild
IMAGE_URL=$(wave -f Dockerfile --context . --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN")

# 6. Launch new studio
tw studios add --name "IGV Studio" -w scidev/testing --custom-template "$IMAGE_URL" --compute-env "seqera_aws_london_fusion_nvme" --auto-start
```

See [references/DATA-DISCOVERY.md](references/DATA-DISCOVERY.md) for data discovery details.
See [references/DOCKERFILE-FIX.md](references/DOCKERFILE-FIX.md) for build fixes.
