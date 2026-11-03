# Aris build entry points. `make help` lists them.

.PHONY: help packages iso run run-bios test test-bios test-luks check assets clean

help:
	@echo "make packages   build the Aris packages into out/repo (as your user)"
	@echo "make iso        packages + ISO in out/ (asks for sudo: mkarchiso needs root)"
	@echo "make run        boot the newest ISO in a QEMU window (UEFI)"
	@echo "make run-bios   same, legacy BIOS"
	@echo "make test       headless end-to-end test: live session + unattended install + login"
	@echo "make test-bios  the same on BIOS/GRUB with ext4"
	@echo "make test-luks  the same with LUKS2 encryption"
	@echo "make check      static checks (shell, Hyprland config, JSON, Python)"
	@echo "make assets     re-render PNGs from branding/*.svg"
	@echo "make clean      remove build/ and out/"

packages:
	./scripts/build-packages.sh

iso: packages
	sudo ./scripts/build-iso.sh

run:
	./scripts/run-vm.sh

run-bios:
	./scripts/run-vm.sh --bios

test:
	./scripts/vm-test.py

test-bios:
	./scripts/vm-test.py --bios --fs ext4

test-luks:
	./scripts/vm-test.py --encrypt

check:
	./scripts/check.sh

assets:
	./scripts/render-branding.sh

clean:
	rm -rf build out
