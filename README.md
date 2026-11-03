# ✦ Aris

![status: under dev](https://img.shields.io/badge/status-under%20dev-orange)

Aris is an Arch Linux–based distribution built around the
[Hyprland](https://hypr.land) Wayland compositor. It boots into a live
Hyprland desktop and installs itself with a guided terminal installer. It
stays plain Arch underneath: official repositories, `pacman`, and rolling
releases.

## What you get

| Area | Choice |
| --- | --- |
| Compositor | Hyprland 0.56 with a Lua config; Aris defaults live in `/usr/share/aris/lua` |
| Session | greetd + tuigreet login; Waybar, mako, fuzzel, swaybg, hyprlock, hypridle |
| Apps | kitty, Thunar, Firefox, pavucontrol, nm-applet, blueman, btop |
| Look | Aris palette (iris `#9d8cff` → teal `#5ce1c6`), Inter + JetBrains Mono Nerd Font, adw-gtk3-dark, Papirus |
| System | PipeWire, NetworkManager, BlueZ, power-profiles-daemon, zram swap |
| Install | GPT, Btrfs (`@ @home @log @pkg @snapshots`, zstd) or ext4, optional LUKS2, systemd-boot (UEFI) or GRUB (BIOS) |

Keybindings: `SUPER + /` lists them all. The essentials are `SUPER + Return`
(terminal), `SUPER + Space` (apps), `SUPER + Q` (close), `SUPER + 1…0`
(workspaces) and `SUPER + Escape` (power menu).

## Repository layout

```
branding/            SVG sources for the logo, wallpaper and boot splash
packages/
  aris-desktop/      meta-package: Hyprland session, defaults, branding, helper scripts
    rootfs/          installed verbatim (rootfs/usr/bin/x -> /usr/bin/x)
  aris-installer/    aris-install (TUI installer) and aris-welcome (live welcome)
iso/                 archiso profile, derived from archiso 91 "releng"
scripts/             build, VM, test and check tooling
```

### How the pieces fit

- **The packages are the distro.** `aris-desktop` depends on the whole
  desktop stack and ships every Aris file. The ISO installs it, and the
  installer `pacstrap`s it onto the target, so an installed system is just
  Arch plus one package that pacman manages and can upgrade.
- **Defaults vs. your settings.** Package-owned defaults sit in
  `/usr/share/aris`. Each user gets thin files in `~/.config` that include
  those defaults (Hyprland `require`/`dofile`, Waybar `include`, kitty,
  fuzzel and mako `include`, hyprlock/hypridle `source`). Updates improve
  the defaults without touching your edits.
- **Identity.** A pacman hook re-applies the Aris `os-release` whenever the
  `filesystem` package is upgraded.
- **Keyboard.** The installer writes the standard
  `/etc/X11/xorg.conf.d/00-keyboard.conf`, and Hyprland reads it through the
  Aris input defaults.

## Building

Run this on Arch, or anything Arch-based:

```sh
sudo pacman -S --needed archiso qemu-desktop edk2-ovmf shellcheck
make iso        # builds packages as you, then runs mkarchiso via sudo
```

The ISO lands in `out/aris-YYYY.MM.DD-x86_64.iso` with a `.sha256` next to
it. `make packages` builds just the packages into `out/repo`.

By default the build downloads from the official Arch mirrors listed in
`iso/airootfs/etc/pacman.d/mirrorlist`, the same list the live system ships.
To use your host's mirrorlist instead, run
`sudo ARIS_HOST_MIRRORS=1 scripts/build-iso.sh`.

## Testing

```sh
make check      # shell syntax/shellcheck, Hyprland --verify-config, JSON, Python
make run        # boot the ISO in a QEMU window (UEFI); `make run-bios` for BIOS
make test       # headless end-to-end: live desktop → unattended install → login
make test-bios  # same on BIOS + GRUB + ext4
make test-luks  # same with LUKS2
```

`make test` writes screenshots and diagnostics to `build/vm-test/<variant>/`.
Hyprland in the VM renders through virtio-gpu with virgl, so the host needs
working OpenGL.

## Installing

Boot the ISO. The live session logs in as `aris` (no password) and opens the
welcome window. Choose **Install Aris** there, press `SUPER + I`, or run
`aris-install` in a terminal. If the desktop doesn't start on your GPU, pick
the *text mode / safe graphics* boot entry; `aris-install` works from the
console too.

For unattended installs, put the answers in a file:

```sh
cat > answers.conf <<'EOF'
ARIS_DISK=/dev/nvme0n1
ARIS_FS=btrfs              # btrfs | ext4
ARIS_ENCRYPT=no            # yes needs ARIS_LUKS_PASSWORD
ARIS_FULLNAME='Ada Lovelace'
ARIS_USER=ada
ARIS_PASSWORD='change-me'
ARIS_HOSTNAME=aris
ARIS_TIMEZONE=Asia/Kathmandu
ARIS_LOCALE=en_US.UTF-8
ARIS_XKB_LAYOUT=us
EOF
sudo aris-install --config answers.conf --yes
```

## Status and next steps

v0.1. Things deliberately left for later:

- **Package repository hosting.** The Aris packages ship on the ISO, but
  installed systems have no `[aris]` repo yet, so Aris defaults don't update
  after install. A signed repo (e.g. on GitHub Pages) is the next
  infrastructure step.
- **Secure Boot**, **Plymouth** boot splash, a **graphical installer**
  (Calamares would have to be built from the AUR into the local repo), and
  **Btrfs snapshots** (snapper + boot entries; the `@snapshots` subvolume is
  already in place).
- **License.** The PKGBUILDs say `LicenseRef-unspecified` until a license is
  chosen.
