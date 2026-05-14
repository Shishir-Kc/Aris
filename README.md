# ARIS Linux

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)

A custom, minimal Arch Linux-based live distribution featuring the **i3-gaps** tiling window manager with a polished dark theme and curated set of tools out of the box.

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Packages](#packages)
- [Configuration](#configuration)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Customization](#customization)
- [Building from Source](#building-from-source)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Minimal & Lightweight** — Arch Linux base with no bloat; boots fast and uses minimal RAM
- **i3-gaps Tiling WM** — Gaps between windows, smart gaps, and pixel borders for a clean look
- **ARIS Dark Theme** — Deep blue-purple accent (`#7b2cbf`) on a `#1a1a2e` base throughout i3, picom, rofi, and more
- **Compositor** — Picom with dual Kawase blur, transparency, and fading
- **Application Launcher** — Rofi with a custom ARIS theme
- **Modern CLI Tools** — `eza`, `bat`, `lf`, `fzf`, `tldr` replace older utilities
- **Media & Hardware Keys** — Playerctl, pulsemixer, and brightnessctl with i3 keybindings
- **Multi-boot** — UEFI + BIOS (syslinux) support
- **Rolling Release** — Tracks Arch Linux rolling updates

---

## Screenshots

<!-- Add screenshots here if available -->

---

## Requirements

| Requirement | Details |
|---|---|
| **Host OS** | Arch Linux (or any system with `archiso` available) |
| **archiso** | `sudo pacman -S archiso` |
| **Disk Space** | ~20 GB free for build artifacts |
| **Root Access** | Required for `mkarchiso` |
| **Architecture** | x86_64 only |

---

## Quick Start

```bash
# 1. Install archiso
sudo pacman -S archiso

# 2. Clone the repo
git clone https://github.com/arislinux/aris.git
cd aris

# 3. Build the ISO (requires root)
sudo ./build.sh

# 4. Find your ISO
ls out/
# → aris-1.0.0-x86_64.iso
```

Write the ISO to a USB drive and boot:

```bash
# Write to USB (replace /dev/sdX with your device)
sudo dd if=out/aris-1.0.0-x86_64.iso of=/dev/sdX bs=4M status=progress
```

---

## Project Structure

```
Aris/
├── README.md              # This file
├── SPEC.md                # Detailed project specification
├── build.sh               # ISO build script (wraps mkarchiso)
├── .gitignore             # Ignores build output & temp files
└── work/                  # Archiso profile directory
    ├── profiledef.sh      # Profile variables (name, version, boot modes)
    ├── packages.x86_64    # Package list for the live system
    ├── pacman.conf        # Pacman mirror configuration
    ├── profiledef/        # Archiso profile definition
    │   └── (auto-generated links)
    ├── airootfs/          # Root filesystem overlay applied to the live image
    │   ├── etc/
    │   │   ├── hostname                    # System hostname
    │   │   ├── locale.conf                 # Locale settings (en_US.UTF-8)
    │   │   ├── vconsole.conf               # Console font & keymap
    │   │   ├── os-release                  # OS branding info
    │   │   ├── mkinitcpio.conf             # Initramfs hooks
    │   │   ├── modprobe.d/modprobe.conf    # Kernel module options
    │   │   ├── pacman.d/mirrorlist         # Build-time mirrorlist
    │   │   ├── X11/                         # X11 configuration
    │   │   └── skel/                       # Default user skeleton files
    │   │       ├── .xinitrc                # X session startup (picom → i3)
    │   │       └── .config/
    │   │           ├── i3/config            # i3 window manager config
    │   │           ├── picom/picom.conf     # Compositor settings
    │   │           └── rofi/config.rasi     # Application launcher theme
    ├── boot/               # Boot-related overlays
    ├── efiboot/            # EFI boot files
    └── syslinux/           # BIOS boot (syslinux) files
├── out/                   # Build output directory (gitignored)
│   └── aris-{version}-x86_64.iso
├── Creating               # Build log placeholder
├── Installing             # Install log placeholder
└── ERROR:                 # Error log placeholder
```

---

## Packages

### Core System
- `base`, `base-devel`, `linux`, `linux-firmware`, `linux-headers`
- `systemd`, `dbus`, `sudo`, `polkit`, `elogind`
- `networkmanager`, `netctl`, `wpa_supplicant`, `wireless_tools`, `dhclient`

### Window Manager & Desktop
- **i3-gaps** — Tiling window manager with gaps
- **i3status** — Status bar for i3
- **i3lock** — Screen locker
- **picom** — Compositor (blur, transparency, shadows, fading)
- **rofi** — Application launcher (custom ARIS theme)
- **feh** — Wallpaper setter
- **alacritty** — GPU-accelerated terminal

### Utilities
- `vim`, `nano`, `dash` — Editors & shell
- `eza`, `bat`, `lf` — Modern `ls`, `cat`, and file manager
- `fzf` — Fuzzy finder
- `tldr` — Simplified man pages
- `maim` — Screenshot tool
- `playerctl` — Media player controls
- `pulsemixer` — Audio mixer
- `brightnessctl` — Screen brightness control
- `ffmpeg`, `mpv` — Multimedia playback

### Fonts
- `ttf-jetbrains-mono`, `ttf-font-awesome`, `noto-fonts`, `terminus-font`

### Build Tools & ISO
- `xorg`, `xorg-xinit`, `xorg-server`, `mesa`, `libglvnd`
- `syslinux`, `mkinitcpio`, `squashfs-tools`
- `memtest86+`, `edk2-shell`, `gptfdisk`

---

## Configuration

### Shell
- Default shell: **zsh**

### Colors (ARIS Theme)
| Name    | Hex       | Usage                    |
|---------|-----------|--------------------------|
| Base    | `#1a1a2e` | Background (i3, rofi)    |
| Foreground | `#cdd6f4` | Text color            |
| Accent  | `#7b2cbf` | Highlights, focus borders |
| Urgent  | `#f38ba8` | Urgent window indicator  |
| Container | `#313244` | Unfocused window border |

### i3 Window Manager
Config: `~/.config/i3/config` (deployed via `airootfs/etc/skel/`)

- **Mod key**: `Super (Mod4)`
- **Terminal**: Alacritty
- **Launcher**: Rofi (`Mod+d`)
- **Gaps**: Inner 10px, Outer 5px, smart gaps enabled
- **Borders**: 2px pixel borders
- **Workspaces**: `Mod+1` through `Mod+5`

### Picom Compositor
Config: `~/.config/picom/picom.conf`

- Backend: GLX
- Dual Kawase blur (7x7box)
- Active opacity: 1.0 / Inactive opacity: 0.9
- Shadows enabled with offset
- Fading transitions on open/close

### Rofi Launcher
Config: `~/.config/rofi/config.rasi`

- Matches the ARIS dark theme
- JetBrains Mono 12pt font
- Accent-colored selection highlight

---

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Super + Return` | Open terminal (Alacritty) |
| `Super + d` | Open app launcher (Rofi) |
| `Super + Shift + q` | Kill focused window |
| `Super + j/k/l/;` | Focus left/down/up/right |
| `Super + Shift + j/k/l/;` | Move window left/down/up/right |
| `Super + 1-5` | Switch to workspace 1-5 |
| `Print` | Full screenshot (clipboard) |
| `Super + Print` | Area screenshot (clipboard) |
| `XF86AudioPlay/Pause/Next/Prev` | Media playback control |
| `XF86AudioRaiseVolume/LowerVolume/Mute` | Volume control |
| `XF86MonBrightnessUp/Down` | Screen brightness |
| `Super + Shift + e` | Suspend system |

---

## Building from Source

### Prerequisites

```bash
# On an Arch Linux host:
sudo pacman -S archiso git
```

### Build Steps

```bash
# Clone the repository
git clone https://github.com/arislinux/aris.git
cd aris

# Run the build script (requires root)
sudo ./build.sh

# The ISO will appear in out/
ls out/
# aris-1.0.0-x86_64.iso
```

### What `build.sh` Does

1. Verifies root access and `archiso` installation
2. Cleans previous build artifacts (`work/` and `out/`)
3. Makes `customize_airootfs.sh` executable
4. Runs `mkarchiso` with the `work/` profile
5. Reports the output ISO path and size

### Customizing the Build

- **Version**: Edit `VERSION` in `build.sh`
- **Packages**: Edit `work/packages.x86_64`
- **Mirror**: Edit `work/airootfs/etc/pacman.d/mirrorlist`
- **i3 Config**: Edit `work/airootfs/etc/skel/.config/i3/config`
- **Colors**: Update the color variables in both `i3/config` and `config.rasi`

---

## Live Session

When you boot the ISO:

1. Select **ARIS Live** from the boot menu (UEFI or BIOS)
2. Log in as `root` (no password on live session)
3. The i3 desktop starts automatically
4. Use **Super+d** to launch applications
5. Use the shortcuts in the table above to navigate

To start the live session with a specific language or keymap, edit the boot parameters in the GRUB/syslinux menu.

---

## Installing to Disk

The ISO currently provides a live session. To install to disk:

### Option A: Manual (archinstall)

```bash
# From the live session:
archinstall
# Follow the interactive prompts
```

### Option B: Calamares (planned)

Calamares installer support is planned for a future release. See [SPEC.md](SPEC.md) for details.

---

## Troubleshooting

### Build fails with "archiso not found"
```bash
sudo pacman -S archiso
```

### ISO boots to black screen
- Try selecting a different boot mode in the GRUB menu
- Verify your USB was written correctly: `sudo dd if=out/aris-*.iso of=/dev/sdX bs=4M status=progress`

### i3 session doesn't start
- Log in as `root` and run `startx` manually
- Check `~/.xinitrc` and `~/.config/i3/config` for syntax errors

### No network in live session
```bash
# Start NetworkManager manually
sudo systemctl start NetworkManager
nmtui  # or use nm-applet in the i3 bar
```

### Low resolution
The default console font is Terminus at 16px. To change:
```bash
# Edit vconsole.conf in airootfs:
FONT=ter-v32n  # Larger font
```

---

## Contributing

Contributions are welcome! Here's how to help:

1. **Fork** the repository
2. **Create a branch** for your feature or fix
3. **Commit** with clear, descriptive messages
4. **Push** and open a Pull Request

Areas for contribution:
- Additional packages and utilities
- New i3 keybindings or configurations
- Calamares installer integration
- Custom kernel compilation
- AUR helper setup (yay/paru)
- Documentation improvements

---

## Roadmap

| Version | Features |
|---|---|
| **v1.0** ✅ | Minimal i3-gaps setup, ARIS theme, core utilities |
| **v2.0** | Calamares installer, AUR helper, dotfiles repo integration |
| **v3.0** | Custom kernel, ARIS-specific utilities, improved theming |

---

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

---

## Links

- **GitHub**: [github.com/arislinux/aris](https://github.com/arislinux/aris)
- **Documentation**: [github.com/arislinux/docs](https://github.com/arislinux/docs)
- **Issues**: [github.com/arislinux/issues](https://github.com/arislinux/issues)