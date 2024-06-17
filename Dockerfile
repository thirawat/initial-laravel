FROM php:8.3-fpm

RUN apt-get update && apt-get install -y libmcrypt-dev \
    cron zip unzip git wget libpq-dev libpng-dev \
    zlib1g-dev \
    libzip-dev \
    && docker-php-ext-install pdo_pgsql exif zip gd \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && pecl install pcov && docker-php-ext-enable pcov

RUN apt-get install supervisor -y
RUN mkdir -p /usr/share/man/man1
# RUN apt-get update -y && apt-get install -y default-jre

RUN apt-get install -y --no-install-recommends freetds-bin
RUN apt-get install -y --no-install-recommends freetds-dev
RUN apt-get install -y --no-install-recommends freetds-common
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/
RUN docker-php-ext-install pdo_dblib

RUN apt-get install -y --no-install-recommends nginx redis-server \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install redis && docker-php-ext-enable redis

WORKDIR /app

COPY . .

COPY docker-config/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker-config/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY docker-config/freetds.conf /etc/freetds/freetds.conf
COPY docker-config/laravel-worker.conf /etc/supervisor/conf.d/laravel-worker.conf
COPY docker-config/crontab /etc/cron.d/app-cron
COPY docker-config/timezone /etc/timezone
COPY docker-config/site.conf /etc/nginx/conf.d/default.conf
COPY docker-config/nginx.conf /etc/nginx/nginx.conf
COPY docker-config/redis.conf /etc/redis/redis.conf

RUN chown www-data:www-data -R /app 
RUN php composer.phar install
RUN php artisan key:generate

CMD ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]