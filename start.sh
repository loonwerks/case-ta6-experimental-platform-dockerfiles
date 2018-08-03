#! /bin/bash

docker build --force-rm=true \
	-f case-ta6-tools.dockerfile \
	-t case-ta6-tools:latest \
	. && \
docker build --force-rm=true \
	-f case-ta6-odroid-xu4-tools.dockerfile \
	-t case-ta6-odroid-xu4-tools:latest \
	. && \
docker build --force-rm=true \
	-f case-ta6-odroid-xu4-build.dockerfile \
	-t case-ta6-odroid-xu4-build:latest \
	. && \
docker build --force-rm=true \
	-f case-ta6-uxas-tools.dockerfile \
	-t case-ta6-uxas-tools:latest \
	. && \
docker build --force-rm=true \
	-f case-ta6-uxas-build.dockerfile \
	-t case-ta6-uxas-build:latest \
	. && \
docker run \
	--privileged \
	-it \
	--hostname in-container \
	--rm \
	-v $PWD:/host \
	case-ta6-uxas-build bash

