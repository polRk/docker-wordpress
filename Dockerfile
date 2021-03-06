FROM alpine

# Install packages from testing repo's
RUN apk --no-cache add php7 php7-fpm php7-mysqli php7-json php7-openssl php7-curl php7-gd \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-xmlwriter php7-mbstring \
    php7-exif php7-fileinfo php7-imagick php7-zip php7-iconv php7-simplexml php7-ctype php7-mcrypt \
    nginx supervisor msmtp curl bash less && \
    rm -rf /var/cache/apk/*

# Install WordPress
ENV WORDPRESS_VERSION 5.4
ENV WORDPRESS_SHA1 d5f1e6d7cadd72c11d086a2e1ede0a72f23d993e

RUN mkdir -p /usr/src

# Upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
	&& echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
	&& tar -xzf wordpress.tar.gz -C /usr/src/ \
	&& rm wordpress.tar.gz \
	&& chown -R nobody.nobody /usr/src/wordpress

# Add WP CLI
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Add application
WORKDIR /var/www/html
COPY --chown=nobody wordpress/wp-content /var/www/html/wp-content/

# Add WP config
COPY --chown=nobody wordpress/wp-config.php /usr/src/wordpress
RUN chmod 640 /usr/src/wordpress/wp-config.php

# Add WP secrets
COPY --chown=nobody wordpress/wp-secrets.php /usr/src/wordpress
RUN chmod 640 /usr/src/wordpress/wp-secrets.php

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/zzz_custom.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Configure sendmail
COPY config/sendmail.ini /etc/php7/conf.d/sendmail.ini

# Change uploads folder permissions
RUN mkdir -p /var/www/html/wp-content/uploads && \
    chown nobody:nobody /var/www/html/wp-content/uploads

# Make the wordpress uploads a volume
VOLUME /var/www/html/wp-content/uploads

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
