# Use Alpine as a build environment
FROM alpine:latest as build

# Update package repository and install necessary dependencies
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        git \
        linux-headers \
        alpine-sdk \
        cmake \
        tcl \
        openssl-dev \
        zlib-dev

# Set the working directory to /tmp
WORKDIR /tmp

# Clone the required repositories
RUN git clone  https://github.com/irlserver/srtla.git && \
    git clone  https://github.com/irlserver/srt.git && \
    git clone  https://github.com/irlserver/irl-srt-server.git srt-live-server

# Switch to the srt repository directory
WORKDIR /tmp/srt

# Checkout the master branch and build and install srt library
RUN ./configure && \
    make -j8 && \
    make install

# Switch to the srtla repository directory
WORKDIR /tmp/srtla

# Checkout the master branch and build srtla library
RUN git submodule update --init && \
    mkdir build && cd build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make -j8
RUN find /tmp/srtla/build -name srtla_rec

# Switch to the sls repository directory
WORKDIR /tmp/srt-live-server

RUN git submodule update --init && \
    mkdir build && cd build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make -j8

# Checkout the master branch and build sls library
#RUN git checkout master && \
#    make -j8


# Use Alpine Linux as the final base image
FROM alpine:latest

# Set environment variables
ENV LD_LIBRARY_PATH /lib:/usr/lib:/usr/local/lib64

# Update package repository and install necessary dependencies
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        supervisor \
        openssl \
		bash \
        libstdc++

# Add a user for running the application
RUN mkdir /etc/sls /logs

# Copy necessary files and directories from the build stage
COPY --from=build /usr/local/bin/srt-* /usr/local/bin/
COPY --from=build /usr/local/lib/libsrt* /usr/local/lib/
#COPY --from=build /tmp/srt-live-server/bin/* /usr/local/bin/
COPY --from=build /tmp/srt-live-server/build/bin/* /usr/local/bin/
COPY --from=build /tmp/srt/srt-live-transmit /usr/local/bin/srt-live-transmit
COPY --from=build /tmp/srt/srt-tunnel /usr/local/bin/srt-tunnel
#COPY --from=build /tmp/srtla/srtla_rec /usr/local/bin/srtla_rec
COPY --from=build /tmp/srtla/build/srtla_rec /usr/local/bin/srtla_rec

# Copy the sls.conf file to /etc/sls directory
#COPY --from=build /tmp/srt-live-server/sls.conf /etc/sls/
COPY files/sls.conf /etc/sls/sls.conf

# Create a volume for logs
VOLUME /logs

# Environment Variables
ENV SRTLA_PORT          5000

ENV SLS_HTTP_PORT       8181
ENV SLS_SRT_PORT        30000
ENV SLS_SRTLA_PORT      5002
ENV SLS_DEFAULT_SID     live/feed1
ENV SLS_SRT_LATENCY     1000
ENV SLS_SRT_TIMEOUT     -1

ENV SLS_SRT_LATENCY     1000
ENV SLT_SRT_LOSSMAXTTL  40

# Expose ports
EXPOSE $SLS_HTTP_PORT/tcp $SRTLA_PORT/udp $SLS_SRT_PORT/udp

# Set working dir to /opt
WORKDIR /opt

# Copy necessary configurations and scripts
COPY files/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY files/supervisord.conf /etc/supervisor/supervisord.conf
COPY files/logprefix /usr/local/bin/logprefix
COPY files/restart_all_on_exit /usr/local/bin/restart_all_on_exit

# Ensure the scripts are executable
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/logprefix /usr/local/bin/restart_all_on_exit

# Set the entrypoint to entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
