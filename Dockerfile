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
    strip -s /usr/bin/ss-server \
             /usr/bin/kcptun \
             /usr/lib/libev.so.4.0.0 \
             /usr/lib/libmbedcrypto.so.2.4.2 \
             /usr/lib/libmbedtls.so.2.4.2 \
             /usr/lib/libmbedx509.so.2.4.2 \
             /usr/lib/libpcre.so.1.2.7 \
             /usr/lib/libpcreposix.so.0.0.4 \
             /usr/lib/libsodium.so.18.1.1 \
             /usr/lib/libudns.so.0 \
             /lib/libexecline.so.2.2.0.0 \
             /lib/libs6.so.2.4.0.0 \
             /lib/libskarnet.so.2.4.0.2 && \

# clean
    apk del .build-deps && \
    rm -rf /usr/bin/ss-local \
           /usr/bin/ss-manager \
           /usr/bin/ss-nat \
           /usr/bin/ss-redir \
           /usr/bin/ss-tunnel \
           /usr/lib/libshadowsocks-libev.a \
           /usr/include/*

COPY s6/ /etc/s6/

RUN chmod -R +x /etc/s6/* \
    && chmod +x /etc/s6/.s6-svscan/finish

EXPOSE 8388/tcp 29900/udp

ENTRYPOINT ["/bin/s6-svscan", "/etc/s6"]
