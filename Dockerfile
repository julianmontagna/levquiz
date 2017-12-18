FROM php:7.1.12-apache

MAINTAINER Julian Montagna <julian.montagna@tooit.com>

ENV XDEBUG_VERSION=2.5.0 NODE_VERSION=4.4.7 GOPATH=/opt/go NVM_DIR=/usr/local/nvm
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:/usr/local/bin:/usr/bin:/var/www/html/vendor/bin:$PATH

# install php extensions
RUN set -ex \
  && systemDeps='htop git vim zip unzip rsyslog cron mysql-client wget golang-go libssl-dev libpcre3 libpcre3-dev' \
  && buildDeps='libjpeg62-turbo-dev libpng12-dev libpq-dev' \
  && phpDeps='gd mbstring opcache pdo pdo_mysql zip' \
  && apt-get update && apt-get install -y --no-install-recommends \
    $buildDeps \
    $systemDeps \
  && docker-php-ext-configure gd \
    --with-jpeg-dir=/usr \
    --with-png-dir=/usr \
  && docker-php-ext-install -j "$(nproc)" $phpDeps \
  && apt-mark manual \
    libjpeg62-turbo \
    libpq5 \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get purge -y --auto-remove $buildDeps \
  && a2enmod rewrite \
  && a2enmod expires \
  && a2enmod headers \
  && mkdir -p /opt/go

# install mhsendmail
RUN go get github.com/mailhog/mhsendmail

# install uploadprogress
RUN git clone https://github.com/Jan-E/uploadprogress.git /tmp/php-uploadprogress \
  && cd /tmp/php-uploadprogress \
  && phpize && ./configure --prefix=/usr && make && make install \
  && echo 'extension=uploadprogress.so' > /usr/local/etc/php/conf.d/uploadprogress.ini \
  && rm -rf /tmp/*

# install xdebug
RUN wget -c "http://xdebug.org/files/xdebug-$XDEBUG_VERSION.tgz" \
  && tar -xf xdebug-$XDEBUG_VERSION.tgz && cd xdebug-$XDEBUG_VERSION/ \
  && phpize && ./configure && make && make install \
  && echo 'zend_extension=xdebug.so' > /usr/local/etc/php/conf.d/xdebug.ini \
  && cd .. && rm -rf xdebug-$XDEBUG_VERSION/

# overwrite service settings
COPY ./etc/php/drupal.ini /usr/local/etc/php/conf.d/
COPY ./etc/apache/default.conf /etc/apache2/sites-available/000-default.conf

# install composer by using multi-stage builds (docker 17.04 and above)
COPY --from=composer:1.5 /usr/bin/composer /usr/bin/composer

# add a custom project's entrypoint
COPY ./etc/entrypoint.sh /entrypoint.sh
COPY ./etc/helpers.sh /helpers.sh
RUN chmod +x /entrypoint.sh /helpers.sh

# override any previous entrypoint
CMD ["/entrypoint.sh"]
