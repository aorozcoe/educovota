#!/bin/bash
set -e

php artisan storage:link --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
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

php artisan serve --host=0.0.0.0 --port=${PORT:-8080}
