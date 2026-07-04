#!/bin/bash
# Re-applies the max_tokens fix for OpenRouter auxiliary calls.
# This patch forces OpenRouter to respect the max_tokens parameter in
# auxiliary calls (title generation, compression, web extraction, etc.)
# instead of defaulting to the model's maximum (65536 tokens), which
# causes HTTP 402 billing errors.
#
# Run this script after any `hermes update` or `pip install --upgrade hermes-agent`.
# It is idempotent: if the patch is already present, it exits cleanly.

set -euo pipefail

# Locate the auxiliary_client.py file inside the hermes-agent venv
FILE=$(find /usr/local/lib/hermes-agent -path '*/agent/auxiliary_client.py' -not -path '*/__pycache__/*' 2>/dev/null | head -1)

if [ -z "$FILE" ]; then
  echo "ERROR: auxiliary_client.py not found under /usr/local/lib/hermes-agent"
  exit 1
fi

# Check if the patch is already applied
if grep -q 'or _provider_norm == "openrouter"' "$FILE"; then
  echo "OK: Patch already present in $FILE"
  exit 0
fi

# Check that the anchor line (the one we insert after) exists
if ! grep -q 'or _is_nvidia_nim' "$FILE"; then
  echo "ERROR: Anchor line 'or _is_nvidia_nim' not found in $FILE."
  echo "The upstream code may have changed. Re-evaluate the patch location before proceeding."
  exit 1
fi

# Apply the patch: insert two lines after 'or _is_nvidia_nim'
sed -i '/or _is_nvidia_nim/a\            or _provider_norm == "openrouter"' "$FILE"
sed -i '/or _provider_norm == "openrouter"/a\            or base_url_host_matches(_effective_base, "openrouter.ai")' "$FILE"

echo "OK: Patch applied to $FILE"
echo "    Added OpenRouter conditions to _build_call_kwargs max_tokens whitelist."
