#!/bin/bash

# set paths
INSTALL_DIR=$(dirname "$0")
SCRIPTS="$INSTALL_DIR"/components

ERROR_CODES="$INSTALL_DIR"/error_codes.sh

echo "Starting custom Arch install."

# source error codes
echo -e "\nImporting error codes."
if source "$ERROR_CODES"; then
    echo -e "\tSuccessfully imported error codes."
else
    echo -e "\tError importing error codes..."
    exit 1
fi

# source component files
echo -e "\nImporting component files."
for script in "$SCRIPTS"/*.sh; do
    if source "$script"; then
        echo -e "\tSuccessfully imported $(basename "$script")."
    else
        echo -e"\tError importing $(basename "$script")..."
        return $ERR
    fi
done

# terminal font
set_font
FONT_CODE=$?

if [ $FONT_CODE -eq $FONT_OK ]; then
    echo -e "\tFont set successfuly!"
elif [$FONT_CODE -eq $FONT_ERR ]; then
    echo -e "\tFailed to set font."
else
    echo -e "\tUnknown error setting font..."
    exit $FONT_CODE
fi

# keyboard layout
set_keyboard_layout
KB_CODE=$?

if [ $KB_CODE -eq $KB_OK ]; then
    echo -e "\tKeyboard layout set successfuly!"
elif [ $KB_CODE -eq $KB_ERR ]; then
    echo -e "\tFailed to set keyboard layout..."
    exit $KB_CODE
else
    echo -e "\tUnknown error setting keyboard layout..."
    exit $KB_CODE
fi

# boot vertification
verify_boot
BOOT_CODE=$?

if [ $BOOT_CODE -eq $BOOT_TYPE_UEFI ]; then
    echo -e "\tUEFI boot detected."
elif [ $BOOT_CODE - eq $BOOT_TYPE_LEGACY ]; then
    echo -e "\tLegacy boot not yet supported..."
    exit $BOOT_CODE
else
    echo -e "\tUnknown error verifiying boot..."
    exit $BOOT_CODE
fi


# network setup
network_setup
NET_CODE=$?

if [ $NET_CODE -eq $NET_TYPE_WIRED ]; then
    echo -e "\tWired connection established."
elif [ $NET_CODE -eq $NET_TYPE_WIRELESS ]; then
    echo -e "\tWireless connection established."
elif [ $NET_CODE -eq $NET_ERR]; then
    echo -e "\tNo connection established..."
    exit $NET_CODE
else
    echo -e "\tUnknown error establishing connection..."
    exit $NET_CODE
fi

# system clock
update_clock
CLK_CODE=$?

if [ $CLK_CODE -eq $CLK_OK ]; then
    echo -e "\tSystem clock updated."
elif [ $CLK_CODE -eq $CLK_ERR ]; then
    echo -e "\tFailed to update system clock..."
    exit $CLK_CODE
else
    echo -e "\tUnknown error updating system clock..."
    exit $CLK_CODE
fi

# partition
partition_disk
PART_CODE=$?

if [ $PART_CODE -eq $PART_OK ]; then
    echo -e "\tPartitioned disk."
elif [ $PART_CODE -eq $PART_ERR ]; then
    echo -e "\tFailed to parition disk..."
    exit $PART_CODE
else
    echo -e "\tUnknown error paritioning disk..."
    exit $PART_CODE
fi


# format
format_disk
FMT_CODE=$?

if [ $FMT_CODE -eq $FMT_OK ]; then
    echo -e "\tDisk formatted."
elif [ $FMT_CODE -eq $FMT_ERR ]; then
    echo -e "\tFailed to format disk..."
    exit $FMT_CODE
else
    echo -e "\tUnknown error formating disk..."
    exit $FMT_CODE
fi


# mount
mount_disk
MNT_CODE=$?

if [ $MNT_CODE -eq $MNT_OK ]; then
    echo -e "\tDisk mounted."
elif [ $MNT_CODE -eq $MNT_ERR ]; then
    echo -e "\tFailed to mount disk..."
    exit $MNT_CODE
else
    echo -e "\tUnknown error mounting disk..."
    exit $MNT_CODE
fi


# install core packages
install_core
PKG_CODE=$?

if [ $PKG_CODE -eq $PKG_OK ]; then
    echo -e "\tCore packages installed."
elif [ $PKG_CODE -eq $PKG_ERR ]; then
    echo -e "\tFailed to install core packages..."
    exit $PKG_CODE
else
    echo -e "\tUnknown error installing core packages..."
    exit $PKG_CODE
fi


# configure
configure_user
CFG_CODE=$?

if [ $CFG_CODE -eq $CFG_OK ]; then
    echo -e "\tUser profile configured."
elif [ $CFG_CODE -eq $CFG_ERR ]; then
    echo -e "\tFailed to configure user profile..."
    exit $CFG_CODE
else
    echo -e "\tUnknown error configuring user profile..."
    exit $CFG_CODE
fi


# bootloader
update_clock
BOOTLDR_CODE=$?

if [ $BOOTLDR_CODE -eq $BOOTLDR_OK ]; then
    echo -e "\tInstalled bootloader."
elif [ $BOOTLDR_CODE -eq $BOOTLDR_ERR ]; then
    echo -e "\tFailed to install bootloader..."
    exit $BOOTLDR_CODE
else
    echo -e "\tUnknown error installing bootloader..."
    exit $BOOTLDR_CODE
fi


# reboot

echo "Arch install successful."