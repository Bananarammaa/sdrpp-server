#!/bin/bash

shopt -s extglob

#   Nuke some misc stuff, /usr/sbin and /usr/bin
rm -rf /var/lib/dpkg
rm -rf /var/lib/apt
rm -rf /var/cache/debconf
rm -rf /usr/share/doc
rm -rf /usr/share/zoneinfo
rm -rf /usr/share/perl5
rm -rf /usr/share/common-licenses

cd /usr/sbin
rm !(ldconfig)

cd /usr/bin
rm !(bash|ls|sh|dash|more|rm)

#   Remove select libraries
rm -rf /usr/lib/apt
rm -rf /usr/lib/systemd

#   Remove everything but what we need from x86_64_linux-gnu
cd /lib/x86_64-linux-gnu
EXCLUDE="!(libc.*|libselinux*|libtinfo*|ld-linux*)"
rm -rf $EXCLUDE
