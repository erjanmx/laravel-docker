FROM php:7.2-apache

RUN apt-get update && apt-get install -y \
  git-core \
  ssh-client \
  unzip \
  libtool apache2-dev \
  --no-install-recommends && rm -r /var/lib/apt/lists/*

# Install composer bin to /usr/local/bin
RUN curl -sS https://getcomposer.org/installer | \
  php -- --install-dir=/usr/local/bin --filename=composer

# https://github.com/vishnubob/wait-for-it
#COPY contrib/wait-for-it.sh /usr/local/bin/
#RUN chmod +x /usr/local/bin/wait-for-it.sh

RUN docker-php-ext-install pdo_mysql

# Apache
COPY contrib/php.ini              $PHP_INI_DIR/conf.d/php.ini
COPY contrib/000-default.conf     $APACHE_CONFDIR/sites-enabled/000-default.conf
COPY contrib/mod_log_post.so /usr/lib/apache2/modules/

RUN curl -o /tmp/mod_cloudflare.c https://www.cloudflare.com/static/misc/mod_cloudflare/mod_cloudflare.c && \
    apxs -a -i -c /tmp/mod_cloudflare.c && \
    rm -f /tmp/mod_cloudflare.c

RUN a2enmod rewrite

# App folders
RUN mkdir /app /app/vendor /app/src
WORKDIR /app/src

# Composer
ENV COMPOSER_VENDOR_DIR /app/vendor
COPY composer.json composer.lock /app/src/
RUN composer install --no-scripts --no-autoloader --no-interaction

ENV PATH "/app/vendor/bin:$PATH"

COPY . ./

RUN chgrp -R www-data storage bootstrap/cache && \
    chmod -R ug+rwx storage bootstrap/cache

RUN composer dump-autoload --optimize && \
    composer run-script post-create-project-cmd

EXPOSE 80
