<?php

use App\Http\Controllers\Api\EmpresaController;
use App\Http\Controllers\Api\GoogleAuthController;
use App\Http\Controllers\Api\ProductoController;
use App\Http\Controllers\Api\VentaController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/auth/google', GoogleAuthController::class);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user()->load('empresa');
    });

    Route::post('/empresas', [EmpresaController::class, 'store']);
    Route::put('/empresa', [EmpresaController::class, 'update']);
    Route::get('/productos', [ProductoController::class, 'index']);
    Route::get('/ventas', [VentaController::class, 'index']);
    Route::post('/ventas', [VentaController::class, 'store']);
    Route::post('/ventas/{venta}/anular', [VentaController::class, 'anular']);
});
