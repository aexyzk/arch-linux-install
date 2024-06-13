#!/bin/bash
clear
echo -e "Welcome to my Arch Linux install script\n"

# test internet
if ping -q -c 2 -W 1 8.8.8.8 > /dev/null; then
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

# set keys
if [[ $(loadkeys us > /dev/null) ]]; then
    echo "[OK] Set keyboard layout"
else
    echo "[FAIL] Couldn't set keyboard layout"
fi

# set terimnal font
setfont ter-132b
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
echo " "

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

echo "'$drive_choice' selected"

IFS=$old_ifs

# wipe drive
# partition drive
