# ARIS Linux

Custom Arch Linux-based distribution with i3 window manager.

## Quick Start

```bash
# Install archiso (required)
sudo pacman -S archiso

# Build the ISO
sudo ./build.sh
```

## Project Structure

```
Aris/
├── SPEC.md              # Project specification
├── build.sh             # ISO build script
└── work/
    ├── profiledef/      # Archiso profile
    │   ├── packages.x86_64
    │   └── pacman.conf
    └── airootfs/        # Live system overlay
        └── etc/         # System configs & user dotfiles
```

## Requirements

- Arch Linux system
- archiso package
- Root access (for mkarchiso)
- ~20GB free disk space

## Output

ISO will be created at `out/aris-{version}-x86_64.iso`