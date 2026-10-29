# Dell XPS 8940 Linux shutdown: fans keep running — a verified GRUB workaround

> **A confirmed workaround on one computer, not a fix for Linux or Ubuntu.**
>
> On **October 29, 2026**, a Dell XPS 8940 user successfully powered off the entire Dell chassis by selecting a custom **Power Off via GRUB** menu entry. Normal Ubuntu shutdown remained broken. **This does not establish that all Linux 7.x systems are affected.**

## Symptoms

A normal Ubuntu shutdown progressed until:

- The display went completely black.
- The hard drive appeared to spin down.
- **Dell CPU/chassis fans remained powered and gradually sped up**, and the computer's power light stayed on.
- A long press of the physical Dell power button was needed to turn it off.

This occurred after an Ubuntu upgrade around August 2026. The reporter recalls earlier Linux 6.x software working, but **a Linux 6.x comparison was not independently retested**. The problem also occurred with several different Intel Arc Pro B70 cards.

## Hardware and tests

| Item | Observed configuration / outcome |
| --- | --- |
| Desktop | Dell XPS 8940 |
| CPU | Intel Core i7-11700 |
| BIOS | Dell 2.27.1 (reported) |
| Graphics | Intel UHD 750 (`i915`) and Arc Pro B70 (`xe`); multiple B70 boards tested |
| Installed OS | Ubuntu 26.04.1 LTS, kernel `7.0.0-42-generic` |
| Live USB | Ubuntu environment, kernel `7.0.0-14-generic` |
| Installed Ubuntu graphical shutdown | **Failed:** Dell fans/lights kept running |
| Installed Ubuntu booted with `systemd.unit=multi-user.target` | **Failed:** same power-off behavior, without graphical desktop |
| Separate Ubuntu live USB shutdown | **Failed:** same power-off behavior |
| Windows 11 full shutdown using `shutdown /s /t 0` | **Passed:** Dell powered off completely |
| GRUB custom `halt` entry | **Passed:** Dell fans and power light switched off completely |

The system used a **separate external PSU for the discrete GPU**. This is an unusual setup; its electrical behavior and the separate GPU PSU's final state were **not validated** by the GRUB test. The Dell's own internal fans and power indicator did switch off.

**Interpretation:** the platform can switch off when instructed through GRUB, but the tested Linux shutdown paths did not reach the same result. It may be a Linux ACPI / kernel / device shutdown interaction; the precise cause is unconfirmed. Another issue seen during troubleshooting was an Intel `xe` blitter-engine fault/reset during normal runtime, but **it was not demonstrated to cause the shutdown failure** or other system freezes.

## Workaround 1 — manually select GRUB power-off (**tested successfully**)

> Use this **only after Ubuntu has completed an ordinary reboot into GRUB**. The GRUB entry is **not** a safe replacement for stopping applications, flushing writes and unmounting filesystems in a running OS.

### A. Add a GRUB menu entry

On a typical Ubuntu GRUB 2 installation, open:

```bash
sudo nano /etc/grub.d/40_custom
```

Keep the existing header lines intact. Append this entry at the bottom:

```grub
menuentry "Power Off via GRUB" {
    halt
}
```

Save the file.

### B. Display the GRUB menu

Edit `/etc/default/grub` and set:

```ini
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=10
```

Keep **all other pre-existing kernel parameters** unchanged. Confirm the Ubuntu entry is still your usual default.

Regenerate the menu:

```bash
sudo update-grub
```

Verify the entry exists:

```bash
grep -F 'menuentry "Power Off via GRUB"' /boot/grub/grub.cfg
```

### C. Use it

1. Save all work and close applications.
2. In Ubuntu, run `sudo reboot`.
3. When GRUB appears, select **Power Off via GRUB**.
4. Press Enter.

**Observed result (October 29, 2026):** the Dell shut off completely, including its own internal fans. No kernel downgrade was necessary.

**Note:** `sudo reboot` must actually reach GRUB. If your computer cannot reboot successfully, this workaround will not help.

## Workaround 2 — one command or desktop button (**optional; not yet end-to-end verified**)

GRUB supports selecting a menu entry for **one subsequent boot** with `grub-reboot`. The example below automates selecting the power-off entry, then initiates a normal Linux **reboot**. The verified component is the manual GRUB `halt`; the automatic flow is supplied for others to test.

### A. Configure one-time GRUB selection

Edit `/etc/default/grub` and set:

```ini
GRUB_DEFAULT=saved
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=10
```

Then run:

```bash
sudo update-grub
sudo grub-set-default 0
```

`0` is appropriate **only if entry zero is your desired normal Ubuntu boot**. Adjust for your menu. Do **not** enable `GRUB_SAVEDEFAULT=true` unless you understand how it changes future boot defaults.

### B. Test the next-boot selection without automation

```bash
sudo grub-reboot "Power Off via GRUB"
sudo grub-editenv list
```

Verify `next_entry=Power Off via GRUB` appears, then **save your work** and run `sudo reboot` to test. GRUB should use that one-time entry and clear it afterward if its environment block is writable. Keep the menu visible for recovery.

### C. Optional guarded helper script

Once the one-time behavior is verified on your own system, you can install the sample helper:

```bash
sudo install -o root -g root -m 0755 scripts/grub-poweroff-next.sh /usr/local/sbin/grub-poweroff-next
```

Use:

```bash
sudo /usr/local/sbin/grub-poweroff-next
```

The script checks the key GRUB conditions, writes the one-time target, verifies it, and invokes a normal `systemctl reboot`. It **does not** call `systemctl poweroff` or directly cut power to a running OS.

### D. Optional GNOME desktop launcher

After the helper is installed and verified, copy the sample launcher:

```bash
mkdir -p ~/Desktop
cp 'desktop/Power Off via GRUB.desktop' ~/Desktop/
chmod +x ~/Desktop/'Power Off via GRUB.desktop'
```

On Ubuntu GNOME, you may need to right-click the desktop file and choose **Allow Launching**. The launcher uses `pkexec`; an administrator authentication dialog and a working Polkit graphical agent are required. Save your work **before clicking** — the helper initiates a reboot without a separate unsaved-work confirmation. This GUI path was prepared but has **not** been independently confirmed as working end-to-end.

## Precautions

- **Do not** type `halt` at the GRUB prompt while Linux is still running; GRUB runs only after a reboot, not inside a live Ubuntu session.
- Do not use `reboot -f`, `poweroff -f`, or an immediate SysRq power-off as a substitute for safe OS shutdown unless you have a separate recovery plan: these can risk unsaved data.
- **Back up** `/etc/default/grub` and `/etc/grub.d/40_custom` before editing, and keep a bootable recovery USB.
- GRUB menu paths and availability differ across distributions, bootloaders, encrypted boot volumes, RAID, and filesystems.
- The GRUB environment block may not be writable on some installations; if so, one-time boot selection cannot be relied on.
- The Dell's normal Linux shutdown fault remains. Running-system freezes and GPU-engine resets require **separate diagnosis**.
- If your GPU is independently powered, confirm that its separate power supply and attached devices are actually safe/off. The Dell's power-off result alone is insufficient.

## How to help identify the underlying bug

Please open a GitHub Issue with a **sanitized** description of your hardware, firmware, distro, kernel, exact shutdown symptom, Windows comparison if available, and whether a live USB or text-only boot behaves the same. See [testing notes](docs/TESTING.md).

Avoid uploading entire unredacted `journalctl` output, serial numbers, IP addresses, usernames, disk IDs, proprietary configuration or private data.

## References

- [GNU GRUB manual — simple configuration](https://www.gnu.org/software/grub/manual/grub/html_node/Simple-configuration.html)
- [GNU GRUB manual — next_entry](https://www.gnu.org/software/grub/manual/grub/html_node/next_005fentry.html)
- [GNU GRUB manual — GRUB commands, including halt](https://www.gnu.org/software/grub/manual/grub/grub.html)
- [Debian Wiki — GrubReboot](https://wiki.debian.org/GrubReboot)

### Scope of this report

A **single confirmed hardware case**, with multiple controlled observations. This repository shares a reproducible workaround; it does **not** claim a universal kernel 7+ regression or provide a proven causal fix. If another user tests a different machine, please report both successes and failures.

---

## Official Ubuntu Kernel Bug Report

**Ubuntu Launchpad Bug #2172556**

https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2172556

This issue has been reported against the Ubuntu `linux` kernel package.

### Confirmed observations

- Dell XPS 8940 running Ubuntu 26.04
- Shutdown failure reproduced with Linux 7.0.0-14 and 7.0.0-42
- Windows 11 powers off successfully
- GRUB `halt` powers off the Dell successfully
- The underlying Linux/firmware interaction remains unresolved

**Status:** Reported to Ubuntu developers. Root cause not yet confirmed.

If you experience similar symptoms, please contribute your hardware,
kernel version, and test results to the Launchpad report.
