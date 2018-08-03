# Docker configuration for CASE-TA6 Experimental Platform Build Environment
#
# Purpose: ...
#
# Ideas in this file were take from the seL4/CAmkES docker build.  Here they
# are streamlined sacrificing flexibility for simplicity in building a single
# environment that can more easily be managed.

FROM case-ta6-odroid-xu4-build:latest

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

# Inject standard cross-build environment
RUN apt-get install -y -q crossbuild-essential-armhf
RUN dpkg --add-architecture armel
RUN dpkg --add-architecture armhf
RUN apt-get update -y -q
RUN apt-get install -y -q \
	libgl1-mesa-glx:armhf libgl1-mesa-dev:armhf libglu1-mesa:armhf libglu1-mesa-dev:armhf
