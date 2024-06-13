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
echo "Set terminal font"

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
    echo "[FAIL] That's not a valid drive"
    exit
fi

IFS=$old_ifs

# wipe drive
wipefs -a /dev/$drive_choice
echo "Wiped drive"

# partition drive
parted -s /dev/$drive_choice mklabel gpt mkpart ESP fat32 1MiB 1025MiB set 1 boot on mkpart primary linux-swap 1025MiB 9217MiB mkpart primary ext4 9217MiB 100% > /dev/null
echo -e "Created partitions\n"

lsblk

echo "Does this look right? (Press enter)"
read ok

# check drive type
if [[ $drive_choice == *"nvme"* ]]; then
    prefix="p"
else
    prefix=""
fi

# get drive paths
boot="/dev/$drive_choice${prefix}1"
swap="/dev/$drive_choice${prefix}2"
root="/dev/$drive_choice${prefix}3"

echo -e "\nBOOT: $boot\nSWAP: $swap\nROOT: $root\n"

# format partitions
mkfs.fat -F32 $boot -y
echo "Formatted BOOT"

mkswap $swap
swapon $swap
echo "Enabled SWAP"

mkfs.ext4 $root -y
echo "Formatted ROOT"

echo " "

# mount partitions
mount $root /mnt
echo "Mounted ROOT"

mkdir /mnt/boot
mount $boot /mnt/boot
echo -e "Mounted BOOT\n"

lsblk

echo -e "\nIs everything mounted correctly? (Press enter)"
read ok

# downloading contrib
echo "downloading necessary packages for install"
pacman -Sy pacman-contrib

# update mirrors
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
echo "Created mirrorlist backup"

echo "Ranking mirrorlist..."
rankmirrors -n 6 /etc/pacman.d/mirrorlist.bak > /etc/pacman.d/mirrorlist
cat /etc/pacman.d/mirrorlist
echo " "

# pacstrap
echo "Downloading Arch Linux"
pacstrap -K /mnt base linux linux-fireware base-devel
echo " "

# fstab
genfstab -U -p /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
echo -e "\nCreated fstab using UUID\n"

# chroot
arch-chroot /mnt
echo -e "chrooted into new system\n"

# installing some programs
echo -e "Installing some programs\n"
pacman -S doas bash-completion neofetch hyfetch vim
echo " "

# locale
cp /etc/locale.gen /etc/locale.gen.bak
echo "es_US.UTF-8 UTF-8" > /etc/locale.gen
local-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8
echo -e "Edited Locale\n"

# timezone
echo "Choose a timezone"
echo -e "\n(1) America/Los_Angeles PST\n(2) America/Denver MST\n(3) America/Chicago CST\n(4) America/New_York EST\n"
read timezone
if [[ $timezone == 1 ]]; then
    $zone="America/Los_Angles"
elif [[ $timezone == 2 ]]; then
    $zone="America/Denver"
elif [[ $timezone == 3 ]]; then
    $zone="America/Chicago"
elif [[ $timezone == 4 ]]; then
    $zone="America/New_York"
else
    $zone="America/Chicago"
fi
ln -s /usr/share/zoneinfo/$zone > /etc/localtime
echo -e "Set to $zone\n"

# syncing clock
hwclock --systohc --utc
echo -e "Synced Hardware clock\n"

# hostname
echo "Please choose a hostname"
read hostname
echo $hostname > /etc/hostname
echo -e "System hostname set to '$hostname'\n"

# ssd fstrim
if [[ $(cat /sys/block/${drive_choice}/queue/rotational) == "1" ]]; then
    echo "fstrim not enabled (not ssd)"
else
    systemctl enable fstrim.timer
    echo "fstrim enabled"
fi

echo "welp thats it"
