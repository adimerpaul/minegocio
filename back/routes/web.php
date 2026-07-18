<?php

use App\Http\Controllers\TiendaController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/tienda/{slug}', TiendaController::class)->name('tienda.show');
