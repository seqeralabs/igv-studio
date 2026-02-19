#!/usr/bin/env bash
# Upload test data to a Seqera data link
set -euo pipefail

WORKSPACE="${WORKSPACE:-scidev/testing}"
BUCKET="${BUCKET:-s3://scidev-playground-eu-west-2}"
CREDENTIALS="${CREDENTIALS:-aws-scidev-playground}"
DATA_LINK_NAME="${DATA_LINK_NAME:-igv-test-data}"
LOCAL_DIR="${1:-test-data}"

if [[ -z "${TOWER_ACCESS_TOKEN:-}" ]]; then
    echo "Error: TOWER_ACCESS_TOKEN not set"
    exit 1
fi

if [[ ! -d "$LOCAL_DIR" ]]; then
    echo "Error: Directory $LOCAL_DIR not found"
    exit 1
fi

echo "Uploading files from $LOCAL_DIR to $DATA_LINK_NAME..."

for file in "$LOCAL_DIR"/*; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        echo "  Uploading: $filename"
        tw data-links upload -w "$WORKSPACE" \
            --uri "$BUCKET" \
            -c "$CREDENTIALS" \
            "$file" \
            --path "$DATA_LINK_NAME/$filename"
    fi
done

echo "Done! Verify with:"
echo "  tw data-links browse -w $WORKSPACE --name \"$DATA_LINK_NAME\""
