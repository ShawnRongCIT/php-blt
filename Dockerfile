FROM php:7.4

LABEL maintainer="shawnr@ciandt.com"

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN mkdir -p /usr/share/man/man1 && \
  apt-get update -y

# Install dependencies
RUN set -ex \
  && apt-get update -yqq \
  && apt-get install -yqq \
  git \
  unzip \
  wget \
  curl \
  rsync \
  libmcrypt-dev \
  libgd-dev \
  libbz2-dev \
  libzip-dev \
  libcurl4-openssl-dev \
  libonig-dev \
  openssh-client \
  libmagickwand-dev \
  default-mysql-client \
  default-libmysqlclient-dev \
  gnupg \
  ca-certificates \
  apt-transport-https \
  ttf-wqy-zenhei \
  imagemagick \
  procps \
  # Install NodeJS & NPM
  && curl -sL https://deb.nodesource.com/setup_11.x | bash - \
  && apt-get install -y nodejs \
  # Install requred PHP extensions.
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j$(nproc) bz2 gd pdo_mysql curl mbstring opcache zip \
  && pecl install xdebug imagick \
  # Install composer
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
  # Add composer dependencies
  && composer global require "hirak/prestissimo:^0.3" \
  # Remove unwanted packages.
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

# Add default user `docker` and modify user id and group id
RUN groupadd -r -g 1001 docker && useradd --no-log-init -r -u 1000 -g docker docker \
  && echo '#!/bin/bash\nset -e\n\
[[ $(id -u docker) != ${CURRENT_USER_UID:-1000} ]] && usermod -u ${CURRENT_USER_UID:-1000} docker\n\
[[ $(id -g docker) != ${CURRENT_USER_GID:-1001} ]] && groupmod -g ${CURRENT_USER_GID:-1001} docker\n\
chown -R docker:docker /var/www/html' > /start.sh && chmod 755 /start.sh && /start.sh

CMD ["php", "-a"]
