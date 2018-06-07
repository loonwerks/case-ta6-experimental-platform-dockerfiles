#! /bin/bash
#

#docker_image=case-ta6-uxas:latest
docker_image=case-ta6-odroid-xu4-build-4.14:latest

function zeroize_sd() {
    echo "zeroizing sd card"
    sudo dd if=/dev/zero of=${1} bs=1M count=2048
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
    docker run --rm $docker_image tar Ccpf /rootfs - . | sudo tar Cxpf rootfs -
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
umount_sd $1
