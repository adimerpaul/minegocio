<?php

use App\Http\Controllers\TiendaController;
use App\Models\Empresa;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    $tiendaEjemplo = Empresa::whereNotNull('slug_tienda')
        ->where('slug_tienda', '!=', '')
        ->orderBy('id')
        ->first();

    return view('landing', compact('tiendaEjemplo'));
})->name('landing');

Route::get('/tienda/{slug}', TiendaController::class)->name('tienda.show');
Route::get('/tienda/{slug}/producto/{producto}/{nombreSlug?}', [TiendaController::class, 'producto'])
    ->name('tienda.producto');
