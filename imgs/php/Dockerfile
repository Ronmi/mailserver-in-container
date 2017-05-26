FROM php:7-fpm
MAINTAINER Ronmi Ren <ronmi@shoutloud.top>

RUN docker-php-ext-install mysqli pdo pdo_mysql

RUN apt-get update \
 && apt-get install -y libc-client-dev libkrb5-dev dovecot-core \
 && rm -r /var/lib/apt/lists/* \
 && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
 && docker-php-ext-install imap
