# docker build -t tempered-webhook .
# docker run --rm --device=/dev/hidraw0:/dev/hidraw0 --device=/dev/hidraw1:/dev/hidraw1 --env WEBHOOK_URL=https://example.com/api/webhook/id tempered-webhook

FROM ubuntu:24.04 AS build

RUN apt update && apt dist-upgrade -y

RUN apt install -y git libudev-dev libusb-1.0-0-dev libfox-1.6-dev autotools-dev autoconf automake libtool
RUN git clone --depth 1 --branch hidapi-0.14.0 https://github.com/libusb/hidapi.git && cd hidapi && ./bootstrap && ./configure && make && make install

COPY TEMPered /home/pi/TEMPered
RUN apt install -y cmake
RUN cd /home/pi/TEMPered && make clean && make depend && make rebuild_cache && make depend && make && make install

FROM ubuntu:24.04 AS release

COPY --from=build /hidapi/linux/.libs/libhidapi-hidraw.so.0.0.0 /lib/libhidapi-hidraw.so.0
COPY --from=build /usr/local/lib/x86_64-linux-gnu/* /lib/
COPY --from=build /usr/local/bin/tempered /usr/local/bin/tempered

CMD ["tempered"]

FROM release AS script

RUN apt update && apt install -y curl && apt autoremove --purge && apt autoclean

COPY TEMPered.sh /TEMPered.sh

CMD ["/TEMPered.sh"]
