FROM alpine:3.5

MAINTAINER Hex "hex@codeigniter.org.cn"

ARG SS_VER=3.0.6
ARG SS_URL=https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$SS_VER/shadowsocks-libev-$SS_VER.tar.gz

ARG KT_VER=20170329
ARG KT_URL=https://github.com/xtaci/kcptun/releases/download/v$KT_VER/kcptun-linux-amd64-$KT_VER.tar.gz

RUN set -ex && \
    apk add --no-cache s6 && \
    apk add --no-cache --virtual .build-deps \
                                autoconf \
                                build-base \
                                curl \
                                libev-dev \
                                libtool \
                                linux-headers \
                                udns-dev \
                                libsodium-dev \
                                mbedtls-dev \
                                pcre-dev \
                                tar \
                                udns-dev && \
    cd /tmp && \
    curl -sSL $SS_URL | tar xz --strip 1 && \
    ./configure --prefix=/usr --disable-documentation && \
    make install && \
    cd .. && \

    runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
    )" && \
    apk add --no-cache --virtual .run-deps $runDeps && \
    rm -rf /tmp/* && \

# kcptun
    cd /tmp && \
    curl -sSL $KT_URL | tar xz && \
    mv server_linux_amd64 /usr/bin/kcptun && \
    rm -rf /tmp/* && \

# strip
    strip -s /usr/bin/ss-server /usr/bin/kcptun && \

# clean
    apk del .build-deps && \
    rm -rf ss-local ss-manager ss-nat ss-redir ss-tunnel

COPY s6/ /etc/s6/

RUN chmod -R +x /etc/s6/* \
    && chmod +x /etc/s6/.s6-svscan/finish

EXPOSE 8388/tcp 29900/udp

ENTRYPOINT ["/bin/s6-svscan", "/etc/s6"]
