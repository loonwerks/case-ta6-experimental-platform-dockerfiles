# Docker configuration for CASE-TA6 Experimental Platform Build Environment
#
# Purpose: ...
#
# Ideas in this file were take from the seL4/CAmkES docker build.  Here they
# are streamlined sacrificing flexibility for simplicity in building a single
# environment that can more easily be managed.

FROM debian:stretch
#FROM ubuntu:16.04

# Fetch some basics
RUN sed -i 's/deb.debian.org/httpredir.debian.org/g' /etc/apt/sources.list \
    && dpkg --add-architecture i386 \
    && apt-get update -q \
    && apt-get install -y --no-install-recommends \
	libc6:i386 libncurses5:i386 libncurses5-dev:i386 libqt4-dev:i386 libstdc++6:i386 lib32z1 \
	apt-utils \
	software-properties-common \
	sudo \
        curl \
	build-essential gcc g++ binutils file \
	device-tree-compiler \
        git \
        make \
	ant \
	bc \
	less \
        python-dev \
        python-pip \
        python3-dev \
        python3-pip \
	tar \
	xz-utils \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/
#	aptdaemon \

# Setup python dep manager
RUN for p in "pip" "python3 -m pip"; \
    do \ 
        ${p} install \
            setuptools \
        && ${p} install pip --upgrade; \
    done

# Install Google's repo
RUN mkdir -p /scripts/repo \
    && curl https://storage.googleapis.com/git-repo-downloads/repo > /scripts/repo/repo \
    && chmod a+x /scripts/repo/repo

