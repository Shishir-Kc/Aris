#!/usr/bin/env python3
"""End-to-end test of an Aris ISO in headless QEMU/KVM.

Phase 1  Boot the ISO (direct kernel boot, so the serial console is live),
         check that the live Hyprland desktop came up, screenshot it, then run
         an unattended `aris-install` onto a blank virtual disk.
Phase 2  Boot the installed disk, screenshot the login screen, log in with the
         virtual keyboard, screenshot the desktop and check its services.

Guest commands run through the QEMU guest agent; screenshots and keystrokes go
through QMP. Results (PNGs, logs, diagnostics) land in build/vm-test/<name>/.

usage: scripts/vm-test.py [--bios] [--encrypt] [--fs btrfs|ext4] [--iso FILE]
"""

import argparse
import base64
import json
import os
import shutil
import socket
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
USER, PASSWORD, LUKS = "tester", "aris-test-1", "aris-luks-1"


def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def connect_unix(path, timeout=60):
    deadline = time.time() + timeout
    while True:
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(str(path))
            return s
        except OSError:
            if time.time() > deadline:
                raise
            time.sleep(0.5)


class JsonChannel:
    """Newline-delimited JSON over a UNIX socket (QMP and the guest agent)."""

    def __init__(self, path):
        self.sock = connect_unix(path)
        self.buf = b""

    def send(self, obj):
        self.sock.sendall(json.dumps(obj).encode() + b"\n")

    def recv(self, timeout):
        self.sock.settimeout(timeout)
        while b"\n" not in self.buf:
            chunk = self.sock.recv(65536)
            if not chunk:
                raise ConnectionError("channel closed")
            self.buf += chunk
        line, self.buf = self.buf.split(b"\n", 1)
        line = line.strip().lstrip(b"\xff")  # guest-sync-delimited sentinel
        return json.loads(line) if line else None


class Qmp(JsonChannel):
    def __init__(self, path):
        super().__init__(path)
        self.recv(30)  # greeting
        self.cmd("qmp_capabilities")

    def cmd(self, name, **arguments):
        self.send({"execute": name, "arguments": arguments})
        while True:
            msg = self.recv(60)
            if msg and "return" in msg:
                return msg["return"]
            if msg and "error" in msg:
                raise RuntimeError(f"QMP {name}: {msg['error']}")

    def screenshot(self, path):
        self.cmd("screendump", filename=str(path), format="png")
        log(f"screenshot -> {path.relative_to(ROOT)}")

    KEYS = {" ": "spc", "-": "minus", ".": "dot", "\n": "ret", "_": ("shift", "minus")}

    def type(self, text):
        for ch in text:
            if ch in self.KEYS:
                codes = self.KEYS[ch]
                codes = codes if isinstance(codes, tuple) else (codes,)
            elif ch.isupper():
                codes = ("shift", ch.lower())
            else:
                codes = (ch,)
            self.cmd("send-key", keys=[{"type": "qcode", "data": c} for c in codes])
            time.sleep(0.06)


class Agent(JsonChannel):
    """QEMU guest agent: run shell commands inside the guest."""

    def wait_ready(self, timeout):
        deadline = time.time() + timeout
        token = 4242
        while time.time() < deadline:
            token += 1
            try:
                self.send({"execute": "guest-sync", "arguments": {"id": token}})
                t_end = time.time() + 3
                while time.time() < t_end:
                    msg = self.recv(3)
                    if msg and msg.get("return") == token:
                        self._drain()
                        return
            except (socket.timeout, json.JSONDecodeError):
                pass
            time.sleep(2)
        raise TimeoutError("guest agent never answered")

    def _drain(self):
        """Discard late replies to earlier sync attempts."""
        try:
            while True:
                self.recv(1)
        except (socket.timeout, json.JSONDecodeError):
            pass

    def call(self, name, timeout=30, **arguments):
        self.send({"execute": name, "arguments": arguments})
        while True:
            msg = self.recv(timeout)
            if msg and "return" in msg:
                return msg["return"]
            if msg and "error" in msg:
                raise RuntimeError(f"QGA {name}: {msg['error']}")

    def sh(self, script, timeout=120):
        pid = self.call("guest-exec", path="/bin/sh", arg=["-c", script], **{"capture-output": True})["pid"]
        deadline = time.time() + timeout
        while time.time() < deadline:
            st = self.call("guest-exec-status", pid=pid)
            if st.get("exited"):
                out = base64.b64decode(st.get("out-data", "")).decode(errors="replace")
                err = base64.b64decode(st.get("err-data", "")).decode(errors="replace")
                return st.get("exitcode", -1), out + err
            time.sleep(0.5)
        raise TimeoutError(f"guest command timed out: {script[:60]}")


def wait_until(what, check, timeout, interval=3):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if check():
            return
        time.sleep(interval)
    raise TimeoutError(f"timed out waiting for: {what}")


def iso_label(iso):
    with open(iso, "rb") as f:
        f.seek(0x8000 + 40)
        return f.read(32).decode("ascii").strip()


def ovmf():
    for d in ("/usr/share/edk2/x64", "/usr/share/edk2-ovmf/x64"):
        if Path(d, "OVMF_CODE.4m.fd").exists():
            return Path(d, "OVMF_CODE.4m.fd"), Path(d, "OVMF_VARS.4m.fd")
    sys.exit("OVMF not found: pacman -S edk2-ovmf")


class Vm:
    def __init__(self, workdir, uefi, phase):
        self.dir, self.uefi, self.phase = workdir, uefi, phase
        self.qmp_path = workdir / f"qmp-{phase}.sock"
        self.qga_path = workdir / f"qga-{phase}.sock"
        self.serial_path = workdir / f"serial-{phase}.sock"
        self.serial_log = workdir / f"serial-{phase}.log"
        self.proc = None

    def start(self, extra):
        for p in (self.qmp_path, self.qga_path, self.serial_path):
            p.unlink(missing_ok=True)
        args = [
            "qemu-system-x86_64", "-name", f"aris-test-{self.phase}",
            "-enable-kvm", "-machine", "q35", "-cpu", "host", "-smp", "4", "-m", "4G",
            "-drive", f"if=virtio,file={self.dir / 'disk.qcow2'},format=qcow2",
            "-nic", "user,model=virtio-net-pci",
            "-usb", "-device", "usb-tablet",
            "-device", "virtio-vga-gl", "-display", "egl-headless",
            "-chardev", f"socket,id=ser0,path={self.serial_path},server=on,wait=off,logfile={self.serial_log}",
            "-serial", "chardev:ser0",
            "-qmp", f"unix:{self.qmp_path},server=on,wait=off",
            "-chardev", f"socket,path={self.qga_path},server=on,wait=off,id=qga0",
            "-device", "virtio-serial",
            "-device", "virtserialport,chardev=qga0,name=org.qemu.guest_agent.0",
        ]
        if self.uefi:
            code, _ = ovmf()
            args += ["-drive", f"if=pflash,format=raw,readonly=on,file={code}",
                     "-drive", f"if=pflash,format=raw,file={self.dir / 'OVMF_VARS.fd'}"]
        self.proc = subprocess.Popen(args + extra, stdout=open(self.dir / f"qemu-{self.phase}.log", "w"),
                                     stderr=subprocess.STDOUT)
        self.qmp = Qmp(self.qmp_path)
        self.agent = Agent(self.qga_path)

    def answer_serial_prompt(self, needle, answer, timeout):
        """Wait for `needle` on the serial console and type `answer`.

        Only connected for the duration: an attached but unread client would
        eventually block the guest's console writes. QEMU's logfile= keeps
        the full serial log either way."""
        serial = connect_unix(self.serial_path)
        serial.settimeout(1)
        seen, deadline = b"", time.time() + timeout
        try:
            while time.time() < deadline:
                try:
                    seen = (seen + serial.recv(4096))[-8192:]
                except socket.timeout:
                    pass
                if needle.encode() in seen:
                    time.sleep(1)
                    serial.sendall(answer.encode() + b"\r")
                    return
            raise TimeoutError(f"serial never showed {needle!r}")
        finally:
            serial.close()

    def stop(self, timeout=120):
        if self.proc and self.proc.poll() is None:
            try:
                self.agent.send({"execute": "guest-shutdown"})
            except (OSError, AttributeError):
                pass
            try:
                self.proc.wait(timeout)
            except subprocess.TimeoutExpired:
                self.proc.kill()


def as_user(uid, cmd):
    """Shell snippet running cmd as uid with that user's Hyprland session env."""
    return (f"rt=/run/user/{uid}; sig=$(ls $rt/hypr 2>/dev/null | head -n1); "
            f"setpriv --reuid={uid} --regid={uid} --init-groups "
            f"env XDG_RUNTIME_DIR=$rt HYPRLAND_INSTANCE_SIGNATURE=$sig sh -c '{cmd}'")


DIAG = [
    ("os-release", "cat /etc/os-release"),
    ("failed units", "systemctl --failed --no-legend --plain || true"),
    ("greetd", "systemctl is-active greetd"),
    ("NetworkManager", "systemctl is-active NetworkManager"),
    ("session processes", "pgrep -a -x 'Hyprland|waybar|mako|swaybg|hyprpolkitagent|nm-applet' || true"),
]


def diagnostics(vm, uid, path):
    lines = []
    checks = DIAG + [
        ("hyprland config errors", as_user(uid, "hyprctl configerrors")),
        ("hyprland layers", as_user(uid, "hyprctl layers -j | jq -r \"..|.namespace? // empty\" | sort -u")),
        ("hyprland clients", as_user(uid, "hyprctl clients -j | jq -r \".[] | .class + \\\" — \\\" + .title\"")),
        ("journal errors", "journalctl -b -p err --no-pager | tail -n 40"),
    ]
    for title, cmd in checks:
        rc, out = vm.agent.sh(cmd)
        lines.append(f"### {title} (rc={rc})\n{out.rstrip()}\n")
    path.write_text("\n".join(lines))
    log(f"diagnostics -> {path.relative_to(ROOT)}")
    return "\n".join(lines)


def phase_live(work, args):
    log("Phase 1: live medium")
    stage = work / "iso"
    stage.mkdir(exist_ok=True)
    subprocess.run(["bsdtar", "-xf", str(args.iso), "-C", str(stage),
                    "aris/boot/x86_64/vmlinuz-linux", "aris/boot/x86_64/initramfs-linux.img"], check=True)
    label = iso_label(args.iso)
    cmdline = f"archisobasedir=aris archisolabel={label} console=tty0 console=ttyS0,115200"
    vm = Vm(work, args.uefi, "live")
    vm.start(["-kernel", str(stage / "aris/boot/x86_64/vmlinuz-linux"),
              "-initrd", str(stage / "aris/boot/x86_64/initramfs-linux.img"),
              "-append", cmdline, "-cdrom", str(args.iso)])
    try:
        vm.agent.wait_ready(240)
        log("guest agent up")
        wait_until("live Hyprland session", lambda: vm.agent.sh("pgrep -x Hyprland")[0] == 0, 180)
        log("Hyprland running; letting the desktop settle")
        time.sleep(12)
        vm.qmp.screenshot(work / "1-live-desktop.png")
        diagnostics(vm, 1000, work / "1-live-diagnostics.txt")
        if args.skip_install:
            return

        conf = "\n".join([
            "ARIS_DISK=/dev/vda", f"ARIS_FS={args.fs}",
            f"ARIS_ENCRYPT={'yes' if args.encrypt else 'no'}", f"ARIS_LUKS_PASSWORD={LUKS}",
            "ARIS_FULLNAME='Aris Tester'", f"ARIS_USER={USER}", f"ARIS_PASSWORD={PASSWORD}",
            "ARIS_HOSTNAME=aris-test", "ARIS_TIMEZONE=Asia/Kathmandu", "ARIS_LOCALE=en_US.UTF-8",
            "ARIS_XKB_LAYOUT=us", "ARIS_KERNEL_PARAMS='console=tty0 console=ttyS0,115200'",
        ])
        vm.agent.sh(f"cat > /root/aris-test.conf <<'EOF'\n{conf}\nEOF")
        vm.agent.sh("setsid -f sh -c 'aris-install --config /root/aris-test.conf --yes "
                    ">/root/install.out 2>&1; echo $? >/root/install.rc'")
        log("aris-install started (unattended)")

        start, last = time.time(), ""
        while True:
            rc, out = vm.agent.sh("cat /root/install.rc 2>/dev/null")
            if rc == 0 and out.strip():
                code = int(out.strip())
                break
            _, step = vm.agent.sh("grep '==>' /var/log/aris-install.log | tail -n1")
            if step.strip() != last:
                last = step.strip()
                log(f"  {last[22:] if len(last) > 22 else last}")
            if time.time() - start > args.install_timeout:
                raise TimeoutError("installer did not finish")
            time.sleep(10)

        _, install_log = vm.agent.sh("cat /var/log/aris-install.log")
        (work / "install.log").write_text(install_log)
        _, install_out = vm.agent.sh("cat /root/install.out")
        (work / "install.out").write_text(install_out)
        log(f"aris-install exited {code} after {int(time.time() - start)}s")
        if code != 0:
            raise RuntimeError(f"aris-install failed (exit {code}); see {work / 'install.log'}")
    finally:
        vm.stop()


def phase_installed(work, args):
    log("Phase 2: installed system")
    vm = Vm(work, args.uefi, "installed")
    vm.start([])
    try:
        if args.encrypt:
            vm.answer_serial_prompt("assphrase", LUKS, 180)
            log("answered the LUKS passphrase prompt on serial")
        vm.agent.wait_ready(240)
        log("guest agent up")
        wait_until("greetd", lambda: vm.agent.sh("systemctl is-active greetd")[0] == 0, 120)
        time.sleep(6)
        vm.qmp.screenshot(work / "2-login.png")

        vm.qmp.type(USER + "\n")
        time.sleep(1.5)
        vm.qmp.type(PASSWORD + "\n")
        log("typed credentials into tuigreet")
        wait_until("Hyprland after login", lambda: vm.agent.sh("pgrep -x Hyprland")[0] == 0, 90)
        time.sleep(12)
        vm.qmp.screenshot(work / "3-installed-desktop.png")

        report = diagnostics(vm, 1000, work / "3-installed-diagnostics.txt")
        extra = [
            ("mounts", "findmnt -rno TARGET,SOURCE,FSTYPE,OPTIONS / /home /boot"),
            ("swap (zram)", "swapon --show"),
            ("kernel cmdline", "cat /proc/cmdline"),
            ("boot loader", "bootctl status 2>/dev/null | head -n 20 || grep -m3 menuentry /boot/grub/grub.cfg"),
            ("enabled services", "systemctl is-enabled NetworkManager bluetooth greetd fstrim.timer power-profiles-daemon"),
        ]
        with open(work / "3-installed-diagnostics.txt", "a") as f:
            for title, cmd in extra:
                rc, out = vm.agent.sh(cmd)
                f.write(f"\n### {title} (rc={rc})\n{out.rstrip()}\n")
        return report
    finally:
        vm.stop()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--bios", action="store_true", help="legacy BIOS instead of UEFI")
    ap.add_argument("--encrypt", action="store_true", help="install with LUKS2")
    ap.add_argument("--fs", choices=["btrfs", "ext4"], default="btrfs")
    ap.add_argument("--iso", type=Path, help="ISO to test (default: newest out/aris-*.iso)")
    ap.add_argument("--install-timeout", type=int, default=45 * 60)
    ap.add_argument("--skip-install", action="store_true", help="phase 1 checks only")
    args = ap.parse_args()
    args.uefi = not args.bios

    if args.iso is None:
        isos = sorted(ROOT.glob("out/aris-*.iso"), key=os.path.getmtime)
        if not isos:
            sys.exit("no ISO in out/; run 'make iso' first")
        args.iso = isos[-1]
    for tool in ("qemu-system-x86_64", "qemu-img", "bsdtar"):
        if not shutil.which(tool):
            sys.exit(f"{tool} not found")

    name = f"{'uefi' if args.uefi else 'bios'}-{args.fs}{'-luks' if args.encrypt else ''}"
    work = ROOT / "build" / "vm-test" / name
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    subprocess.run(["qemu-img", "create", "-q", "-f", "qcow2", str(work / "disk.qcow2"), "24G"], check=True)
    if args.uefi:
        shutil.copy(ovmf()[1], work / "OVMF_VARS.fd")
    log(f"testing {args.iso.name} [{name}] in {work.relative_to(ROOT)}")

    phase_live(work, args)
    if not args.skip_install:
        phase_installed(work, args)
    log("PASS")


if __name__ == "__main__":
    main()
