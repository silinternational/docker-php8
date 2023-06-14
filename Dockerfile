FROM silintl/ubuntu:22.04
LABEL maintainer="jason_jackson@sil.org"

ENV REFRESHED_AT 2022-05-23
ENV HTTPD_PREFIX /etc/apache2
ENV DEBIAN_FRONTEND noninteractive

# Install OS packages
# Specific php versions are not required as ubuntu is feature complete
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    libapache2-mod-php \
    nano \
    netcat \
    php \
    php-cli \
    php-curl \
    php-dom \
    php-intl \
    php-ldap \
    php-mbstring \
    php-mysql \
    php-sqlite3 \
    php-gmp \
    php-zip \
    s3cmd \
    unzip \
    zip \
    # Force security upgrades
    openssl \
    libssl3 \
    apache2 \
    && phpenmod mcrypt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Install whenavail
RUN curl -o /usr/local/bin/whenavail https://bitbucket.org/silintl/docker-whenavail/raw/1.0.2/whenavail \
    && chmod a+x /usr/local/bin/whenavail

# Remove default site, configs, and mods not needed
WORKDIR $HTTPD_PREFIX
RUN a2dissite 000-default
RUN a2disconf serve-cgi-bin
### WARNING: The following essential module will be disabled.
### This might result in unexpected behavior and should NOT be done
### unless you know exactly what you are doing!
RUN a2dismod autoindex -f

# Enable additional configs and mods
RUN a2enmod expires headers rewrite

# Remove default ssl key
RUN rm /etc/ssl/private/*

# Copy in any additional PHP ini files to the folders where they will be found.
COPY conf/*.ini /etc/php/8.1/apache2/conf.d/
COPY conf/*.ini /etc/php/8.1/cli/conf.d/

COPY vhost.conf /etc/apache2/sites-enabled/

EXPOSE 80

# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND
