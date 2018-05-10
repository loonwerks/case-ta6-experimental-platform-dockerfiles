# Docker configuration for CASE-TA6 Experimental Platform Build Environment
#
# Purpose: ...
#
# Ideas in this file were take from the seL4/CAmkES docker build.  Here they
# are streamlined sacrificing flexibility for simplicity in building a single
# environment that can more easily be managed.

FROM case-ta6-tools:latest

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
RUN add-apt-repository -y ppa:webupd8team/java
RUN apt-get update -y -q
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | \
	sudo debconf-set-selections
RUN echo debconf shared/accepted-oracle-license-v1-1 seen true | \
	sudo debconf-set-selections
RUN apt-get install -y -q oracle-java8-installer
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

# Build OpenUxAS
WORKDIR /git/OpenUxAS
RUN meson build --buildtype=release \
	&& ninja -C build all

# CMD ["bash"]
