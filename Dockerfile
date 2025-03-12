# Dockerfile to build sdrplay and sdrpp server.
# Based on an excellent example from github f4fhh/sdrppserver_container.
# SDRplay API is pulled from sdrplay website
# sdrpp is pulled from github sdrpp nightly releases.
# Thanks to sdrplay and Alexandre Rouma for making this possible.
#
# D. G. Adams
# 2024-Sep-15

FROM debian:bookworm-slim AS build

# Get and run SDRplay API installer
WORKDIR /sdrplay
ADD https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-3.15.1.run ./SDRplay.run

RUN <<ENDRUN
    chmod +x SDRplay.run
    ./SDRplay.run --tar -xvf
    chmod 644 x86_64/libsdrplay_api.so.3.15
    chmod 755 x86_64/sdrplay_apiService
ENDRUN
# Now sdrplay_apiService is built and in /sdrplay/x86_64

# install sdrpp
ADD "https://github.com/AlexandreRouma/SDRPlusPlus/releases/download/nightly/sdrpp_debian_bookworm_amd64.deb" ./sdrpp.deb

RUN <<ENDRUN
    apt-get update
    apt-get -y install ./sdrpp.deb rtl-sdr libusb-1.0-0 libglfw3
    cp /sdrplay/x86_64/sdrplay_apiService /usr/local/bin/sdrplay_apiService
    cp /usr/bin/sdrpp /usr/local/bin
ENDRUN
# Build complete

#   copy all needed libraries.  Kind of a reverse muntzing - add until it quits whinning.
WORKDIR /base/usr/lib
RUN <<ENDRUN
    mv /lib/sdrpp .
    cp -a /usr/lib/libsdrpp_core.so .
    cp -a /sdrplay/x86_64/libsdrplay_api* .
    while read p; do
        cp -a /usr/lib/x86_64-linux-gnu/$p .
    done <<ENDLIST
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
        libxcb.so*
        libXau.so*
        libXdmcp.so.*
        libbsd.*
        libmd.*
        librt*
        libudev*
        libgcc_s*
        libstdc++*
        libusb*
ENDLIST
    rm *.a
ENDRUN
#         ld-linux* doesn't work in above list
#         libselinux*
#        librtlsdr.*
#        libpcre2.*
#        libtinfo*

# grab files  and move binaries from /usr/local/bin
# when done files are as follows:
#   /base/sdrpp holds binaries, config, and startup script
#   /base/lib holds all needed libraries
WORKDIR /base/sdrpp
COPY sdrpp.conf.d ./conf.d
COPY sdrpp.sh .
RUN cp /usr/local/bin/* .
######################################################

FROM bellsoft/alpaquita-linux-base:stream-glibc AS filesystem

COPY --from=build /base /
# / now holds binaries and config files in /sdrpp and libs in /usr/lib

RUN <<EOR
#   clean up some libraries
    ln -s /lib/libsdrplay_api.so.3.15 /lib/libsdrplay_api.so.3

#   Now remove some alpaquita stuff we don't need
#	Remember just because we delete it doesn't free up the space taken in the filesystem image.
    rm -rf /lib/gconv
    rm -rf /lib/locale
    rm -rf /lib/libmvec*
    rm -rf /usr/sbin/sln
    rm -rf /usr/sbin/ldconfig*
    rm -rf /usr/sbin/iconvconfig
    rm -rf /usr/share/zoneinfo
    rm -rf /usr/share/X11
    rm -rf /usr/bin/makedb
    rm -rf /usr/bin/locale*
    rm -rf /usr/bin/iconv
    rm -rf /usr/bin/gencat
    rm -rf /usr/bin/getconf
    rm -rf /usr/bin/getent
EOR
# Ready for scratch.  We use scratch to clean up layer junk by just copying needed stuff into the install image.
#   Alpaquita files are in /
#	Libraries are in /usr/lib
#	binaries and config files are in /sdrpp
#####################################################################

FROM scratch AS install
COPY --from=filesystem / /
EXPOSE 5259
WORKDIR /sdrpp
USER nobody
CMD ["/sdrpp/sdrpp.sh" ]
