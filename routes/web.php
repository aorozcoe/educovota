<?php

use Illuminate\Support\Facades\Route;

Route::get('/login/admin', fn () => redirect('/admin/login'));
