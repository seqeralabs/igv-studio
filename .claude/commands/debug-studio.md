# Debug IGV Studio

Troubleshoot IGV Studio issues in Seqera Platform.

## Quick Diagnosis Checklist

1. **Browser Console** - Check for 404s, JS errors
2. **Studio Status** - Is it running? Check `tw studios list`
3. **Container Logs** - Check Seqera Platform UI logs
4. **Data Discovery** - Did Fusion mount data in time?

## Browser Console Errors

Open browser DevTools (F12) → Console tab.

### 404 Not Found on JavaScript/CSS files

**Symptom**: Errors like:
```
GET /node_modules/igv/dist/igv.esm.js 404
GET /resources/...js 404
```

**Cause**: Web app source code was copied but never built.

**Fix**: Ensure Dockerfile uses multi-stage build:
```dockerfile
# Stage 1: Build with Node.js
FROM node:18-slim AS igv-builder
WORKDIR /build
RUN apt-get update && apt-get install -y curl unzip git \
    && curl -L -o igv-webapp.zip https://github.com/igvteam/igv-webapp/archive/refs/heads/master.zip \
    && unzip igv-webapp.zip \
    && cd igv-webapp-master \
    && npm install \
    && npm run build

# Stage 3: Runtime (copy only dist/)
COPY --from=igv-builder /build/igv-webapp-master/dist/ /opt/igv-webapp/
```

### CORS Errors

**Symptom**: `Cross-Origin Request Blocked` when loading remote files.

**Cause**: Data server doesn't allow cross-origin requests.

**Fix**: Configure CORS on the data server or use Fusion data links (which serve via nginx with CORS enabled).

## Data Discovery Issues

### Files Not Auto-Discovered

**Check Fusion mount**:
```bash
# Inside container
ls -la /workspace/data/
```

**Check discovery ran**:
```bash
cat /tmp/discovered-tracks.json | jq .
```

**Check timing**: Fusion creates mount directories immediately but populates files asynchronously. The startup script should wait:

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

### Wrong IGV Config Generated

**Check generated config**:
```bash
cat /opt/igv-webapp/js/igvwebConfig.js
```

**Debug discovery**:
```bash
DEBUG=1 /usr/local/bin/discover-data-links.sh
```

## Container Issues

### Studio Stuck in "Starting"

**Causes**:
- Container crash (check logs)
- Loop device permission (must run as root)
- Image pull failure (check compute env credentials)

### `could not open loop device: permission denied`

**Cause**: Container not running as root.

**Fix**: Remove any `USER` directive from Dockerfile. Connect-client requires root for Fusion loop device setup.

### nginx Not Starting

**Check config syntax**:
```bash
nginx -t
```

**Check port substitution**:
```bash
cat /etc/nginx/sites-available/igv-app | grep listen
```

Port should show `CONNECT_TOOL_PORT` value, not `CONNECT_TOOL_PORT_PLACEHOLDER`.

## Build Issues

### Wave Build Fails with "npm error enoent git"

**Cause**: npm install requires git for some dependencies.

**Fix**: Add git to builder stage:
```dockerfile
RUN apt-get update && apt-get install -y curl unzip git
```

### Multi-Stage Build Tips

1. **Keep builder stage minimal** - Only install build dependencies
2. **Copy only artifacts** - `dist/` folder, not source code
3. **No Node.js in runtime** - Static files don't need runtime

## Debugging Workflow

```bash
# 1. Check existing studios
tw studios list -w scidev/testing

# 2. View studio details (note session ID)
tw studios view --name "IGV Studio" -w scidev/testing

# 3. Check logs in Seqera Platform UI

# 4. If broken, stop and rebuild
tw studios stop --session-id <SESSION_ID> -w scidev/testing

# 5. Fix Dockerfile, rebuild with Wave
IMAGE_URL=$(wave -f /tmp/igv-build/Dockerfile --context /tmp/igv-build --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN")

# 6. Launch new studio
tw studios add --name "IGV Studio" -w scidev/testing --custom-template "$IMAGE_URL" --compute-env "seqera_aws_london_fusion_nvme" --mount-data "igv-test-data" --auto-start
```
