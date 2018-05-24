# Docker configuration for CASE-TA6 Experimental Platform Build Environment
#
# Purpose: ...
#
# Ideas in this file were take from the seL4/CAmkES docker build.  Here they
# are streamlined sacrificing flexibility for simplicity in building a single
# environment that can more easily be managed.

FROM case-ta6-tools:latest

# Install Arm U-Boot build tool chain
WORKDIR /toolchains
RUN curl https://dn.odroid.com/toolchains/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.xz | tar -Jx

# Install Arm Linux kernel build tool chain
WORKDIR /toolchains
RUN curl https://dn.odroid.com/ODROID-XU/compiler/arm-eabi-4.6.tar.gz | tar xz

