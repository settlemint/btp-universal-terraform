#!/usr/bin/env bash
set -euo pipefail

echo "[tflint] Initializing plugins (if any)..."
tflint --init

echo "[tflint] Running TFLint..."
tflint -f compact "$@"

echo "[tflint] Done."

