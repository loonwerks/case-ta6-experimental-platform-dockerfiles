CASE-TA6 Experimental Platform Docker Images
============================================

Welcome!

This repository contains the dockerfile configurations to build the
Docker images that, when instantiated, provide a uniform build
environment for building target sofware for the CASE TA-6 Experimental
Platform.

# Why Do We Want to Use Docker?

Because some software elements of the build ecosystem, while being
open source, have redistribtion clauses that prevent merely including
them in a giant "monorepo" containing everything that we need.  Docker
({*reference to Docker website*} allows us to construct a collection
of software that runs on any platform on which the Docker service is
installed.  Also, Docker allows us to give explicit instructions as
exactly which software to obtain and how to configure it, and to
automate the whole process.

# Building Your Own Images

{*TO DO*}

