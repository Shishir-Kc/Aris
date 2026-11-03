#!/usr/bin/env bash
# Build the Aris ISO with mkarchiso. Needs root.
#
#   sudo scripts/build-iso.sh          (or: make iso — builds packages first)
#
# Environment:
#   ARIS_HOST_MIRRORS=1   build from the host's /etc/pacman.d/mirrorlist
#                         instead of iso/airootfs/etc/pacman.d/mirrorlist
set -Eeuo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
repo="$root/out/repo"
stage="$root/build/profile"
work="$root/build/work"
out="$root/out"

die() {
  echo "build-iso.sh: $*" >&2
  exit 1
}

((EUID == 0)) || die "mkarchiso needs root: sudo $0"
command -v mkarchiso >/dev/null || die "mkarchiso not found: pacman -S archiso"
[[ -f $repo/aris.db ]] || die "no Aris package repo; run scripts/build-packages.sh first (as your user)"

# Never rm -rf a work dir that still has bind mounts from an interrupted build.
if findmnt -rno TARGET | grep -q "^$work/"; then
  die "$work still has mounts from an interrupted build; unmount them first (findmnt | grep $work)"
fi
rm -rf -- "$work" "$stage"

echo "==> Staging profile"
cp -a -- "$root/iso" "$stage"

# Ship the Aris repo on the medium so the installer can pacstrap the Aris
# packages straight from it.
install -d -- "$stage/airootfs/opt/aris/repo"
cp -a -- "$repo/." "$stage/airootfs/opt/aris/repo/"

mirrorlist="$stage/airootfs/etc/pacman.d/mirrorlist"
[[ ${ARIS_HOST_MIRRORS:-0} == 1 ]] && mirrorlist=/etc/pacman.d/mirrorlist
sed -i -e "s|@ARIS_REPO@|$repo|" -e "s|@MIRRORLIST@|$mirrorlist|" "$stage/pacman.conf"

echo "==> Running mkarchiso"
mkarchiso -v -r -w "$work" -o "$out" "$stage"

iso="$(ls -t -- "$out"/aris-*.iso | head -n1)"
(cd -- "$out" && sha256sum -- "$(basename -- "$iso")" >"$(basename -- "$iso").sha256")

# Hand the results back to whoever invoked sudo.
if [[ -n ${SUDO_UID:-} ]]; then
  chown "$SUDO_UID:$SUDO_GID" -- "$out" "$iso" "$iso.sha256"
  chown -R "$SUDO_UID:$SUDO_GID" -- "$root/build"
fi

echo "==> Built $iso"
