#!/usr/bin/env bash
#
# tasmota/build.sh — ZB-GW03 parity build script (PROTOTYPE)
#
# Runs the exact same recipe from a GitHub Actions workflow or a local agent
# session: no Docker, native Linux. Local == CI by construction: both call
# this script, which is the single source of build steps.
#
# Recipe provenance: xsp1989/ZB-GW03_firmware tasmota/README.md (v14.5.0 era),
# run against the current stable Upstream release with the toolchain Upstream's
# own release CI pins: Python 3.13 + pioarduino==6.2.0 (PlatformIO Core fork),
# installed via uv.
#
# Usage:
#   tasmota/build.sh                       # latest stable Upstream release
#   UPSTREAM_TAG=v16.0.0 tasmota/build.sh  # a specific tag
#
# Outputs: ./build/*.bin + sha256
#
# Generated paths (gitignored): .upstream/Tasmota-<tag>/ (checkout), .venv/ (toolchain)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/arendst/Tasmota.git}"
ENV_NAME="${ENV_NAME:-tasmota32-ZB-GW03-EN}"
VENV="${VENV:-$REPO_ROOT/.venv}"
OUT="${OUT:-$REPO_ROOT/build}"

# --- resolve the latest stable Upstream release ("last" vX.Y.Z tag) -------------
if [ -z "${UPSTREAM_TAG:-}" ]; then
  UPSTREAM_TAG="$(git ls-remote --tags --refs "$UPSTREAM_URL" \
    | sed -En 's|.*/refs/tags/(v[0-9]+\.[0-9]+\.[0-9]+)$|\1|p' \
    | sort -V | tail -n1)"
fi
echo "==> Upstream release: $UPSTREAM_TAG"

# --- toolchain ------------------------------------------------------------------
if ! command -v uv >/dev/null 2>&1; then
  echo "==> Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
if [ ! -x "$VENV/bin/platformio" ]; then
  echo "==> Creating toolchain venv: Python 3.13 + pioarduino==6.2.0 (Upstream CI pins)"
  uv venv --python 3.13 "$VENV"
  uv pip install --python "$VENV/bin/python" pioarduino==6.2.0
fi
PIO="$VENV/bin/platformio"

# --- checkout the official tag ---------------------------------------------------
SRC="$REPO_ROOT/.upstream/Tasmota-$UPSTREAM_TAG"
if [ ! -d "$SRC" ]; then
  echo "==> Shallow-cloning Upstream at $UPSTREAM_TAG"
  git -c advice.detachedHead=false clone --depth 1 --branch "$UPSTREAM_TAG" \
    "$UPSTREAM_URL" "$SRC"
fi

# --- Override files (maintained here, copied into Upstream's tree) ----------------
echo "==> Copying Override files"
cp -v "$REPO_ROOT/tasmota/user_config_override.h" "$SRC/tasmota/user_config_override.h"
cp -v "$REPO_ROOT/tasmota/platformio_override.ini" "$SRC/platformio_override.ini"

# --- release footer ---------------------------------------------------------------
# Stamp the tag commit sha into tasmota_version.h (Upstream CI fills it via sed),
# then apply Upstream CI's sed verbatim so the footer reads "<tag> release-<sha>".
UPSTREAM_SHA="$(git -C "$SRC" rev-parse --short=7 HEAD)"
VERSION_H="$SRC/tasmota/include/tasmota_version.h"
sed -i "s/TASMOTA_SHA_SHORT \"\"/TASMOTA_SHA_SHORT \"${UPSTREAM_SHA}\"/" "$VERSION_H"
sed -i -e "s/TASMOTA_SHA_SHORT/TASMOTA_SHA_SHORT release-/g" "$VERSION_H"
grep -n TASMOTA_SHA_SHORT "$VERSION_H" || true

# --- build ------------------------------------------------------------------------
echo "==> platformio run -e $ENV_NAME (in $SRC)"
(cd "$SRC" && PYTHONIOENCODING=utf-8 PYTHONUTF8=1 "$PIO" run -e "$ENV_NAME")

# --- collect artifacts --------------------------------------------------------------
mkdir -p "$OUT"
cp -v "$SRC/build_output/firmware/"*.bin "$OUT/"
echo "==> Artifacts:"
ls -la "$OUT/"
sha256sum "$OUT/"*.bin
