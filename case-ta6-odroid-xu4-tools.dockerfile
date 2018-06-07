# Docker configuration for CASE-TA6 Experimental Platform Build Environment
#
# Purpose: ...
#
# Ideas in this file were take from the seL4/CAmkES docker build.  Here they
# are streamlined sacrificing flexibility for simplicity in building a single
# environment that can more easily be managed.

FROM case-ta6-tools:latest

# Install downloaders
RUN apt-get install -y -q curl wget

# Install Arm U-Boot build tool chain
WORKDIR /toolchains
RUN curl https://dn.odroid.com/toolchains/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.xz | tar -Jx

# Install Arm Linux kernel build tool chain
WORKDIR /toolchains
RUN wget https://releases.linaro.org/components/toolchain/binaries/4.9-2017.01/arm-linux-gnueabihf/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz
RUN tar -Jxf gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz
RUN rm -f gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz
