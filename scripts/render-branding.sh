#!/usr/bin/env bash
# Render Aris branding SVG sources into the raster assets shipped by the
# packages and the ISO. Outputs are committed so a normal build does not need
# librsvg/imagemagick; rerun this after editing anything in branding/.
set -Eeuo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
brand="$root/branding"
desktop="$root/packages/aris-desktop/rootfs/usr/share"

command -v rsvg-convert >/dev/null || { echo "rsvg-convert (librsvg) is required" >&2; exit 1; }

install -d "$desktop/aris/wallpapers" "$desktop/icons/hicolor/scalable/apps" "$desktop/pixmaps"

# Logo: scalable icon (named "aris", referenced by os-release LOGO=) + PNG fallback.
install -m644 "$brand/aris-logo.svg" "$desktop/icons/hicolor/scalable/apps/aris.svg"
install -m644 "$brand/aris-logo.svg" "$desktop/pixmaps/aris.svg"
rsvg-convert -w 256 -h 256 "$brand/aris-logo.svg" -o "$desktop/pixmaps/aris.png"

# Default wallpaper. 4K source keeps it sharp on HiDPI; the shell scales down.
rsvg-convert -w 3840 -h 2160 "$brand/wallpaper.svg" -o "$desktop/aris/wallpapers/aris-default.png"

# Syslinux needs a 640x480 PNG for its vesamenu background.
rsvg-convert -w 640 -h 480 "$brand/splash.svg" -o "$root/iso/syslinux/splash.png"

echo "Branding rendered."
