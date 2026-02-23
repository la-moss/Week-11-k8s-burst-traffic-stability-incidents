#!/usr/bin/env bash
set -euo pipefail

echo "[1/1] Runtime verification"
bash scripts/verify/runtime_checks.sh

echo "verification passed (${VERIFY_PROFILE:-profile1})"
