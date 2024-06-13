#!/bin/bash
clear
echo -e "Welcome to my Arch Linux install script\n"

# test internet
if ping -q -c 2 -W 1 1.1.1.1 > /dev/null; then
    echo "[OK] Internet Connected"
else
    echo "[FAIL] No Vaild Internet Connection"
    echo "Use iwd to setup wifi (if you don't have ethernet)"
    exit
fi

# test if uefi
if efivar -l > /dev/null; then
    echo "[OK] Booted into UEFI"
else
    echo "[FAIL] Not in UEFI"
    exit
fi

# set terimnal font
#setfont ter-132b
echo "[OK] Set terminal font"

# get drive
old_ifs=$IFS
IFS=$'\n'
echo -e "\nPlease choose the drive you would like to install to (int)"
counter=0
for drive in $(lsblk -dn);
do
    counter=$(( counter + 1 ))
    echo "($counter) $drive"
done
echo -e "*THIS WILL WIPE THE DRIVE*\n"

# drive choice
read drive_num
counter=0
drive_choice=''
for drive in $(lsblk -dn);
do
    counter=$(( counter + 1 ))
    if [[ $counter == $drive_num ]]; then
        drive_choice=$(echo $drive | awk '{print $1}')
    fi
done

if [[ $drive_choice == '' ]]; then
    echo "That's not a valid drive"
    exit
fi

IFS=$old_ifs

# wipe drive
wipefs -a /dev/$drive_choice
echo "[OK] Wiped drive"

# partition drive
parted -s /dev/$drive_choice mklabel gpt mkpart ESP fat32 1MiB 1025MiB set 1 boot on mkpart primary linux-swap 1025MiB 9217MiB mkpart primary ext4 9217MiB 100% > /dev/null
echo -e "[OK] Created partition\n"

lsblk

echo "Does this look right?"
read ok

# mount
