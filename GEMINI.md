# Project Overview

This project builds a custom Arch Linux ISO named "Aris" using `archiso`. The ISO is configured with the following software:

*   **Desktop Environment:** KDE Plasma
*   **File Manager:** Dolphin
*   **Terminal:** Konsole
*   **Web Browser:** Brave
*   **Display Manager:** SDDM

# Building the ISO

To build the ISO, run the following command from the root of the project:

```bash
sudo mkarchiso -v -w /tmp/archiso-work -o . aris
```

This will create the ISO file in the current directory.

**Prerequisites:**

Before building the ISO, you need to have `archiso` installed. You also need to import the GPG key for the `chaotic-aur` repository, which is used to install the Brave browser.

```bash
sudo pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key FBA220DFC880C036
```

# Development Conventions

The ISO is customized by modifying the files in the `aris` directory. The main files for customization are:

*   `aris/packages.x86_64`: This file lists the packages to be installed on the ISO.
*   `aris/pacman.conf`: This file configures the pacman package manager, including the repositories to use.
*   `aris/airootfs/`: This directory contains the root filesystem of the live environment. Any files placed here will be included in the ISO.