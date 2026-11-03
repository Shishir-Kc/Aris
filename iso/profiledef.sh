#!/usr/bin/env bash
# Aris live/install medium — archiso profile (derived from archiso 91 releng).
# Keys: /usr/share/doc/archiso/README.profile.rst
# shellcheck disable=SC2034

iso_name="aris"
iso_label="ARIS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Aris <https://github.com/Shishir-Kc/Aris>"
iso_application="Aris Live/Install Medium"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="aris"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/sudoers.d/10-aris-live"]="0:0:440"
  ["/root"]="0:0:750"
  ["/usr/local/bin/aris-live-setup"]="0:0:755"
)
