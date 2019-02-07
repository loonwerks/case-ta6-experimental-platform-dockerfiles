ARG USER_BASE_IMG=case-ta6-uxas-tools
FROM $USER_BASE_IMG

# This dockerfile is a shim between the images from Dockerhub and the 
# user.dockerfile.
# Add extra dependencies in here!

# For example, uncomment this to get cowsay on top of the dependencies:

RUN echo "DARPA CASE TA6 extras"

# RUN apt-get update -q \
#     && apt-get install -y --no-install-recommends \
#         cowsay \
#     && apt-get clean autoclean \
#     && apt-get autoremove --yes \
#     && rm -rf /var/lib/{apt,dpkg,cache,log}/
#
# RUN /usr/games/cowsay "DARPA CASE!"



