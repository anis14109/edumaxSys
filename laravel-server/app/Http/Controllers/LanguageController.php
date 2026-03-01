<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\App;

class LanguageController extends Controller
{
    /**
     * Set the application locale
     */
    public function setLocale(Request $request, string $locale)
    {
        if (!in_array($locale, ['en', 'bn'])) {
            $locale = 'en';
        }

        App::setLocale($locale);
        Session::put('locale', $locale);

        return redirect()->back();
    }
}
