#!/usr/bin/env bash
# Setup TOWER_ACCESS_TOKEN from 1Password
set -euo pipefail

if ! command -v op &> /dev/null; then
    echo "Error: 1Password CLI (op) not found"
    echo "Install: https://developer.1password.com/docs/cli/get-started/"
    exit 1
fi

# Check if signed in
if ! op account list &> /dev/null; then
    echo "Signing in to 1Password..."
    eval $(op signin)
fi

export TOWER_ACCESS_TOKEN=$(op read "op://Employee/Seqera Platform Prod/password")

if [[ -n "$TOWER_ACCESS_TOKEN" ]]; then
    echo "TOWER_ACCESS_TOKEN set successfully (${#TOWER_ACCESS_TOKEN} chars)"
    echo "Token preview: ${TOWER_ACCESS_TOKEN:0:10}..."
else
    echo "Error: Failed to retrieve token"
    exit 1
fi
