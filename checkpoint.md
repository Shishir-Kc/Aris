# Aris OS — Build Checkpoints

## Task 1: Bootstrap profile from releng
**Status**: ✅ COMPLETED  
**Details**: Copied `/usr/share/archiso/configs/releng/` → `~/Aris/myiso/`  
**Files**: Full profile tree with airootfs/, efiboot/, syslinux/, grub/, packages.x86_64, pacman.conf, profiledef.sh, bootstrap_packages

---

## Task 2: Create profiledef.sh
**Status**: ✅ COMPLETED  
**Details**: Aris OS branded profile configuration  
**Key values**:
- `iso_name`: arisos
- `iso_label`: ARIS_$(date +%Y%m)
- `iso_publisher`: Kartabya <https://github.com/Krypton-learn>
- `install_dir`: arisos
- `bootmodes`: bios.syslinux.mbr, bios.syslinux.eltorito, uefi-x64.systemd-boot.esp, uefi-x64.systemd-boot.eltorito
- `airootfs_image_tool_options`: zstd compression level 19
- `file_permissions`: includes /etc/shadow, /etc/gshadow, /root, /root/.ssh, /home/liveuser

---

## Task 3: Create packages.x86_64
**Status**: ✅ COMPLETED  
**Details**: releng base packages + Aris OS additions  
**Added packages**:
- i3-wm, i3status, i3lock, dmenu
- lightdm, lightdm-gtk-greeter
- calamares

**Preserved**: All releng packages including kernel, firmware, filesystem tools, network utilities, bootloaders

---

## Task 4: Create airootfs overlay
**Status**: ✅ COMPLETED  
**Details**:
- **passwd**: root + liveuser (uid 1000)
- **shadow**: root (no password) + liveuser (password: aris, SHA-512 hash)
- **group**: root, adm, wheel, uucp, liveuser groups  
- **gshadow**: corresponding entries
- **hostname**: arisos
- **motd**: Aris OS welcome message with usage instructions
- **LightDM autologin**: `/etc/lightdm/lightdm.conf` with `autologin-user=liveuser`
- **display-manager.service**: symlink → `/usr/lib/systemd/system/lightdm.service`
- **getty autologin**: `/etc/systemd/system/getty@tty1.service.d/autologin.conf` set to `liveuser`
- **i3 config**: Default i3 config in `/etc/skel/.config/i3/config`

---

## Task 5: Create bootloader configs
**Status**: ✅ COMPLETED  
**Details**:
- **efiboot/**: systemd-boot entries updated with Aris OS branding, `cow_spacesize=2G` boot parameter
- **syslinux/**: All .cfg files updated with Aris OS menu titles, `cow_spacesize=2G` boot parameter
- **grub/**: grub.cfg and loopback.cfg updated with Aris OS menu entries, `cow_spacesize=2G`

---

## Task 6: Create Calamares installer config
**Status**: ✅ COMPLETED  
**Details**: Full Calamares configuration at `/etc/calamares/`
- **settings.conf**: Module sequence (show: welcome → locale → keyboard → partition → users → summary; exec: partition → mount → unpackfs → networkcfg → users → fstab → bootloader → packages → finished)
- **Module configs**: welcome.conf, locale.conf, keyboard.conf, partition.conf, users.conf, summary.conf, unpackfs.conf, packages.conf, grubcfg.conf, bootloader.conf, mount.conf, finished.conf, users-shell.conf

---

## Task 7: Verify profile structure
**Status**: ✅ COMPLETED  
**Details**: 
- 101 files, 44 directories
- All required directories present: airootfs/, efiboot/, syslinux/, grub/
- Packages verified: `pptpdclient` corrected to `pptpclient`
- All bootmodes validated against mkarchiso v88

---

## Next Steps (to be done by operator)
1. **Build ISO**: `sudo mkarchiso -v -w /tmp/archiso-tmp -o ~/Aris/out ~/Aris/myiso`
2. **Test in QEMU (BIOS)**: `run_archiso -i ~/Aris/out/arisos-*.iso -vga virtio`
3. **Test in QEMU (UEFI)**: `run_archiso -u -i ~/Aris/out/arisos-*.iso -vga virtio`
4. **Verify LightDM autologin** works in live session
5. **Launch Calamares** from live session to test installer
