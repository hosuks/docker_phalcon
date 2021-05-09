FROM ubuntu:16.04
MAINTAINER "Hoseok Kim" hosuks7@gmail.com

RUN apt-get update && apt-get -y install tzdata && apt-get install -y rdate
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV NGINX_VERSION 1.16.1
ENV PHP_VERSION 7.3.8
ENV PHP_XDEBUG_VERSION 2.7.2
ENV SRC_PATH /usr/local/src
WORKDIR $SRC_PATH

RUN apt-get update
RUN apt-get install -y gcc \
        make \
        autoconf \
        python-setuptools \
        git vim curl wget

ADD http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz .
ADD http://www.php.net/distributions/php-$PHP_VERSION.tar.gz .
ADD https://xdebug.org/files/xdebug-$PHP_XDEBUG_VERSION.tgz .

# Install Nginx
RUN apt-get install -y libpcre3-dev libssl-dev
RUN cd $SRC_PATH && \
    tar xvfz nginx-$NGINX_VERSION.tar.gz && \
    cd nginx-$NGINX_VERSION && \
    ./configure \
        --user=www --group=www \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --with-http_ssl_module \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --with-http_gzip_static_module && \
    make && make install

RUN apt-get install -y zip libzip-dev

# Install PHP
RUN apt-get install -y mariadb-client \
        libpng-dev \
        libmcrypt-dev \
        libxml2-dev \
		libcurl4-openssl-dev \
		pkg-config \
		libmariadb-client-lgpl-dev \
        libmysqlclient-dev
RUN cd $SRC_PATH && \
    tar xvfz php-$PHP_VERSION.tar.gz && \
    cd php-$PHP_VERSION && \
    ./configure \
        --prefix=/usr/local/php \
        --with-config-file-path=/usr/local/php/etc \
        --with-config-file-scan-dir=/usr/local/php/etc/php.d \
        --disable-debug \
        --enable-xml \
        --enable-fd-setsize=8192 \
        --enable-fpm \
        --enable-zip \
        --enable-mbstring \
        --enable-sockets \
        --with-fpm-user=www \
        --with-fpm-group=www \
        --with-config-file-path=/etc/ \
        --with-mysqli=/usr/bin/mysql_config \
        --with-libxml-dir=/usr/local/libxml \
        --with-mcrypt \
        --with-zlib \
        --with-curl \
        --with-iconv \
        --with-libdir=lib64 \
        --with-openssl \
        --with-gd \
        --with-pdo-mysql \
        --with-pdo-sqlite && \
    make && \
    make install && \
    ln -s /usr/local/php/bin/php /usr/bin/php && \
    ln -s /usr/local/php/bin/php-cgi /usr/bin/php-cgi && \
    ln -s /usr/local/php/bin/php-config /usr/bin/php-config && \
    ln -s /usr/local/php/bin/phpdbg /usr/bin/phpdbg && \
    ln -s /usr/local/php/bin/phpize /usr/bin/phpize


# supervisor
# RUN easy_install supervisor


# set directory and add user and Install PhalconPHP Framework
RUN mkdir -p /data/www && useradd -r -s /sbin/nologin -d /data/www -m -k no www && \
    cd $SRC_PATH && \
    git clone --branch v3.4.2 --depth=1 "git://github.com/phalcon/cphalcon.git" && \
    cd cphalcon/build && \
    ./install

# Install PhalconPHP-PSR
RUN git clone https://github.com/jbboehr/php-psr.git && \
    cd php-psr && \
    phpize && \
    ./configure && \
    make && \
    make test && \
    make install

################################
# application for development
################################
# Xdebug
RUN cd $SRC_PATH && \
    tar xvfz xdebug-$PHP_XDEBUG_VERSION.tgz && \
    cd xdebug-$PHP_XDEBUG_VERSION && \
    phpize && \
    ./configure && \
    make && \
    cp modules/xdebug.so $(find /usr/local/php/ -name 'no-debug*')

# Set env
COPY source/nginx/nginx.conf /usr/local/nginx/conf/
COPY source/php/php.ini /etc/
COPY source/php-fpm/php-fpm.conf /usr/local/php/etc/
COPY source/php-fpm/php-fpm.d/www.conf /usr/local/php/etc/php-fpm.d/
COPY source/supervisor/supervisord.conf /etc/supervisor/
COPY source/start.sh /

# for systemd
COPY source/systemd/system/* /lib/systemd/system/

RUN chmod 755 /start.sh

EXPOSE 80 443
VOLUME ["/home/httpd"]
CMD ["/start.sh"]
