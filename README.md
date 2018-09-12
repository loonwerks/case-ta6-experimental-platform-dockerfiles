CASE-TA6 Experimental Platform Docker Images
============================================

**Welcome!**

This repository contains the dockerfile configurations to build the
Docker images that, when instantiated, provide a uniform build
environment for building target sofware for the CASE TA-6 Experimental
Platform.

## Why Do We Want to Use Docker?

[Docker](http://www.docker.com) provides a facility for deployment of
applications as light-weight containers.  These containers can be
easily deployed across an infrastructre allowing standardization and
automation.  Why is this of interest to the CASE TA-6 program?  Four
features that serve program needs:

+ Construction of a build environment containing common features and
dependencies is a complex and ordinarily time-intensive effort.
Docker provides the facility to manage and deploy the build
environment as an application container.  Build tools and dependencies
can be precisely identified, collected and configured in a
standardized manner.

+ Maintenance of the build environment as tool and dependcency
versions change and as new functionality emerges is ordinarily
difficult to coordinate, especially across a program team in diverse
organizations located across the globe.  Docker provides means to
manage revision control of the build environment container, precisely
and reproducibly distributig specific configurations, including
selecting specific versions of elements if necessary.

+ Some software elements of the build ecosystem, while being open
source, have licence clauses that prevent redistribution and merely
including them in a giant "monorepo" containing everything that we
need.  Docker provides the capability to collect that software from
the origial sources, preserving adherence to copyright protections.

+ The TA-6 team is a collection of diverse organizations each with
differing enterprise operating systems and tools.  Ordinarily this
would require customization of the the build environment to operate on
each of the team sites, potentially affecting the behavior of the
build tools.  Docker constructs the build environment as a container
containing all of the tools and dependencies which may be run on any
platform supporting Docker client software, including Microsoft
Windows, Linux, and Apple OSX.

## Building Your Own Docker Images

To preserve copyright protections, team members are required to
individually construct the Docker images.  This, however, is not
difficult as Dockerfile specifications of the build environment is
provided.  Once a Docker client is installed, team members run a
script to invoke Docker to download and constituent software and
construct the build environment and run

### Installing and Configuring Docker

Please see the [Docker Community
Edition](https://www.docker.com/community-edition) page for
installation instructions for your platform.

Alternatively, Docker CE may be installed using the package management
system of many operating systems

+ For Ubuntu and derivatives such as Linux Mint, see [Get Docker CE
for Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/).

+ For CentOS, see [Get Docker CE for
CentOS](https://docs.docker.com/install/linux/docker-ce/centos/).

+ For Apple OSX there is an unofficial means of installing via Brew,
see [How to easily install and uninstall docker on MacOs
[sic]](https://stackoverflow.com/questions/44346109/how-to-easily-install-and-uninstall-docker-on-macos).
However, we have not tested it and cannot vouch for it.  Instead,
downloanding the .DMG from Docker is recommended.

### Notes on Using Docker Behind a Proxy

May users may need to setup and use Docker behind a corporate firewall
and proxy server system.  There are a few steps to getting Docker
working in this configuration.  First the Docker service must be
instructed as to the proxy server.  On Unix-like operating systems
this is typically done by adding the following entries to the
/etc/default/docker file:

~~~~~
export http_proxy="http://proxy.corporate.com:8080/"
export https_proxy="https://proxy.corporate.com:8080/"
export HTTP_PROXY="http://proxy.corporate.com:8080/"
export HTTPS_PROXY="https://proxy.corporate.com:8080/"
~~~~~

where, of course, the "proxy.corporate.com:9090/" is replaced with the
approprite network name and port number for your organization.

Next Docker containers must be instructed also to use proxies.  This
is done on a per-user basis by adding the following to the user
~/.docker/config.json file:

~~~~~
{
  "proxies": {
    "default": {
      "httpProxy": "http://proxy.corporate.com:8080/",
      "httpsProxy": "http://proxy.corporate.com:8080/",
      "noProxy": "*.corporate.com"
    }
  }
}
~~~~~

where again the values are replaced with those appropriate for your
organization.

Finally, Docker attempts to manage network name resolution through DNS
by filtering out local servers and replacing with with public DNS
servers.  Again, firewalls and proxy servers will get in the way.
This can be resolved through a bit of reconfiguration of the name
resolution.  Please see the Docker Documentation article [Configure
container
DNS](https://docs.docker.com/v17.09/engine/userguide/networking/default_network/configure-dns/)
and Docker Forums article [DNS resolution not working in
containers](https://forums.docker.com/t/dns-resolution-not-working-in-containers/36246)
for a detailed explanation.  To resolve the issue, add the following
to the /etc/docker/daemon.json file:

~~~~~
{
	"dns" : ["127.0.1.1"]
}
~~~~~

where the address "127.0.1.1" is replaced with an address of a DNS
server accessible within your private network.  A comma-separated list
of servers may be provided if you wish to have some alternate servers.

There are likely Windows equivalents for the steps taken here, but
this has not yet been explored.

## Running the Docker Images

In Docker nomenclature a running instance of an image is called a
"container."  The .dockerfiles in this repository build a collection of
images that collect tools and dependencies and support building the OpenUxAS
for the CASE TA-6 Experimental Platform.  Once the docker images are built,
they can be run as a container producing a shell in which UxAS can be built.

The ideas behind how this is put together with .dockerfiles and a Makefile is
based on a [similar project](https://github.com/SEL4PROJ/seL4-CAmkES-L4v-dockerfiles)
created by the [Trustworthy Systems](https://ts.data61.csiro.au/projects/TS/)
group to access a common build environment for seL4, CAmkES and L4v.  Thanks!

### Quick Start

To sequentially build the docker images and start a shell in which UxAS
can be built, run:

~~~
git clone https://eisgit.rockwellcollins.com/case-ta6/experimental-platform-docker-images.git
cd experimental-platform-docker-images
make user
~~~

A location for the top of the UxAS source code tree can also be specified by:

~~~
make user HOST_DIR=/scratch/uxas_stuff
~~~

### More Lengthy Description of Startup Details

TODO

### Example of Fetching and Building UxAS

First open the build as described above.

To build UxAS its source code must first be retrieved.  A fork of the [OpenUxAS](https://github.com/afrl-rq/OpenUxAS) software repository
containing necessary additions and examples for the CASE TA-6 experimental
platform exists [here](https://eisgit.rockwellcollins.com/case-ta6/OpenUxAS).

~~~
git clone https://github.com/afrl-rq/LmcpGen.git
git clone -b develop-case-ta6 https://eisgit.rockwellcollins.com/case-ta6/OpenUxAS.git
~~~

The follow the build instructions for OpenUxAS as follows:

~~~
cd LmcpGen
ant jar
cd ../OpenUxAS
./RunLmcpGen.sh
./prepare
meson build-armhf --cross-file=arm-linux-gnueabihf-cross-file.txt --buildtype=release
ninja -C build-armhf all
~~~

## Fusing the Build onto a MicroSD Card

Ideally, this is as simple as running (assuming you have a bash shell):

~~~
./build-sd-card.sh <dev>
~~~

where `<dev>` is the device file for the raw MicroSD card (e.g. /dev/sdc).
This script erases, partitions and formats the MicroSD card, gathers the
various elements of software including the bootloader, device tree,
boot filesystem and root filesystem, UxAS application and example
configuration files and fuses these onto the MicroSD card.

In future, we hope to have a script working in a platform independent
manner under the Docker-based build system that constructs a whole-disk
image file.  This file would then support using fusing tools for for
various host development platforms.

## To Do

1. Add Google 'repo' manifest to gather the various pieces of software
   (e.g. OpenUxAS, LmcpGen, etc.).
2. Add a top-level build script, likely in 'ant' with at least incremental
   and rebuild targets.
