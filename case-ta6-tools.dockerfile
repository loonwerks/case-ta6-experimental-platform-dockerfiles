# Docker configuration for CASE-TA6 Experimental Platform Build Environment
#
# Purpose: ...
#
# Ideas in this file were take from the seL4/CAmkES docker build.  Here they
# are streamlined sacrificing flexibility for simplicity in building a single
# environment that can more easily be managed.

#FROM debian:stretch
FROM ubuntu:16.04

# Fetch some basics
RUN sed -i 's/deb.debian.org/httpredir.debian.org/g' /etc/apt/sources.list \
    && apt-get update -q \
    && apt-get install -y --no-install-recommends \
	aptdaemon \
	apt-utils \
	software-properties-common \
	sudo \
        curl \
        git \
        make \
	ant \
        python-dev \
        python-pip \
        python3-dev \
        python3-pip \
    && apt-get upgrade -y -q \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/


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

