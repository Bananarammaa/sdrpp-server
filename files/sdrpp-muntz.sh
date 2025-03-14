#!/bin/bash
# This script uses a feature of bash - extglob which allows rm !(exception_list) to
# selectively remove any file in the current image layer except those listed.  
# Used for muntzing libraries and files down to the minimal set needed to run the application.

shopt -s extglob

#   Remove select libraries
	cd /usr/lib
	rm -rf !(x86_64-linux-gnu|sdrpp)

# 	remove all libraries except ...
	cd /usr/lib/x86_64-linux-gnu
	EXC="!(libc.*|ld-linux*"							# basic c library
#	EXC+="|libtinfo*"									# needed for bash
	EXC+="|libselinux*|libacl.*|libattr.*|libpcre*"		# needed for cp
	EXC+="|libresolv.*"									# needed for busybox
	EXC+=")"
	rm -fr $EXC

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
    libselinux*
    libudev*
    libgcc_s*
    librt*
ENDLIST

#   Nuke anything not needed in the container
	rm -rf /var/lib/dpkg
	rm -rf /var/lib/apt
	rm -rf /var/cache/debconf
	rm -rf /var/cache/apt
	rm -rf /usr/share

# 	And last remove everything from sbin and bin except busybox.
	cd /usr/sbin && rm !(nothing)
	cd /usr/bin  && rm !(busybox)

