FROM jsurf/rpi-raspbian:latest
MAINTAINER Wouter De Schuyter <wouter.de.schuyter@gmail.com>

# Enable cross build for automated builds
RUN [ "cross-build-start" ]

# PHP Version
ENV PHP_VERSION 7.0.0

# Build path
ENV BPATH /usr/local/src/php

RUN apt-get update;

RUN apt-get install -y --no-install-recommends \
    wget \
    bison \
    autoconf \
    pkg-config \
    build-essential;

RUN apt-get install -y --no-install-recommends \
    libssl-dev \
    libltdl-dev \
    libbz2-dev \
    libxml2-dev \
    libxslt1-dev \
    libpspell-dev \
    libenchant-dev \
    libmcrypt-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libmysqlclient-dev \
    libcurl4-openssl-dev;

RUN mkdir --parents /usr/local/php \
    && mkdir --parents /etc/php/conf.d \
    && mkdir --parents /etc/php/cli/conf.d \
    && mkdir --parents /etc/php/fpm/conf.d \
    && mkdir --parents --mode=777 /var/log/php;

RUN wget --show-progress https://github.com/php/php-src/archive/php-$PHP_VERSION.tar.gz \
    && tar xzf php-$PHP_VERSION.tar.gz \
    && rm php-$PHP_VERSION.tar.gz \
    && mv php-src-php-$PHP_VERSION $BPATH;

RUN cd $BPATH \
    && ./buildconf --force \
    && php_configure_args=" \
        --prefix=/usr/local/php \
        \
        --with-bz2 \
        --with-zlib \
        --enable-zip \
        \
        --with-mcrypt \
        --with-openssl \
        \
        --with-curl \
        --enable-ftp \
        --with-mysqli \
        --enable-sockets \
        --enable-pcntl \
        \
        --with-pspell \
        --with-enchant \
        --with-gettext \
        \
        --with-gd \
        --enable-exif \
        --with-jpeg-dir \
        --with-png-dir \
        --with-freetype-dir \
        \
        --with-xsl \
        --enable-bcmath \
        --enable-mbstring \
        --enable-calendar \
        \
        --enable-sysvmsg \
        --enable-sysvsem \
        --enable-sysvshm \
        ";

RUN cd $BPATH \
    && ./configure $php_configure_args \
        --with-config-file-path=/etc/php/cli \
        --with-config-file-scan-dir=/etc/php/cli/conf.d \
    && make && make install && make clean;

RUN cd $BPATH \
    && ./configure $php_configure_args \
        --disable-cli --enable-fpm \
        --with-fpm-user=www-data \
        --with-fpm-group=www-data \
        --with-config-file-path=/etc/php/fpm \
        --with-config-file-scan-dir=/etc/php/fpm/conf.d \
    && make && make install && make clean;

RUN cd /usr/local/etc \
    && if [ -d php-fpm.d ]; then \
        cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
       fi;

RUN ln --symbolic /usr/local/php/bin/php /usr/bin/php \
    && ln --symbolic /usr/local/php/sbin/php-fpm /usr/sbin/php-fpm \
    && echo 'zend_extension=opcache.so' > /etc/php/conf.d/opcache.ini \
    && ln --symbolic /etc/php/conf.d/opcache.ini /etc/php/cli/conf.d/opcache.ini \
    && ln --symbolic /etc/php/conf.d/opcache.ini /etc/php/fpm/conf.d/opcache.ini;

RUN apt-get remove --purge -y \
        wget \
        bison \
        autoconf \
        pkg-config \
        build-essential \
    && apt-get autoremove --purge -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf $BPATH;

# Disable cross build again
RUN [ "cross-build-end" ]

# Exposed ports
EXPOSE 9000

CMD ["php-fpm"]
