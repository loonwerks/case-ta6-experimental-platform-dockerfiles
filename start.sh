#! /bin/bash

docker build --force-rm=true \
	-f case-ta6-tools.dockerfile \
	-t case-ta6-tools:latest \
	. && \
docker build --force-rm=true \
	-f case-ta6-uxas.dockerfile \
	-t case-ta6-uxas:latest \
	. && \
docker run \
	-it \
	--hostname in-container \
	--rm \
	-v $PWD:/host \
	case-ta6-uxas bash

