#!/bin/bash
# verify-signing.sh
set -e

CHROOT="config/chroot-root"

echo "[*] Checking MOK keys..."
for f in MOK.priv MOK.pem MOK.der; do
    if [[ -f "$CHROOT/root/$f" ]]; then
        echo "  OK: $f exists"
    else
        echo "  FAIL: $f missing!"
    fi
done

echo "[*] Checking kernel module signing..."
find "$CHROOT/lib/modules/" -type f -name '*.ko' | while read mod; do
    signer=$(modinfo "$mod" | grep -i signer || true)
    if [[ -n "$signer" ]]; then
        echo "  OK: $mod signed ($signer)"
    else
        echo "  WARN: $mod unsigned"
    fi
done

echo "[*] Checking GRUB EFI binaries signing..."
EFI_PATHS=(
    "$CHROOT/boot/efi/EFI/debian/grubx64.efi"
    "$CHROOT/boot/efi/EFI/kali/grubx64.efi"
    "$CHROOT/usr/lib/grub/x86_64-efi-signed/grubx64.efi"
    "$CHROOT/usr/lib/grub/x86_64-efi/grubx64.efi"
)
for grub_bin in "${EFI_PATHS[@]}"; do
    if [[ -f "$grub_bin" ]]; then
        out=$(sbsigntool verify "$grub_bin" 2>&1)
        if echo "$out" | grep -q "Signature verification OK"; then
            echo "  OK: $grub_bin signed"
        else
            echo "  WARN: $grub_bin not properly signed"
        fi
    fi
done

echo "[*] Verification complete."

