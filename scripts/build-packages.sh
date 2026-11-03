#!/usr/bin/env bash
# Build the Aris packages (packages/*/PKGBUILD) into a local pacman repository
# at out/repo. Runs as a normal user — makepkg refuses to run as root.
set -Eeuo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
repo="$root/out/repo"
build="$root/build/makepkg"

if ((EUID == 0)); then
  echo "build-packages.sh: run as a normal user (makepkg refuses root)." >&2
  exit 1
fi

rm -rf -- "$repo" "$build"
mkdir -p -- "$repo" "$build"

for dir in "$root"/packages/*/; do
  name="$(basename -- "$dir")"
  echo "==> Building $name"
  # --nodeps: these are arch=any file packages; their runtime deps (Hyprland
  # etc.) are resolved on the target, not needed on the build host.
  BUILDDIR="$build" PKGDEST="$repo" SRCDEST="$build/src" PKGEXT=.pkg.tar.zst \
    makepkg --dir "$dir" --clean --cleanbuild --force --nodeps --noconfirm
done

echo "==> Indexing repository"
repo-add --quiet "$repo/aris.db.tar.zst" "$repo"/*.pkg.tar.zst
ls -1 "$repo"
