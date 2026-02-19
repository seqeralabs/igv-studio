# Dockerfile Build Fixes

## Multi-Stage Build (Required)

IGV webapp has no pre-built releases. Source requires Node.js to build, but output (`dist/`) is static files that nginx serves directly.

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

# Stage 2: Connect client (Seqera integration)
FROM ... AS connect-client
...

# Stage 3: Runtime (copy only dist/)
FROM ubuntu:20.04
COPY --from=igv-builder /build/igv-webapp-master/dist/ /opt/igv-webapp/
```

## Common Build Errors

### npm error enoent git

Add git to builder stage:

```dockerfile
RUN apt-get update && apt-get install -y curl unzip git
```

### Multi-Stage Tips

1. **Keep builder stage minimal** - Only install build dependencies
2. **Copy only artifacts** - `dist/` folder, not source code
3. **No Node.js in runtime** - Static files don't need runtime

## nginx Issues

### Config Syntax Error

```bash
nginx -t
```

### Port Not Substituted

Check port substitution:

```bash
cat /etc/nginx/sites-available/igv-app | grep listen
```

Should show `CONNECT_TOOL_PORT` value, not `CONNECT_TOOL_PORT_PLACEHOLDER`.
