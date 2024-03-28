#!/bin/bash

# verify boot
verify_boot() {
    echo -e "\nVerifying boot mode."
    if [ -e "/sys/firmware/efi/fw_platform_size" ]; then
        return $BOOT_TYPE_UEFI
    else
        return $BOOT_TYPE_LEGACY
    fi
}