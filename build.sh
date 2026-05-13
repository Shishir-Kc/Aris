#!/bin/bash
# ARIS Linux ISO Build Script

set -e

VERSION="1.0.0"
PROFILE="work"
WORK_DIR="/tmp/aris-build"
OUTPUT_DIR="out"

echo "=== ARIS Linux Build Script v${VERSION} ==="

# Check for root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Check for archiso
if ! command -v mkarchiso &> /dev/null; then
    echo "Error: archiso is not installed"
    echo "Install with: pacman -S archiso"
    exit 1
fi

# Clean previous build
echo "Cleaning previous build..."
rm -rf "${WORK_DIR}" "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Make customize script executable
chmod +x "${PROFILE}/airootfs/root/customize_airootfs.sh"

# Build ISO
echo "Building ARIS ISO..."
mkarchiso -v -w "${WORK_DIR}" -o "${OUTPUT_DIR}" "${PROFILE}/"

echo "=== Build Complete ==="
ISO_FILE=$(ls ${OUTPUT_DIR}/aris-*.iso 2>/dev/null | head -1)
if [[ -n "$ISO_FILE" ]]; then
    echo "ISO created: ${ISO_FILE}"
    echo "Size: $(du -h ${ISO_FILE} | cut -f1)"
else
    echo "Error: ISO not found"
    exit 1
fi