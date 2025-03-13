# Dockerfile to build sdrplay and sdrpp server.
# Based on an excellent example from github f4fhh/sdrppserver_container.
# SDRplay API is pulled from sdrplay website
# sdrpp is pulled from github sdrpp nightly releases.
# Thanks to sdrplay and Alexandre Rouma for making this possible.
#
# D. G. Adams
# 2025-March-12

FROM debian:bookworm-slim AS dga-build

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
    apt-get -y install ./sdrpp.deb rtl-sdr libusb-1.0-0 libglfw3 busybox
    cp /sdrplay/x86_64/sdrplay_apiService /usr/local/bin/sdrplay_apiService
    cp /usr/bin/sdrpp /usr/local/bin
ENDRUN
# Both the sdrpp binary and sdrplay_apiService are in /usr/local/bin
# Now do some flimflamery to preserve library links across layer copy.
WORKDIR /sdrpp/tmp
RUN <<EOR
    cp -a /usr/lib/x86_64-linux-gnu/* .
    cp -a /sdrplay/x86_64/libsdrplay_api* .
    cp -a /usr/lib/libsdrpp_core.* .
    ln -s libsdrplay_api.so.3.15 libsdrplay_api.so.3
    rm *.a
EOR
######################################################
# Build our filesystem
# copy all needed files from dga-build.
# Then call sdrpp-muntz to remove unneeded files
# and last, install busybox.  Order of commands is critical when changing shells.

FROM debian:bookworm-slim AS dga-filesystem

COPY --from=dga-build /usr/lib/sdrpp /lib/sdrpp/
COPY --from=dga-build /sdrpp/tmp /sdrpp/tmp/
COPY --from=dga-build /usr/local/bin/* /sdrpp
COPY --from=dga-build /bin/busybox /bin
COPY files/ /sdrpp

RUN <<EOR
    /sdrpp/sdrpp-muntz.sh
    /bin/busybox --install -s
    rm -rf /sdrpp/tmp /sdrpp/sdrpp-muntz.sh
EOR
#####################################################################
# Ready for scratch.  We use scratch to clean up layer junk by just copying needed stuff into the install image.
#	Libraries are in /usr/lib
#	binaries and config files are in /sdrpp

FROM scratch AS install
COPY --from=dga-filesystem / /
EXPOSE 5259
WORKDIR /sdrpp
USER nobody
CMD ["/sdrpp/sdrpp.sh" ]
