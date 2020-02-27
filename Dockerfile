FROM alpine

# Install packages from testing repo's
RUN apk --no-cache add php7 php7-fpm php7-mysqli php7-json php7-openssl php7-curl \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-xmlwriter \
    php7-simplexml php7-ctype php7-mbstring php7-gd ssmtp nginx supervisor curl bash less

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/zzz_custom.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini
RUN echo "sendmail_path = /usr/sbin/ssmtp -t" >> /etc/php7/conf.d/sendmail.ini
RUN echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# WordPress
ENV WORDPRESS_VERSION 5.3.2
ENV WORDPRESS_SHA1 fded476f112dbab14e3b5acddd2bcfa550e7b01b

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

# WP config
COPY --chown=nobody wordpress/wp-config.php /usr/src/wordpress
RUN chmod 640 /usr/src/wordpress/wp-config.php

# Append WP secrets
COPY --chown=nobody wordpress/wp-secrets.php /usr/src/wordpress
RUN chmod 640 /usr/src/wordpress/wp-secrets.php

# Add application
WORKDIR /var/www/html
COPY --chown=nobody wordpress/wp-content /var/www/html/wp-content/

# Change uploads folder permissions
RUN mkdir -p /var/www/html/wp-content/uploads && chmod 777 /var/www/html/wp-content/uploads

# Make the wordpress uploads a volume
VOLUME /var/www/html/wp-content/uploads

EXPOSE 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1/wp-login.php
