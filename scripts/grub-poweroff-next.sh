#!/bin/sh
# OPTIONAL, NOT YET END-TO-END VERIFIED ON THE ORIGINAL DELL.
# Run as root only after verifying manual GRUB halt AND one-time grub-reboot.
set -eu
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: must run as root (e.g. with sudo/pkexec)." >&2
    exit 1
fi

if ! grep -Eq '^GRUB_DEFAULT=(saved|"saved")[[:space:]]*$' /etc/default/grub; then
    echo "ERROR: set GRUB_DEFAULT=saved and run sudo update-grub first." >&2
    exit 1
fi

if ! grep -Eq '^[[:space:]]*menuentry[[:space:]]+"Power Off via GRUB"' /boot/grub/grub.cfg; then
    echo "ERROR: custom GRUB power-off entry not present in grub.cfg." >&2
    exit 1
fi

if ! command -v grub-reboot >/dev/null 2>&1 || ! command -v grub-editenv >/dev/null 2>&1; then
    echo "ERROR: GRUB utilities not found." >&2
    exit 1
fi

grub-reboot 'Power Off via GRUB'
if ! grub-editenv list | grep -Fxq 'next_entry=Power Off via GRUB'; then
    echo "ERROR: one-time GRUB entry could not be verified; NOT rebooting." >&2
    exit 1
fi

echo "GRUB will select 'Power Off via GRUB' on the next boot. Rebooting normally."
exec systemctl reboot
