#!/bin/bash
set -e

# Set Railway's dynamic PORT in nginx config (default 8080)
sed -i "s|listen 8080|listen ${PORT:-8080}|g" /etc/nginx/sites-enabled/default

# Create storage link
php artisan storage:link --force

# Cache configuration
php artisan config:cache
php artisan view:cache

# Run migrations
php artisan migrate --force

# Create admin user if it doesn't exist
php artisan tinker --execute="
if (!\App\Models\User::where('email', 'admin@email.co')->exists()) {
    \App\Models\User::create([
        'name' => 'Administrador del Sistema',
        'email' => 'admin@email.co',
        'password' => bcrypt('admin'),
    ]);
    echo 'Admin user created.';
} else {
    echo 'Admin user already exists.';
}
"

# Seed configuracion and grados if tables are empty
php artisan tinker --execute="
if (\Illuminate\Support\Facades\Schema::hasTable('configuraciones') && \App\Models\Configuracion::count() === 0) {
    \Illuminate\Support\Facades\Artisan::call('db:seed', ['--class' => 'Database\Seeders\ConfiguracionSeeder', '--force' => true]);
    echo 'ConfiguracionSeeder executed.';
}
"

php artisan tinker --execute="
if (\Illuminate\Support\Facades\Schema::hasTable('grados') && \DB::table('grados')->count() === 0) {
    \Illuminate\Support\Facades\Artisan::call('db:seed', ['--class' => 'Database\Seeders\GradoSeeder', '--force' => true]);
    echo 'GradoSeeder executed.';
}
"

# Ensure correct permissions for runtime
chown -R www-data:www-data /app/storage /app/bootstrap/cache

# Create php-fpm socket directory
mkdir -p /run

# Start supervisor (manages nginx + php-fpm)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
