# Docker configuration for CASE-TA6 Experimental Platform Build Environment
#
# Purpose: ...
#
# Ideas in this file were take from the seL4/CAmkES docker build.  Here they
# are streamlined sacrificing flexibility for simplicity in building a single
# environment that can more easily be managed.

FROM case-ta6-uxas-tools:latest

# Set the working directory to /git
WORKDIR /git

# 'git' the source code for OpenUxAS
# RUN ["git", "clone", "https://github.com/afrl-rq/OpenUxAS.git"]
RUN ["git", "clone", "-b", "ph2-platform-assessment-1", "https://github.com/loonwerks/case-ta6-experimental-platform-OpenUxAS.git" "OpenUxAS"]

# 'git' the source code for LcmpGen
RUN ["git", "clone", "https://github.com/afrl-rq/LmcpGen.git"]

# 'git' the source code for OpenAMASE
# RUN ["git", "clone", "https://github.com/afrl-rq/OpenAMASE.git"]

# Build the LmcpGen JAR
WORKDIR /git/LmcpGen
RUN ["ant", "jar"]

# Autogenerate source code for LMCP libraries
WORKDIR /git/OpenUxAS
RUN ["/bin/bash", "/git/OpenUxAS/RunLmcpGen.sh"]

# Prepare UxAS-specific patches to external libraries
WORKDIR /git/OpenUxAS
RUN ./prepare

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
c_args = [ '"'"'-lGLU'"'", ''"'"'-lGL'"'"', '"'"'-static-libstdc++'"'"' ] \n\
cpp_args = [ '"'"'-lGLU'"'", ''"'"'-lGL'"'"', '"'"'-static-libstdc++'"'"' ] \n\
c_link_args = [ '"'"'-lGLU'"'", ''"'"'-lGL'"'"', '"'"'-static-libstdc++'"'"' ] \n\
cpp_link_args = [ '"'"'-lGLU'"'", ''"'"'-lGL'"'"', '"'"'-static-libstdc++'"'"' ] \n\
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
