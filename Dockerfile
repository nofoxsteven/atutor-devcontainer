FROM docker.io/library/ubuntu:jammy as base

RUN apt-get update && \
 apt-get full-upgrade -y && \
 apt-get install -y software-properties-common

RUN export DEBIAN_FRONTEND=noninteractive && \
 add-apt-repository ppa:ondrej/php && \
 add-apt-repository ppa:ondrej/apache2 && \
 apt-get update && \
 apt-get install -y apache2 libapache2-mod-php5.6 php5.6 php5.6-mysql php5.6-xdebug php5.6-gd php5.6-mbstring php5.6-curl

# https://github.com/docker-library/php/tree/master/8.2/bullseye/apache
FROM docker.io/library/php:apache as php
FROM base as app

RUN mkdir /workspace && rm -rf /var/www/html && ln -sf /workspace/src /var/www/html

RUN ln -sfT /dev/stderr /var/log/apache2/error.log && \
	ln -sfT /dev/stdout /var/log/apache2/access.log && \
	ln -sfT /dev/stdout /var/log/apache2/other_vhosts_access.log

COPY php.ini /etc/php/5.6/apache2/conf.d/php.ini
COPY --from=php /usr/local/bin/apache2-foreground /usr/local/bin/
COPY --from=php /usr/local/bin/docker-php-entrypoint /usr/local/bin/
COPY --from=php /etc/apache2/conf-available/docker-php.conf /etc/apache2/conf-available/

RUN a2dismod mpm_event && a2enmod mpm_prefork
RUN a2enconf docker-php

ENTRYPOINT ["docker-php-entrypoint"]
STOPSIGNAL SIGWINCH

WORKDIR /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
