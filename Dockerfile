
# bump: ogg /OGG_VERSION=([\d.]+)/ https://github.com/xiph/ogg.git|*
# bump: ogg after ./hashupdate Dockerfile OGG $LATEST
# bump: ogg link "CHANGES" https://github.com/xiph/ogg/blob/master/CHANGES
# bump: ogg link "Source diff $CURRENT..$LATEST" https://github.com/xiph/ogg/compare/v$CURRENT..v$LATEST
ARG OGG_VERSION=1.3.5
ARG OGG_URL="https://downloads.xiph.org/releases/ogg/libogg-$OGG_VERSION.tar.gz"
ARG OGG_SHA256=0eb4b4b9420a0f51db142ba3f9c64b333f826532dc0f48c6410ae51f4799b664

# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.16.2 AS base

FROM base AS download
ARG OGG_URL
ARG OGG_SHA256
ARG WGET_OPTS="--retry-on-host-error --retry-on-http-error=429,500,502,503 -nv"
WORKDIR /tmp
RUN \
  apk add --no-cache --virtual download \
    coreutils wget tar && \
  wget $WGET_OPTS -O libogg.tar.gz "$OGG_URL" && \
  echo "$OGG_SHA256  libogg.tar.gz" | sha256sum --status -c - && \
  mkdir ogg && \
  tar xf libogg.tar.gz -C ogg --strip-components=1 && \
  rm libogg.tar.gz && \
  apk del download

FROM base AS build
COPY --from=download /tmp/ogg/ /tmp/ogg/
WORKDIR /tmp/ogg
RUN \
  apk add --no-cache --virtual build \
    build-base && \
  ./configure --disable-shared --enable-static && \
  make -j$(nproc) install && \
  apk del build

FROM scratch
ARG OGG_VERSION
COPY --from=build /usr/local/lib/pkgconfig/ogg.pc /usr/local/lib/pkgconfig/ogg.pc
COPY --from=build /usr/local/lib/libogg.a /usr/local/lib/libogg.a
COPY --from=build /usr/local/include/ogg/ /usr/local/include/ogg/
