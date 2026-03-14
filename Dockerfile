FROM php:8.2-cli

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl zip unzip libicu-dev libzip-dev libpng-dev libjpeg-dev libfreetype6-dev \
    nodejs npm \
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

# Dump autoload without running scripts (avoid DB connections during build)
RUN composer dump-autoload --optimize --no-scripts

# Build frontend assets
RUN npm run build

# Expose port
EXPOSE ${PORT:-8080}

# Start: link storage, cache config, run migrations, then serve
CMD php artisan storage:link --force && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan migrate --force && \
    php artisan serve --host=0.0.0.0 --port=${PORT:-8080}
