#!/usr/bin/env bash
# ==============================================================================
# 05-install-tools.sh
# Downloads and installs the Spanner Omni local CLI tool based on OS/Arch.
# ==============================================================================

set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

VERSION=${SPANNER_OMNI_VERSION:-"2026.r1-beta.2"}
LOCAL_BIN_DIR="$(pwd)/bin"

# 1. Detect Operating System and CPU Architecture
log_info "Detecting system architecture..."

OS="linux"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="darwin"
fi

RAW_ARCH=$(uname -m)
ARCH="x86_64"
if [[ "$RAW_ARCH" == "arm64" ]] || [[ "$RAW_ARCH" == "aarch64" ]]; then
    ARCH="arm"
fi

log_info "Detected OS: $OS, Architecture: $ARCH"

# Create local bin directory
mkdir -p "$LOCAL_BIN_DIR"

# 2. Build download URL
# Example: https://storage.googleapis.com/spanner-omni/2026.r1-beta.2/spanner-omni-cli-2026.r1-beta.2-darwin-arm.tar.gz
TAR_NAME="spanner-omni-cli-${VERSION}-${OS}-${ARCH}.tar.gz"
DOWNLOAD_URL="https://storage.googleapis.com/spanner-omni/${VERSION}/${TAR_NAME}"

log_info "Downloading Spanner Omni CLI from: $DOWNLOAD_URL..."

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Download using curl
if ! curl -sSL -f -o "$TEMP_DIR/$TAR_NAME" "$DOWNLOAD_URL"; then
    log_error "Failed to download Spanner Omni CLI from $DOWNLOAD_URL."
    log_error "Please check your network connection or the version tag '$VERSION'."
    exit 1
fi

log_success "Download complete. Extracting tarball..."

# Extract the archive
tar -xzf "$TEMP_DIR/$TAR_NAME" -C "$TEMP_DIR"

# Identify the spanner binary
# The tarball structure extracts a folder named google/spanner/bin/spanner
EXTRACTED_BINARY="$TEMP_DIR/google/spanner/bin/spanner"

if [ -f "$EXTRACTED_BINARY" ]; then
    mv "$EXTRACTED_BINARY" "$LOCAL_BIN_DIR/spanner"
    chmod +x "$LOCAL_BIN_DIR/spanner"
    log_success "Successfully installed Spanner CLI to: $LOCAL_BIN_DIR/spanner"
else
    log_error "Could not find 'spanner' binary in the extracted archive at google/spanner/bin/spanner"
    exit 1
fi

# Verification
log_info "Verifying installed Spanner CLI version..."
"$LOCAL_BIN_DIR/spanner" --help &>/dev/null || true
log_success "Tool installation process finished. Run: ./bin/spanner --help"
