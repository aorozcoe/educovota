FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl zip unzip libicu-dev libzip-dev libpng-dev libjpeg-dev libfreetype6-dev \
    nodejs npm nginx supervisor \
    && docker-php-ext-install intl zip pdo pdo_mysql bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy composer files and install dependencies
COPY composer.json composer.lock ./
RUN composer install --optimize-autoloader --no-scripts --no-interaction --no-dev

# Copy package files and install node dependencies
COPY package.json package-lock.json ./
RUN npm install

# Copy the rest of the application
COPY . .

# Create required Laravel directories
RUN mkdir -p storage/framework/sessions \
    storage/framework/views \
    storage/framework/cache \
    storage/logs \
    bootstrap/cache

# Set permissions
RUN chmod -R 775 storage bootstrap/cache
RUN chown -R www-data:www-data storage bootstrap/cache

# Run composer scripts (publishes Filament assets, discovers packages)
# Use a temporary APP_KEY for artisan commands during build (no DB needed)
RUN composer dump-autoload --optimize \
    && APP_KEY=base64:dGVtcG9yYXJ5LWtleS1mb3ItYnVpbGQtMDAwMDA= php artisan package:discover --ansi \
    && APP_KEY=base64:dGVtcG9yYXJ5LWtleS1mb3ItYnVpbGQtMDAwMDA= php artisan filament:upgrade

# Build frontend assets
RUN npm run build

# Nginx configuration
RUN rm /etc/nginx/sites-enabled/default
COPY docker/nginx.conf /etc/nginx/sites-enabled/default

# PHP-FPM configuration - listen on socket for nginx
RUN sed -i 's|listen = 9000|listen = /run/php-fpm.sock|' /usr/local/etc/php-fpm.d/zz-docker.conf \
    && echo "listen.owner = www-data" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "listen.group = www-data" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "listen.mode = 0660" >> /usr/local/etc/php-fpm.d/www.conf

# Supervisor configuration
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy entrypoint script
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

EXPOSE ${PORT:-8080}

CMD ["/app/docker-entrypoint.sh"]
