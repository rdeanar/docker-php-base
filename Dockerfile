FROM php:7.2-fpm

# Allow Composer to be run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

# term fix
ENV TERM xterm

# Github api token for composer
ENV GITHUB_API_TOKEN c2cf68f5ea048f440ec451af81068798f2c02fdb
# PHP_CPPFLAGS are used by the docker-php-ext-* scripts
ENV PHP_CPPFLAGS="$PHP_CPPFLAGS -std=c++11"
# Version of rabbitmq_c lib
ENV RABBITMQ_C_VERSION 0.8.0

RUN set -ex; \
	apt-get update; \
    apt-get -y install \
            build-essential \
            libcurl4-openssl-dev \
            automake \
            libtool \

            mysql-client \
            supervisor \
            nano \
            cron \

            # imagick
            libmagickwand-dev \
            libmagickwand-6.q16-3 \

            # GD
            libfreetype6-dev \
            libjpeg62-turbo-dev \

            # for mcrypt
            libmcrypt-dev \
            libltdl7 \

            # required by composer
            git \
            zlib1g-dev \

            # php-ext-amqp
            gcc make pkg-config librabbitmq-dev \
        --no-install-recommends \


# PHP extension

    # amqp
    && curl -L -o /tmp/rabbitmq.tar.gz https://github.com/alanxz/rabbitmq-c/releases/download/v$RABBITMQ_C_VERSION/rabbitmq-c-$RABBITMQ_C_VERSION.tar.gz \
     && tar xfz /tmp/rabbitmq.tar.gz \
      && rm -r /tmp/rabbitmq.tar.gz \
       && cd rabbitmq-c-$RABBITMQ_C_VERSION \
        && ./configure \
         && make \
          && make install \

    #RUN if [ -z `php -m | grep -i "amqp"` ];then  \
    && pecl install amqp && docker-php-ext-enable amqp \
    #;fi

    # build ICU 61.1 from sources (for intl ext)
    && curl -fsS -o /tmp/icu.tgz -L http://download.icu-project.org/files/icu4c/61.1/icu4c-61_1-src.tgz \
    && tar -zxf /tmp/icu.tgz -C /tmp \
    && cd /tmp/icu/source \
    && ./configure --prefix=/usr/local \
    && make \
    && make install \
    # just to be certain things are cleaned up
    && rm -rf /tmp/icu* \

    # Intl configure and install
    && docker-php-ext-configure intl --with-icu-dir=/usr/local \
    && docker-php-ext-install intl \

    # GD
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \

    # imagick
    && pecl install imagick-3.4.3 && docker-php-ext-enable imagick \

    # xdebug
    && pecl install xdebug-2.6.0beta1 && docker-php-ext-enable xdebug \

    # pdo opcache bcmath mcrypt bz2 pcntl sockets
    && docker-php-ext-install -j$(nproc) pdo_mysql opcache bcmath bz2 pcntl \

    # zip (required by composer)
    && docker-php-ext-install -j$(nproc) zip \

# Cleanup to keep the images size small
&&  apt-get purge -y \
        zlib1g-dev \
    && apt-get autoremove -y \
    && rm -r /var/lib/apt/lists/* \

    # Create base directory
    && mkdir -p /var/www/html

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN composer config -g github-oauth.github.com "$GITHUB_API_TOKEN" \
    && composer global require "hirak/prestissimo:^0.3" --prefer-dist --no-progress --no-suggest --classmap-authoritative \
    && composer clear-cache \

&& echo "memory_limit=-1" > "$PHP_INI_DIR/conf.d/memory-limit.ini" \
    && echo "date.timezone=${PHP_TIMEZONE:-Europe/Moscow}" > "$PHP_INI_DIR/conf.d/date_timezone.ini"  \
    && echo "post_max_size=50M\nupload_max_filesize=50M" > "$PHP_INI_DIR/conf.d/upload.ini" \
    && echo "expose_php=0" > "$PHP_INI_DIR/conf.d/expose_php.ini"


ENV PATH="${PATH}:/root/.composer/vendor/bin"
