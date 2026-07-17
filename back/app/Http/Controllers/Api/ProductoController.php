<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductoController extends Controller
{
    /**
     * Catálogo de la empresa del usuario: categorías y productos.
     * Lo usan Venta rápida y los módulos de gestión de la app.
     */
    public function index(Request $request): JsonResponse
    {
        $empresa = $request->user()->empresa;

        if ($empresa === null) {
            return response()->json([
                'message' => 'Tu cuenta no tiene una empresa registrada.',
            ], 404);
        }

        return response()->json([
            'categorias' => $empresa->categorias()->orderBy('id')->get(),
            'productos' => $empresa->productos()->orderBy('id')->get(),
        ]);
    }
}
