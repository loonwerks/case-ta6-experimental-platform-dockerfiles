# Docker configuration for CASE-TA6 Experimental Platform Build Environment
#
# Purpose: ...
#
# Ideas in this file were take from the seL4/CAmkES docker build.  Here they
# are streamlined sacrificing flexibility for simplicity in building a single
# environment that can more easily be managed.

FROM case-ta6-odroid-xu4-build:latest

# Set the working directory to /git
WORKDIR /git

# 'git' the source code for OpenUxAS
RUN ["git", "clone", "https://github.com/afrl-rq/OpenUxAS.git"]

# 'git' the source code for LcmpGen
RUN ["git", "clone", "https://github.com/afrl-rq/LmcpGen.git"]

# 'git' the source code for OpenAMASE
# RUN ["git", "clone", "https://github.com/afrl-rq/OpenAMASE.git"]

# Install build prerequisites
# The script provided by AFRL isn't compatible with Docker, duplicate
# those items here
# RUN ["/bin/bash", "/git/OpenUxAS/install_prerequisites.sh"]
RUN apt-get install -y -q \
	pkg-config \
	git \
	gitk \
	libglu1-mesa-dev \
	uuid-dev \
	libboost-filesystem-dev \
	libboost-regex-dev \
	libboost-system-dev \
	python3-pip 
RUN pip3 install --upgrade pip
RUN pip3 install ninja
RUN pip3 install meson==0.42.1
RUN pip3 install matplotlib pandas
RUN apt-get install -y -q software-properties-common
# RUN add-apt-repository -y ppa:webupd8team/java
RUN add-apt-repository -y "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main"
RUN apt-get update -y -q
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | \
	sudo debconf-set-selections
RUN echo debconf shared/accepted-oracle-license-v1-1 seen true | \
	sudo debconf-set-selections
RUN apt-get install -y -q --allow-unauthenticated oracle-java8-installer
RUN apt-get install -y -q oracle-java8-set-default
RUN apt-get install -y -q ant

# Build the LmcpGen JAR
WORKDIR /git/LmcpGen
RUN ["ant", "jar"]

# Autogenerate source code for LMCP libraries
WORKDIR /git/OpenUxAS
RUN ["/bin/bash", "/git/OpenUxAS/RunLmcpGen.sh"]

# Prepare UxAS-specific patches to external libraries
WORKDIR /git/OpenUxAS
RUN ./prepare

# Inject standard cross-build environment
RUN apt-get install -y -q crossbuild-essential-armhf
RUN dpkg --add-architecture armel
RUN dpkg --add-architecture armhf
RUN apt-get update -y -q
RUN apt-get install -y -q \
	libgl1-mesa-glx:armhf libgl1-mesa-dev:armhf libglu1-mesa:armhf libglu1-mesa-dev:armhf

# Inject cross-compilation configuration
WORKDIR /git/OpenUxAS
RUN echo '[binaries] \n\
c = '"'"'arm-linux-gnueabihf-gcc'"'"'\n\
cpp = '"'"'arm-linux-gnueabihf-g++'"'"'\n\
ar = '"'"'arm-linux-gnueabihf-ar'"'"'\n\
strip = '"'"'arm-linux-gnueabihf-strip'"'"'\n\
pkgconfig = '"'"'arm-linux-gnueabihf-pkg-config'"'"'\n\
\n\
[properties] \n\
c_args = [ '"'"'-lGLU'"'", ''"'"'-lGL'"'"' ] \n\
cpp_args = [ '"'"'-lGLU'"'", ''"'"'-lGL'"'"' ] \n\
c_link_args = [ '"'"'-lGLU'"'", ''"'"'-lGL'"'"' ] \n\
cpp_link_args = [ '"'"'-lGLU'"'", ''"'"'-lGL'"'"' ] \n\
needs_exe_wrapper = true \n\
\n\
[host_machine]\n\
system = '"'"'linux'"'"'\n\
cpu_family = '"'"'arm'"'"'\n\
cpu = '"'"'armv7'"'"'\n\
endian = '"'"'little'"'"'\n' > cross_file.txt

# Build OpenUxAS
WORKDIR /git/OpenUxAS
#ENV CROSS_COMPILE=/toolchains/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/bin/arm-linux-gnueabihf-
#ENV ARCH=arm
ENV CROSS_COMPILE=
ENV ARCH=arm
RUN meson build-armhf --cross-file=cross_file.txt --buildtype=release \
	&& ninja -C build-armhf all

# Install the UxAS binary to the rootfs
RUN install build-armhf/uxas /rootfs/usr/bin
