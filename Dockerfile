FROM alpine:3.6

# Laravel users: Don't put `php artisan config:cache` in the Dockerfile as it
# prevents the app from reading ENV vars at runtime.

ENV TZ=Asia/Tehran \
    # You can find the php5 packages here: http://dl-cdn.alpinelinux.org/alpine/v3.6/community/x86_64/
    ADDITIONAL_PACKAGES="php5-pdo_pgsql php5-pdo_mysql php5-mcrypt php5-curl php5-gd php5-soap" \
    PHP_MEMORY_LIMIT=2048M \
    PHP_UPLOAD_MAX_SILE_SIZE=50M \
    MAGENTO_VERSION="1.9.2.4" \
    PHP_POST_MAX_SIZE=50M

RUN apk update && \
    # Install required packages - you can find any additional packages here: https://pkgs.alpinelinux.org/packages
    apk add tzdata curl bash ca-certificates rsync supervisor nginx nano \
            php5 php5-fpm php5-common php5-openssl php5-bcmath \
            php5-dom php5-cli php5-pdo php5-json php5-phar \
            php5-iconv php5-zlib php5-ctype php5-xml ${ADDITIONAL_PACKAGES} && \
    # Fix PHP paths
    ln -sf /usr/bin/php5 /usr/bin/php && \
    # Install composer
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/bin/composer && \
    # Set the timezone
    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone && \
    # Set the nginx config
    sed -i "/user nginx;/c #user nginx;" /etc/nginx/nginx.conf && \
    # Set php.ini config
    sed -i "/date.timezone =/c date.timezone = ${TZ}"                                    /etc/php5/php.ini && \
    sed -i "/memory_limit = /c memory_limit = ${PHP_MEMORY_LIMIT}"                       /etc/php5/php.ini && \
    sed -i "/upload_max_filesize = /c upload_max_filesize = ${PHP_UPLOAD_MAX_SILE_SIZE}" /etc/php5/php.ini && \
    sed -i "/post_max_size = /c post_max_size = ${PHP_POST_MAX_SIZE}"                    /etc/php5/php.ini && \
    # Set www conf
    sed -i "/listen.owner = /c listen.owner = root" /etc/php5/php-fpm.conf && \
    sed -i "/listen = /c listen = 127.0.0.1:9000"   /etc/php5/php-fpm.conf && \
    sed -i "/;clear_env = /c clear_env = no"        /etc/php5/php-fpm.conf && \
    # Setup permissions
    mkdir -p /.composer /.config /run/nginx /var/lib/nginx/logs && \
    chmod -R g+rws,a+rx /.composer /.config /var/log /var/run /var/tmp /run/nginx /var/lib/nginx && \
    chown -R 1001:0     /.composer /.config /var/log /var/run /var/tmp /run/nginx /var/lib/nginx && \
    # Log aggregation
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    # Clean up packages
    apk del tzdata && \
    rm -rf /var/cache/apk/*

EXPOSE 8080
WORKDIR /var/www

COPY supervisord.conf /
COPY nginx.conf /etc/nginx/conf.d/default.conf
# COPY composer.json composer.lock ./
# RUN composer install --no-scripts --no-autoloader --prefer-dist --no-dev --working-dir=/var/www

RUN mkdir /var/www/public && \
    curl https://codeload.github.com/OpenMage/magento-mirror/tar.gz/$MAGENTO_VERSION -o $MAGENTO_VERSION.tar.gz && \
    tar xvf $MAGENTO_VERSION.tar.gz && \
    mv magento-mirror-$MAGENTO_VERSION/* magento-mirror-$MAGENTO_VERSION/.htaccess /var/www/public

# Copy the app files
COPY . /tmp/app
RUN chmod -R g+w /tmp/app && \
    chown -R 1001:0 /tmp/app && \
    cp -a /tmp/app/. /var/www && \
    rm -rf /tmp/app && \
    # composer dump-autoload --optimize && \
    chmod +x /var/www/start.sh

CMD ["./start.sh"]
USER 1001
