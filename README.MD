# php docker image

Based on php 7.2 (7.2.8)

## Ext
* ext-amqp
* intl (ICU 61.1)
* gd
* imagick 3.4.3
* xdebug 2.6.0beta1
* pdo mysql
* opcache
* bcmath
* bz2
* pcntl
* zip
* exif

## Extras
* composer
* composer plugin `hirak/prestissimo:^0.3`

## Tools
* supervisor
* cron
* nano
* git

## php.ini
* memory_limit=-1
* date.timezone=Europe/Moscow
* max upload 50m
* expose_php=0


