# Docker configuration for CASE-TA6 Experimental Platform Build Environment
#
# Purpose: ...
#
# Ideas in this file were take from the seL4/CAmkES docker build.  Here they
# are streamlined sacrificing flexibility for simplicity in building a single
# environment that can more easily be managed.

FROM case-ta6-odroid-xu4-tools:latest

# Fetch U-Boot and build
ENV CROSS_COMPILE=/toolchains/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/bin/arm-linux-gnueabihf-
ENV ARCH=arm
WORKDIR /git
RUN git clone https://github.com/hardkernel/u-boot.git -b odroidxu4-v2017.05
WORKDIR u-boot
RUN make odroid-xu4_defconfig && make 

# Fetch Linux Kernel and build
# ENV CROSS_COMPILE=/toolchains/arm-eabi-4.6/bin/arm-eabi-
# ENV ARCH=arm
ENV CROSS_COMPILE=/toolchains/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/bin/arm-linux-gnueabihf-
ENV ARCH=arm
WORKDIR /git
RUN git clone --depth 1 https://github.com/hardkernel/linux.git -b odroidxu4-4.9.y odroidxu4-4.9.y
WORKDIR odroidxu4-4.9.y
# RUN make odroidxu3_defconfig && make
RUN make odroidxu4_defconfig && make

# Fetch prebuilt Linux rootfs


