# Docker configuration for CASE-TA6 Experimental Platform Build Environment
#
# Purpose: ...
#
# Ideas in this file were take from the seL4/CAmkES docker build.  Here they
# are streamlined sacrificing flexibility for simplicity in building a single
# environment that can more easily be managed.

ARG BASE_IMG=case-ta6-odroid-xu4-build
FROM $BASE_IMG

# Necessary because we cannot avoid apt updates in the FROM image
RUN apt-get update -y -q

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
RUN apt-get install -y -q openjdk-8-jre openjdk-8-jdk
RUN apt-get install -y -q ant

# Inject standard cross-build environment
RUN apt-get install -y -q crossbuild-essential-armhf
RUN dpkg --add-architecture armel
RUN dpkg --add-architecture armhf
RUN apt-get update -y -q
RUN apt-get install -y -q \
	libgl1-mesa-glx:armhf libgl1-mesa-dev:armhf libglu1-mesa:armhf libglu1-mesa-dev:armhf
