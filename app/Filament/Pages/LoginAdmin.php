<?php

namespace App\Filament\Pages;

use Filament\Pages\Auth\Login;
use Filament\Http\Responses\Auth\Contracts\LoginResponse;
use Illuminate\Support\Facades\Auth;

class LoginAdmin extends Login
{
    public function getHeading(): string
    {
        return 'Ingrese a EducoVota';
    }

    public function getTitle(): string
    {
        return 'EducoVota - Inicio de sesión';
    }

    public function authenticate(): ?LoginResponse
    {
        $result = parent::authenticate();

        if ($result) {
            return new class implements LoginResponse {
                public function toResponse($request)
                {
                    return redirect()->intended('/admin');
                }
            };
        }

        return null;
    }
}
