#! /bin/bash
#

HOST=${HOST:-.}

docker_image=case-ta6-uxas-build

function zeroize_sd() {
    echo "zeroizing sd card"
    sudo dd if=/dev/zero of=${1} bs=1M count=512 status=progress
}

function mount_sd() {
    echo "mounting filesystems"
    mkdir bootfs
    mkdir rootfs
    sudo mount ${1}"1" bootfs
    sudo mount ${1}"2" rootfs
}

function umount_sd() {
    echo "unmounting filesystems"
    sudo umount bootfs
    sudo umount rootfs
    rmdir bootfs rootfs
}

function create_partitions() {
    echo "creating partitions"
    echo 'label: dos
label-id: 0x1bc8b1d4
device: ${1}
unit: sectors

${1}1 : start=3072, size=266239, type=c
${1}2 : start=266240, size=124469248, type=83' | sudo sfdisk ${1}
    sudo partprobe
}

function format_partitions() {
    echo "formatting bootfs partition"
    sudo mkfs.vfat -n boot ${1}1
    echo "formatting rootfs partition"
    sudo mkfs.ext4 -L rootfs ${1}2
    sudo tune2fs -O ^has_journal ${1}2
    if [ -n "${2}" ]
    then
	sudo tune2fs ${1}2 -U ${2}
    fi
}

function install_bootloader() {
    echo "BL1 fusing"
    docker run --rm $docker_image cat /git/u-boot/sd_fuse/bl1.bin.hardkernel | sudo dd iflag=dsync oflag=dsync of=${1} seek=1
    echo "BL2 fusing"
    docker run --rm $docker_image cat /git/u-boot/sd_fuse/bl2.bin.hardkernel.720k_uboot | sudo dd iflag=dsync oflag=dsync of=${1} seek=31
    echo "u-boot fusing"
    docker run --rm $docker_image cat /git/u-boot/u-boot-dtb.bin | sudo dd iflag=dsync oflag=dsync of=${1} seek=63
    echo "TrustZone S/W fusing"
    docker run --rm $docker_image cat /git/u-boot/sd_fuse/tzsw.bin.hardkernel | sudo dd iflag=dsync oflag=dsync of=${1} seek=1503
    echo "u-boot env erase"
    sudo dd iflag=dsync oflag=dsync if=/dev/zero of=${1} seek=2015 count=32
    sudo sync
}

function install_bootfs() {
    echo "bootfs installing"
    docker run --rm $docker_image tar Ccf /bootfs - . | sudo tar Cxf bootfs -
}

function install_rootfs() {
    echo "rootfs installing"
    # docker run --rm $docker_image tar Ccpf /rootfs - . | sudo tar Cxpf rootfs -
    docker run --rm --privileged $docker_image bash -c "mkdir -p /mnt/rootfs && mount /ubuntu-image/1.img /mnt/rootfs && tar Ccpf /mnt/rootfs - ." | sudo tar Cxpf rootfs -    
}

function setup_chroot() {
    sudo cp /usr/bin/qemu-arm-static rootfs/usr/bin
    for m in `echo 'sys dev proc'`; do sudo mount /$m rootfs/$m -o bind; done
}

function unsetup_chroot() {
    for m in `echo 'sys dev proc'`; do sudo umount rootfs/$m; done
    sudo rm rootfs/usr/bin/qemu-arm-static
}

function setup_wifi() {
    sudo sed -i -e '/\t\t\trm -fr \/\.first_boot/a\' -e '\t\t\t[ ! -f \/etc\/NetworkManager\/system-connections\/wifi-wlan0 ] && nmcli connection add ifname wlan0 autoconnect yes save yes type wifi ssid CASE-UxAS-Net && nmcli connection modify wifi-wlan0 wifi-sec.key-mgmt wpa-psk wifi-sec.psk CASE-UxAS-Raze-is-Cool' rootfs/aafirstboot
}

function add_accounts() {
    echo 'adduser --disabled-password --gecos "" uxas && addgroup uxas adm && addgroup uxas sudo && echo "uxas:uxas" | chpasswd' | sudo tee -a rootfs/adduser_uxas.sh > /dev/null
    setup_chroot
    sudo LC_ALL=C chroot rootfs bash /adduser_uxas.sh
    unsetup_chroot
    sudo rm rootfs/adduser_uxas.sh
}

function install_uxas() {
    setup_chroot
    echo 'apt-get update -y -q && apt-get install -y -q libglu1-mesa:armhf libglu1-mesa-dev:armhf' | sudo tee -a rootfs/install_libglu1.sh > /dev/null
    sudo LC_ALL=C chroot rootfs bash /install_libglu1.sh
    unsetup_chroot
    sudo rm rootfs/install_libglu1.sh
    sudo mkdir rootfs/home/uxas/build
    # docker run --rm $docker_image cat /git/OpenUxAS/build-armhf/uxas | sudo tee -a rootfs/home/uxas/build/uxas > /dev/null
    sudo cp ${HOST}/OpenUxAS/build-armhf/uxas rootfs/home/uxas/build/uxas
    sudo chown -R 1000 rootfs/home/uxas/build
    sudo chgrp -R 1000 rootfs/home/uxas/build
    sudo chmod +x rootfs/home/uxas/build/uxas
    # docker run --rm $docker_image tar Ccf /git/OpenUxAS - examples | sudo tar Cxf rootfs/home/uxas -
    sudo cp -R ${HOST}/OpenUxAS/examples rootfs/home/uxas
    sudo chown -R 1000 rootfs/home/uxas/examples
    sudo chgrp -R 1000 rootfs/home/uxas/examples
}

set -x

if [ -z $1 ]
then
    echo "usage: ${0} <SD card device file>"
    exit 0
fi

zeroize_sd $1
install_bootloader $1
create_partitions $1
format_partitions $1 e15b93a3-d43c-4e1a-a847-c96fa32cc6e7
mount_sd $1
install_bootfs $1
install_rootfs $1
setup_wifi
add_accounts $1
install_uxas
umount_sd $1
