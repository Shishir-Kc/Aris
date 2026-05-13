# ARIS Linux - Specification

## 1. Project Overview
- **Name**: ARIS Linux
- **Type**: Custom Arch Linux-based distribution (ISO)
- **Base**: Arch Linux
- **Window Manager**: i3-gaps
- **Goal**: Minimal, lightweight, customizable Linux distro with ARIS branding

## 2. Branding
- **OS Name**: ARIS
- **Bootloader**: ARIS (grub theme)
- **TTY**: Custom ARIS issue/login
- **Colors**: Deep blue/purple accent (#1a1a2e base, #7b2cbf accent)
- **Hostname**: aris-{machine}

## 3. ISO Specifications
- **Archiso Profile**: releng (standard)
- **Boot**: UEFI + BIOS (dual)
- **Installer**: calamares (optional) or manual archinstall
- **Live Session**: i3-gaps with basic apps

## 4. Packages (Base)
### Core
- base base-devel linux linux-firmware
- i3-gaps i3status dmenu
- vim nano git curl wget
- networkmanager connman
- sudo polkit
- alacritty (terminal)
- picom (compositor)
- rofi (launcher)
- feh (wallpaper)
- playerctl (media controls)
- pulsemixer (audio)
- brightnessctl
- maim (screenshots)

### Fonts
- ttf-jetbrains-mono ttf-font-awesome
- noto-fonts

### Utils
- eza bat lf (modern cli tools)
- fzf (fuzzy finder)
- tldr (man pages simplified)
- calcurse (calendar)
- cmus (music player)

## 5. Configuration
- **Shell**: zsh + oh-my-zsh (optional)
- **Editor**: vim config
- **i3**: Custom config with gaps, borders, colors
- **picom**: Dual kawase + blur
- **dmenu/rofi**: Custom ARIS theme
- **colors**: Tokyo Night or custom ARIS theme

## 6. Build Commands
```bash
# Clone this repo to /workspace/aris
# Run:
sudo mkarchiso -v work/
```

## 7. Output
- `out/aris-{version}-x86_64.iso`

## 8. Future Features (v2+)
- calamares installer
- AUR helper (yay/paru)
- dotfiles repo integration
- custom kernel
- ARIS specific utilities