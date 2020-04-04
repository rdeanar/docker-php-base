FROM php:7.4.4-fpm

# Allow Composer to be run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

# term fix
ENV TERM xterm

# Github api token for composer
ENV GITHUB_API_TOKEN c2cf68f5ea048f440ec451af81068798f2c02fdb
# PHP_CPPFLAGS are used by the docker-php-ext-* scripts
ENV PHP_CPPFLAGS="$PHP_CPPFLAGS -std=c++11"

RUN set -ex; \
	apt-get update; \
    apt-get -y install \
            build-essential \
            libcurl4-openssl-dev \
            automake \
            libtool \

            mariadb-client \
            supervisor \
            vim \
            nano \
            cron \

            # imagick
            libmagickwand-dev \
            libmagickwand-6.q16-6 \

            # GD
            libfreetype6-dev \
            libjpeg62-turbo-dev \

            # memcache
            libmemcached-dev \
            libmemcached11 \

            # for mcrypt
            libmcrypt-dev \
            libltdl7 \

            # required by composer
            git \
            unzip \
            zlib1g-dev \
            libzip-dev \

            # Fix terminal init size
            xterm \
        --no-install-recommends \


# PHP extension

    # build ICU from sources (for intl ext)
    # https://netcologne.dl.sourceforge.net/project/icu/ICU4C/64.2/icu4c-64_2-src.tgz
    && curl -fsS -o /tmp/icu.tgz -L http://download.icu-project.org/files/icu4c/64.2/icu4c-64_2-src.tgz \ 
    && tar -zxf /tmp/icu.tgz -C /tmp \
    && cd /tmp/icu/source \
    && ./configure --prefix=/usr/local \
    && make \
    && make install \
    # just to be certain things are cleaned up
    && rm -rf /tmp/icu* \

    # Intl configure and install
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \

    # memcached
    && pecl install memcached && docker-php-ext-enable memcached \

    # GD
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd \

    # imagick
    && pecl install imagick-3.4.4 && docker-php-ext-enable imagick \

    # xdebug
    && pecl install xdebug-2.9.0 && docker-php-ext-enable xdebug \

    # apcu
    && pecl install apcu && docker-php-ext-enable apcu \

    # pdo opcache bcmath bz2 pcntl exif zip (required by composer)
    && docker-php-ext-install -j$(nproc) pdo_mysql opcache bcmath bz2 pcntl exif zip  \

# Cleanup to keep the images size small
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
    && echo "expose_php=0" > "$PHP_INI_DIR/conf.d/expose_php.ini"\
    # Fix terminal init size
    && echo "\n\neval \$(resize)\n" >> /root/.bashrc


ENV PATH="${PATH}:/root/.composer/vendor/bin"
