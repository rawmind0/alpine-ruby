FROM rawmind/alpine-monit:5.25-0
MAINTAINER Raul Sanchez <rawmind@gmail.com>

# Set environment
ENV RUBY_MAJOR=2.5 \
    RUBY_VERSION=2.5.1 \
    RUBY_HOME=/opt/ruby \
    RUBY_SRC=/opt/src \
    RUBY_URL=https://cache.ruby-lang.org/pub/ruby \
    BUNDLE_HOME=/opt/ruby/bundle \
    RUBY_DOWNLOAD_SHA256=886ac5eed41e3b5fc699be837b0087a6a5a3d10f464087560d2d21b3e71b754d \
    RUBYGEMS_VERSION=2.7.6 \
    BUNDLER_VERSION=1.16.2
ENV BUNDLE_PATH=${BUNDLE_HOME} \
    BUNDLE_BIN=${BUNDLE_HOME}/bin \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG=${BUNDLE_HOME} \
    RUBY_BIN=${RUBY_HOME}/bin \
    PATH=$PATH:${RUBY_HOME}/bin:${BUNDLE_HOME}/bin

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
# readline-dev vs libedit-dev: https://bugs.ruby-lang.org/issues/11869 and https://github.com/docker-library/ruby/issues/75
RUN set -ex \
    \
    && mkdir -p ${RUBY_HOME}/etc ${BUNDLE_BIN} ${RUBY_SRC} \
    && chmod 777 ${BUNDLE_BIN} \
    && { \
        echo 'install: --no-document'; \
        echo 'update: --no-document'; \
      } >> ${RUBY_HOME}/etc/gemrc \
    && apk add --no-cache --virtual .ruby-builddeps \
        autoconf \
        bison \
        bzip2-dev \
        coreutils \
        dpkg-dev dpkg \
        gcc \
        gdbm-dev \
        glib-dev \
        libc-dev \
        libffi-dev \
        libressl-dev \
        libxml2-dev \
        libxslt-dev \
        linux-headers \
        make \
        ncurses-dev \
        readline-dev \
        ruby \
        tar \
        xz \
        yaml-dev \
        zlib-dev \
    \
    && cd ${RUBY_SRC} \
    && wget -O ruby.tar.xz "${RUBY_URL}/${RUBY_MAJOR%-rc}/ruby-${RUBY_VERSION}.tar.xz" \
    && echo "${RUBY_DOWNLOAD_SHA256} *ruby.tar.xz" | sha256sum -c - \
    \
    && tar -xJf ruby.tar.xz -C ${RUBY_SRC} --strip-components=1 \
    && rm ruby.tar.xz \
    \
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
    && { \
        echo '#define ENABLE_PATH_CHECK 0'; \
        echo; \
        cat file.c; \
    } > file.c.new \
    && mv file.c.new file.c \
    \
    && autoconf \
# the configure script does not detect isnan/isinf as macros
    && export ac_cv_func_isnan=yes ac_cv_func_isinf=yes \
    && ./configure \
        --prefix=${RUBY_HOME} \
        --exec-prefix=${RUBY_HOME} \
        --disable-install-doc \
        --enable-shared \
    && make -j "$(nproc)" \
    && make install \
    \
    && runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive ${RUBY_HOME} \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e ${RUBY_HOME}/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" \
    && apk add --no-cache --virtual .ruby-rundeps $runDeps \
        bzip2 \
        libffi \
        procps \
        yaml \
        zlib \
    && apk del .ruby-builddeps \
    && cd ${RUBY_HOME} \
    && rm -r ${RUBY_SRC} \
    \
    && gem update --system "$RUBYGEMS_VERSION" \
    && gem install bundler --version "$BUNDLER_VERSION" --force \
    && rm -r /root/.gem/


