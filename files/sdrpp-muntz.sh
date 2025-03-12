#!/bin/bash
# Removes unneeded files.  Use option extglob to allow rm !()
shopt -s extglob

#   Nuke some misc stuff, /usr/sbin and /usr/bin
rm -rf /var/lib/dpkg
rm -rf /var/lib/apt
rm -rf /var/cache/debconf
rm -rf /usr/share/doc
rm -rf /usr/share/zoneinfo
rm -rf /usr/share/perl5
rm -rf /usr/share/common-licenses
cd /usr/sbin && rm !(nothing)
cd /usr/bin &&  rm !(busybox|cp|rm)

#   Remove select libraries
cd /usr/lib
rm -rf !(x86_64-linux-gnu|sdrpp)

#   Remove everything but what commands (bash,rm,etc) need for operation
cd /usr/lib/x86_64-linux-gnu
rm -rf !(libc.*|libselinux*|libpcre*|libtinfo*|ld-linux*|libacl.*|libattr.*)

#   Now copy in needed libraries
while read p; do
    cp -a /sdrpp/tmp/$p /usr/lib/x86_64-linux-gnu
done <<ENDLIST
    libsdrplay_api.so.*
    libsdrpp_core.so
    libglfw.*
    libOpenGL.*
    libfftw3f.*
    libvolk.*
    libzstd.*
    libm.*
    libdl.*
    libX11.so.*
    libpthread.*
    libGLdispatch.*
    liborc-0.4.*
    libxcb.*
    libXau.*
    libXdmcp.*
    libbsd.*
    libmd.*
    librtlsdr.*
    libusb*
    libstdc++*
    libc.*
    libselinux*
    libpcre2*
    libudev*
    libtinfo*
    libgcc_s*
    librt*
    libresolv.*
ENDLIST
