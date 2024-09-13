FROM php:8.2-fpm

RUN apt-get update -y
RUN apt-get -y install gcc make autoconf libc-dev pkg-config libzip-dev

RUN apt-get install -y --no-install-recommends \
	git \
	libz-dev \
	libpq-dev \
	libxml2-dev \
	libmemcached-dev \
	libldap2-dev libbz2-dev \
	zlib1g-dev libicu-dev g++ \
	libssl-dev libssl-doc libsasl2-dev \
	curl libcurl4-openssl-dev

RUN apt-get install -y --no-install-recommends \
	libgmp-dev firebird-dev libib-util

RUN apt-get install -y --no-install-recommends \
	re2c libpng++-dev libwebp-dev libjpeg-dev libjpeg62-turbo-dev libpng-dev libxpm-dev libvpx-dev libfreetype6-dev

RUN apt-get install -y --no-install-recommends \
	python3-lib2to3 libmagick++-dev libmagickwand-dev

RUN apt-get install -y --no-install-recommends \
	zlib1g-dev libgd-dev \
	unzip libpcre3 libpcre3-dev \
	sqlite3 libsqlite3-dev libxslt-dev \
	libtidy-dev libxslt1-dev libmagic-dev libexif-dev file \
	libmhash2 libmhash-dev libc-client-dev libkrb5-dev libssh2-1-dev \
	poppler-utils ghostscript libmagickwand-6.q16-dev libsnmp-dev libedit-dev libreadline6-dev libsodium-dev \
	freetds-bin freetds-dev freetds-common libct4 libsybdb5 tdsodbc libreadline-dev librecode-dev libpspell-dev libonig-dev

# issue on linux/amd64
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl && docker-php-ext-install imap

# fix for docker-php-ext-install pdo_dblib
# https://stackoverflow.com/questions/43617752/docker-php-and-freetds-cannot-find-freetds-in-know-installation-directories
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/
RUN docker-php-ext-install pdo_dblib

RUN docker-php-ext-install \
        dba \
        ldap \
        bcmath \
        bz2 \
        calendar \
        ctype \
        curl \
        dom \
        fileinfo \
        filter \
        exif \
        ftp \
        gettext \
        gmp \
        iconv \
        intl \
        mbstring \
        mysqli \
        opcache \
        pcntl \
        pspell \
        pdo_mysql \
        pdo_pgsql \
        pdo_sqlite \
        pgsql \
        phar \
        posix \
        session \
        shmop \
        simplexml \
        soap \
        sockets \
        sodium \
        sysvmsg \
        sysvsem \
        sysvshm \
        snmp \
        tidy \
        zip \
        xsl \
        xml


# install GD
RUN docker-php-ext-configure gd --with-jpeg --with-xpm --with-webp --with-freetype && \
	docker-php-ext-install -j$(nproc) gd

# build fails with spl
# RUN docker-php-ext-configure spl && docker-php-ext-install spl

# install pecl extension
RUN pecl install ds && docker-php-ext-enable ds
RUN pecl install memcached && docker-php-ext-enable memcached
RUN pecl install imagick && docker-php-ext-enable imagick
RUN pecl install igbinary && docker-php-ext-enable igbinary
RUN pecl install mongodb && docker-php-ext-enable mongodb
RUN pecl install apcu && docker-php-ext-enable apcu --ini-name docker-php-ext-10-apcu.ini
RUN yes "" | pecl install msgpack && docker-php-ext-enable msgpack

# install xdebug
# RUN pecl install xdebug && docker-php-ext-enable xdebug
RUN apt-get update -y && apt-get install -y apt-transport-https locales gnupg

# Install Supervisor
RUN apt-get install -y supervisor

# Create Supervisor directories
RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d

# Add Supervisor configuration
ADD ./configs/supervisord.conf /etc/supervisor/supervisord.conf

# install git
#RUN apt install -y git
#RUN apt-get update && apt-get install -y git

# install MSSQL support and ODBC driver
# RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
# 	curl https://packages.microsoft.com/config/debian/8/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
# 	export DEBIAN_FRONTEND=noninteractive && apt-get update -y && \
# 	ACCEPT_EULA=Y apt-get install -y msodbcsql unixodbc-dev
# RUN set -xe \
# 	&& pecl install pdo_sqlsrv \
# 	&& docker-php-ext-enable pdo_sqlsrv \
# 	&& apt-get purge -y unixodbc-dev && apt-get autoremove -y && apt-get clean

# set locale to utf-8
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

#--------------------------------------------------------------------------
# Final Touches
#--------------------------------------------------------------------------

# install required libs for health check
RUN apt-get -y install libfcgi0ldbl nano htop iotop lsof cron mariadb-client redis-tools wget

# install composer
RUN EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)" && \
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
	ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")" && \
	if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then >&2 echo 'ERROR: Invalid installer checksum' && exit 1; fi

RUN php composer-setup.php --quiet && rm composer-setup.php && \
	mv composer.phar /usr/local/sbin/composer && \
	chmod +x /usr/local/sbin/composer

# install SendGrid
RUN echo "postfix postfix/mailname string localhost" | debconf-set-selections && \
	echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && \
	DEBIAN_FRONTEND=noninteractive apt-get install postfix libsasl2-modules -y

# install NewRelic - issue on linux/arm/v7
RUN export NEW_RELIC_AGENT_VERSION=10.11.0.3 \
	&& curl -L https://download.newrelic.com/php_agent/archive/${NEW_RELIC_AGENT_VERSION}/newrelic-php5-${NEW_RELIC_AGENT_VERSION}-linux.tar.gz | tar -C /tmp -zx \
	&& export NR_INSTALL_USE_CP_NOT_LN=1 \
	&& export NR_INSTALL_SILENT=1 \
	&& /tmp/newrelic-php5-${NEW_RELIC_AGENT_VERSION}-linux/newrelic-install install \
	&& rm -rf /tmp/newrelic-php5-* /tmp/nrinstall*

# Set default work directory
ADD scripts/* /usr/local/bin/
RUN chmod +x  /usr/local/bin/*

# Add default configuration files
ADD configs/php.ini /usr/local/etc/php/
ADD configs/www.conf /usr/local/etc/php-fpm.d/

# Health check
RUN echo '#!/bin/bash' > /healthcheck && \
	echo 'env -i SCRIPT_NAME=/health SCRIPT_FILENAME=/health REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1' >> /healthcheck && \
	chmod +x /healthcheck

# Clean up
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /var/www/html
