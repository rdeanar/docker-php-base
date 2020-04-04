# php docker image

Based on php 7.4 fpm (7.4.4)

## Ext
* memcached
* intl (ICU 64.2)
* gd
* imagick 3.4.4
* xdebug 2.9.0
* pdo mysql
* opcache
* bcmath
* bz2
* pcntl
* zip
* exif
* apcu

## Extras
* composer
* composer plugin `hirak/prestissimo:^0.3`

## Tools
* supervisor
* cron
* nano
* vim
* git
* unzip

## php.ini
* memory_limit=-1
* date.timezone=Europe/Moscow
* max upload 50m
* expose_php=0


