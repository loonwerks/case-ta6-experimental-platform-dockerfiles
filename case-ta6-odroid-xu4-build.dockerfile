# Docker configuration for CASE-TA6 Experimental Platform Build Environment
#
# Purpose: ...
#
# Ideas in this file were take from the seL4/CAmkES docker build.  Here they
# are streamlined sacrificing flexibility for simplicity in building a single
# environment that can more easily be managed.

FROM case-ta6-odroid-xu4-tools:latest

# Fetch prebuilt Linux rootfs
WORKDIR /rootfs
RUN curl http://cdimage.ubuntu.com/ubuntu-base/releases/16.04/release/ubuntu-base-16.04-core-armhf.tar.gz | tar xpz

# Fetch U-Boot and build
ENV CROSS_COMPILE=/toolchains/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/bin/arm-linux-gnueabihf-
ENV ARCH=arm
WORKDIR /git
RUN git clone https://github.com/hardkernel/u-boot.git -b odroidxu4-v2017.05
WORKDIR u-boot
RUN make odroid-xu4_defconfig && make 

# Fetch Linux Kernel and build
ENV CROSS_COMPILE=/toolchains/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/bin/arm-linux-gnueabihf-
ENV ARCH=arm
WORKDIR /git
ENV GIT_CURL_VERBOSE=1
RUN git clone --depth 1 https://github.com/hardkernel/linux.git -b odroidxu4-4.9.y odroidxu4-4.9.y
WORKDIR odroidxu4-4.9.y
RUN make odroidxu4_defconfig && make

# Construct the Linux bootfs
RUN mkdir /bootfs
RUN cp arch/arm/boot/zImage /bootfs

# Install the kernel modules in the rootfs
RUN make ARCH=arm INSTALL_MOD_PATH=/rootfs modules_install

############ Move me!! ##############
RUN apt-get install -y -q u-boot-tools

# Create initial boot script
WORKDIR /bootfs
RUN echo 'setenv initrd_high "0xffffffff" \n\
setenv fdt_high "0xffffffff" \n\
setenv vout "hdmi" \n\
setenv cecenable "false" \n\
setenv disable_vu7 "false" \n\
setenv governor "performance" \n\
setenv ddr_freq "825" \n\
setenv external_watchdog "false" \n\
setenv external_watchdog_debounce "3" \n\
setenv HPD "true" \n\
setenv bootrootfs "console=tty1 console=ttySAC2,115200n8 root=UUID=e15b93a3-d43c-4e1a-a847-c96fa32cc6e7 rootwait ro fsck.repair=yes net.ifnames=0" \n\
setenv bootcmd "fatload mmc 0:1 0x40008000 zImage; bootm 0x40008000" \n\
setenv bootargs "console=tty1 console=ttySAC1,115200n8 root=/dev/mmcblk0p2 rootwait rw mem=2047M" \n\
boot' > boot.txt
RUN mkimage -A arm -T script -C none -n boot -d ./boot.txt boot.scr


# Customize the rootfs
# RUN apt-get install -y -q qemu-user-static debootstrap binfmt-support
# ENV targetdir=/debian-rootfs
# ENV distro=stretch
# RUN debootstrap --arch=armhf --foreign $distro $targetdir
# RUN cp /usr/bin/qemu-arm-static $targetdir/usr/bin
# RUN chroot $targetdir
