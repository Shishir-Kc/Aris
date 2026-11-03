#!/usr/bin/env bash
# Boot Aris in QEMU/KVM with a virtual disk to install to.
#
#   scripts/run-vm.sh [--bios] [--iso FILE] [--no-iso] [--fresh-disk] [--headless]
#
#   --bios        legacy BIOS (SeaBIOS) instead of UEFI (OVMF)
#   --iso FILE    ISO to boot (default: newest out/aris-*.iso)
#   --no-iso      boot only the virtual disk (an installed Aris)
#   --fresh-disk  recreate the 32 GiB virtual disk and UEFI variables
#   --headless    no window: VNC on 127.0.0.1:5905
#
# Needs: qemu-desktop (or qemu-full), edk2-ovmf, and a GPU with OpenGL on the
# host (Hyprland in the guest renders through virtio-gpu/virgl).
set -Eeuo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
vm="$root/build/vm"
disk="$vm/disk.qcow2"

firmware=uefi iso="" use_iso=1 fresh=0 headless=0
while (($#)); do
  case "$1" in
    --bios) firmware=bios ;;
    --iso) iso="$2" && shift ;;
    --no-iso) use_iso=0 ;;
    --fresh-disk) fresh=1 ;;
    --headless) headless=1 ;;
    -h | --help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//' && exit 0 ;;
    *) echo "unknown option: $1" >&2 && exit 2 ;;
  esac
  shift
done

command -v qemu-system-x86_64 >/dev/null || { echo "qemu-system-x86_64 not found: pacman -S qemu-desktop" >&2; exit 1; }
mkdir -p -- "$vm"

if ((use_iso)) && [[ -z $iso ]]; then
  iso="$(ls -t -- "$root"/out/aris-*.iso 2>/dev/null | head -n1 || true)"
  [[ -n $iso ]] || { echo "no ISO in out/; build one with 'make iso'" >&2; exit 1; }
fi

if ((fresh)) || [[ ! -f $disk ]]; then
  rm -f -- "$disk" "$vm"/OVMF_VARS.fd
  qemu-img create -q -f qcow2 "$disk" 32G
fi

args=(
  -name Aris -enable-kvm -machine q35 -cpu host -smp 4 -m 4G
  -drive "if=virtio,file=$disk,format=qcow2"
  -nic user,model=virtio-net-pci
  -usb -device usb-tablet
  -device virtio-vga-gl
)

if [[ $firmware == uefi ]]; then
  code="" vars=""
  for d in /usr/share/edk2/x64 /usr/share/edk2-ovmf/x64; do
    [[ -f $d/OVMF_CODE.4m.fd ]] && code="$d/OVMF_CODE.4m.fd" vars="$d/OVMF_VARS.4m.fd" && break
  done
  [[ -n $code ]] || { echo "OVMF not found: pacman -S edk2-ovmf" >&2; exit 1; }
  [[ -f $vm/OVMF_VARS.fd ]] || cp -- "$vars" "$vm/OVMF_VARS.fd"
  args+=(-drive "if=pflash,format=raw,readonly=on,file=$code"
    -drive "if=pflash,format=raw,file=$vm/OVMF_VARS.fd")
fi

# Boot the ISO once; reboots fall through to the installed disk.
((use_iso)) && args+=(-cdrom "$iso" -boot once=d)

if ((headless)); then
  args+=(-display egl-headless -vnc 127.0.0.1:5)
  echo "VNC: 127.0.0.1:5905"
else
  args+=(-display gtk,gl=on)
fi

exec qemu-system-x86_64 "${args[@]}"
