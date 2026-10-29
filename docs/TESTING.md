# Diagnostic notes and reproducibility

This file separates **observations** from **hypotheses**. The shutdown workaround was tested on October 29, 2026.

## Observed conditions

**Hardware:** Dell XPS 8940, Intel Core i7-11700, BIOS 2.27.1 (reported); UHD 750 integrated GPU and Intel Arc Pro B70 discrete GPU with an independent external PSU. Several different B70 boards were tried. The Dell's own chassis fans did not stop during failed Linux shutdowns.

**Linux tests:** normal graphical Ubuntu shutdown; boot to `systemd.unit=multi-user.target` (no GNOME) and request `sudo systemctl poweroff`; separate Ubuntu live USB (kernel `7.0.0-14-generic`) and `sudo systemctl poweroff -i` after a live-session inhibitor blocked the first attempt. All resulted in black display and storage shutdown while Dell fans continued running. The installed Ubuntu kernel was `7.0.0-42-generic`.

**Windows comparison:** Windows 11 `shutdown /s /t 0` completely powered down the Dell, including internal fans and power light.

**GRUB test:** custom `menuentry "Power Off via GRUB" { halt }` selected from GRUB after clean Ubuntu reboot; the Dell powered down completely, including the internal fans.

**Not yet fully tested:** an automated one-time `grub-reboot` shutdown script and GUI launcher. Writing `next_entry=Power Off via GRUB` was observed, but success of fully automatic selection on the original machine was not independently confirmed in the conversation.

**Additional driver event:** a separate Ubuntu session logged an `xe` GT0 `bcs` memory fault and engine reset. That event occurred well before the session ended, and cannot be treated as proof of the power-off cause.

## Exact shutdown symptoms to compare

1. Does the display turn black?
2. Does disk activity/spin-down stop?
3. Are fans on the **motherboard's own PSU** still running?
4. Do fans ramp up after video loss?
5. Does an ordinary reboot reach GRUB successfully?
6. Does a Linux live USB also fail?
7. Does Windows **full shutdown** (not merely sleep or hybrid shutdown) succeed?
8. Does GRUB's `halt` power the machine off when selected after a clean reboot?

## Safe collection of follow-up evidence

Before a controlled shutdown, record the kernel with `uname -r` and the effective command line with `cat /proc/cmdline`. After rebooting, identify the correct boot using `journalctl --list-boots`; inspect the final messages using `journalctl -b -1 -e --no-pager` **only after confirming that boot -1 is the failed shutdown**. Boot indexes shift on every reboot. Distinguish service shutdown completion from the kernel and firmware's final power-off transition.

Sanitize logs before sharing. In particular, don't post user identifiers, IPs, URLs to private services, device serial numbers, filesystem UUIDs or authentication messages.

## Possible areas for kernel-level investigation (unproven)

- ACPI S5 entry and firmware response on Dell XPS 8940.
- Kernel device shutdown ordering and PCIe devices/driver teardown.
- Interactions with installed kernel parameters or firmware.
- Comparison with an earlier Linux kernel if the older hardware stack actually boots and is safe to test.

Avoid changing multiple BIOS options and kernel parameters at the same time. Keep all long GPU training disabled until runtime stability, power and watchdog configuration have been separately verified.
