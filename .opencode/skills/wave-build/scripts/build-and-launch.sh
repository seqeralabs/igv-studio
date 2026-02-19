#!/usr/bin/env bash
# Build IGV Studio with Wave and optionally launch on Seqera Platform
set -euo pipefail

# Configuration
BUILD_REPO="${BUILD_REPO:-cr.seqera.io/seqera-services/igv-studio}"
WORKSPACE="${WORKSPACE:-scidev/testing}"
COMPUTE_ENV="${COMPUTE_ENV:-seqera_aws_london_fusion_nvme}"
STUDIO_NAME="${STUDIO_NAME:-IGV Studio}"
MOUNT_DATA="${MOUNT_DATA:-}"

# Check prerequisites
if [[ -z "${TOWER_ACCESS_TOKEN:-}" ]]; then
    echo "Error: TOWER_ACCESS_TOKEN not set"
    echo "Run: export TOWER_ACCESS_TOKEN=\$(op read \"op://Employee/Seqera Platform Prod/password\")"
    exit 1
fi

if ! command -v wave &> /dev/null; then
    echo "Error: wave CLI not found"
    exit 1
fi

# Parse arguments
LAUNCH=false
PERSISTENT=false
CONTEXT="."

while [[ $# -gt 0 ]]; do
    case $1 in
        --launch) LAUNCH=true; shift ;;
        --persistent) PERSISTENT=true; shift ;;
        --context) CONTEXT="$2"; shift 2 ;;
        --mount-data) MOUNT_DATA="$2"; shift 2 ;;
        --name) STUDIO_NAME="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "Building with Wave..."

WAVE_ARGS=(
    -f Dockerfile
    --context "$CONTEXT"
    --platform linux/amd64
    --await
    --tower-token "$TOWER_ACCESS_TOKEN"
)

if [[ "$PERSISTENT" == true ]]; then
    WAVE_ARGS+=(--build-repo "$BUILD_REPO" --freeze)
fi

IMAGE_URL=$(wave "${WAVE_ARGS[@]}")
echo "Built image: $IMAGE_URL"

if [[ "$LAUNCH" == true ]]; then
    if ! command -v tw &> /dev/null; then
        echo "Error: tw CLI not found (required for --launch)"
        exit 1
    fi

    echo "Launching studio..."
    TW_ARGS=(
        studios add
        --name "$STUDIO_NAME"
        --workspace "$WORKSPACE"
        --custom-template "$IMAGE_URL"
        --compute-env "$COMPUTE_ENV"
        --auto-start
    )

    if [[ -n "$MOUNT_DATA" ]]; then
        TW_ARGS+=(--mount-data "$MOUNT_DATA")
    fi

    tw "${TW_ARGS[@]}"
    echo "Studio launched!"
fi
