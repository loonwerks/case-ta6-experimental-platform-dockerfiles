# Docker configuration for CASE-TA6 Experimental Platform Build Environment
#
# Purpose: ...
#
# Ideas in this file were take from the seL4/CAmkES docker build.  Here they
# are streamlined sacrificing flexibility for simplicity in building a single
# environment that can more easily be managed.

FROM case-ta6-odroid-xu4-tools:latest

# Fetch all build dependencies
RUN apt-get install -y -q \
    lib32stdc++6 lib32z1 lzop u-boot-tools \
    build-essential gcc \
    libncurses5-dev libssl-dev

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
ENV CROSS_COMPILE=arm-linux-gnueabihf-
ENV ARCH=arm
ENV PATH=/toolchains/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/bin/:${PATH}
WORKDIR /git
RUN git config --global http.postBuffer 2147463648
RUN git config --global https.postBuffer 2147483648
ENV GIT_CURL_VERBOSE=1
RUN git clone --depth 1 https://github.com/hardkernel/linux.git -b odroidxu4-4.14.y odroidxu4-4.14.y
WORKDIR odroidxu4-4.14.y
RUN make odroidxu4_defconfig && make -j4

# Construct the Linux bootfs
RUN mkdir /bootfs
RUN cp arch/arm/boot/zImage /bootfs
RUN cp arch/arm/boot/dts/*odroidxu*.dtb /bootfs
RUN cp .config /bootfs/config
RUN make kernelrelease >> /bootfs/kernelrelease.txt

# Install the kernel modules and headers in the rootfs
RUN make ARCH=arm INSTALL_MOD_PATH=/rootfs modules_install
RUN make INSTALL_HDR_PATH=/rootfs/usr headers_install

####### Move me!!! ###########
RUN apt-get install -y -q initramfs-tools

# Create boot RAM filesystem
WORKDIR /rootfs/boot
RUN cp /bootfs/config config-`cat /bootfs/kernelrelease.txt`
# Note: this does not yet work because it cannot grab the necessary
# because its not done in a chroot (which docker doesn't support)
RUN mkinitramfs -o initrd.img-`cat /bootfs/kernelrelease.txt` `cat /bootfs/kernelrelease.txt`
RUN mkimage -A arm -O linux -T ramdisk -a 0x0 -e 0x0 -n initrd.img-`cat /bootfs/kernelrelease.txt` -d initrd.img-`cat /bootfs/kernelrelease.txt` uInitrd-`cat /bootfs/kernelrelease.txt`
RUN cp uInitrd-`cat /bootfs/kernelrelease.txt` /bootfs/uInitrd

# Create initial boot script
WORKDIR /bootfs
RUN echo 'ODROIDXU-UBOOT-CONFIG\n\
\n\
'#' U-Boot Parameters\n\
setenv initrd_high "0xffffffff"\n\
setenv fdt_high "0xffffffff"\n\
\n\
'#' Mac address configuration\n\
setenv macaddr "00:1e:06:61:7a:39"\n\
\n\
'#' --- HDMI / DVI Mode Selection ---\n\
'#' ------------------------------------------\n\
'#' - HDMI Mode\n\
setenv vout "hdmi"\n\
'#' - DVI Mode (disables sound over HDMI as per DVI compat)\n\
'#' setenv vout "dvi"\n\
\n\
'#' --- HDMI CEC Configuration ---\n\
'#' ------------------------------------------\n\
setenv cecenable "false" '#' false or true\n\
'#' set to true to enable HDMI CEC\n\
\n\
'#' Enable/Disable ODROID-VU7 Touchsreen\n\
setenv disable_vu7 "false" '#' false\n\
\n\
'#' CPU Governor Selection\n\
'#' Available governos: conservative, userspace, powersave, ondemand, performance, schedutil\n\
setenv governor "performance"\n\
\n\
'#' DRAM Frequency\n\
'#' Sets the LPDDR3 memory frequency\n\
'#' Supported values: 933 825 728 633 (MHZ)\n\
setenv ddr_freq 825\n\
\n\
'#' External watchdog board enable\n\
setenv external_watchdog "false"\n\
'#' debounce time set to 3 ~ 10 sec, default 3 sec\n\
setenv external_watchdog_debounce "3"\n\
\n\
\n\
'#'------------------------------------------------------------------------------\n\
'#'\n\
'#' HDMI Hot Plug detection\n\
'#'\n\
'#'------------------------------------------------------------------------------\n\
'#'\n\
'#' Forces the HDMI subsystem to ignore the check if the cable is connected or \n\
'#' not.\n\
'#' false : disable the detection and force it as connected.\n\
'#' true : let cable, board and monitor decide the connection status.\n\
'#' \n\
'#' default: true\n\
'#' \n\
'#'------------------------------------------------------------------------------\n\
setenv HPD "true"\n\
\n\
'#'------------------------------------------------------------------------------------------------------\n\
'#' Basic Ubuntu Setup. Don'"'"'t touch unless you know what you are doing.\n\
'#' --------------------------------\n\
setenv bootrootfs "console=tty1 console=ttySAC2,115200n8 root=UUID=e15b93a3-d43c-4e1a-a847-c96fa32cc6e7 rootwait ro fsck.repair=yes net.ifnames=0"\n\
\n\
\n\
'#' Load kernel, initrd and dtb in that sequence\n\
fatload mmc 0:1 0x40008000 zImage\n\
fatload mmc 0:1 0x42000000 uInitrd\n\
\n\
setenv fdtloaded "false"\n\
if test "x${board_name}" = "x"; then setenv board_name "xu4"; fi\n\
if test "${board_name}" = "xu4"; then fatload mmc 0:1 0x44000000 exynos5422-odroidxu4.dtb; setenv fdtloaded "true"; fi\n\
if test "${board_name}" = "xu3"; then fatload mmc 0:1 0x44000000 exynos5422-odroidxu3.dtb; setenv fdtloaded "true"; fi\n\
if test "${board_name}" = "xu3l"; then fatload mmc 0:1 0x44000000 exynos5422-odroidxu3-lite.dtb; setenv fdtloaded "true"; fi\n\
if test "${fdtloaded}" = "false"; then fatload mmc 0:1 0x44000000 exynos5422-odroidxu4.dtb; setenv fdtloaded "true"; fi\n\
\n\
fdt addr 0x44000000\n\
\n\
setenv hdmi_phy_control "HPD=${HPD} vout=${vout}"\n\
if test "${cecenable}" = "false"; then fdt rm /cec@101B0000; fi\n\
if test "${disable_vu7}" = "false"; then setenv hid_quirks "usbhid.quirks=0x0eef:0x0005:0x0004"; fi\n\
if test "${external_watchdog}" = "true"; then setenv external_watchdog "external_watchdog=${external_watchdog} external_watchdog_debounce=${external_watchdog_debounce}"; fi\n\
\n\
'#' final boot args\n\
setenv bootargs "${bootrootfs} ${videoconfig} ${hdmi_phy_control} ${hid_quirks} smsc95xx.macaddr=${macaddr} ${external_watchdog} governor=${governor}"\n\
\n\
'#' set DDR frequency\n\
dmc ${ddr_freq}\n\
\n\
'#' Boot the board\n\
bootz 0x40008000 0x42000000 0x44000000' > boot.ini
