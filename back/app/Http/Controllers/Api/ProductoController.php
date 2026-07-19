<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Producto;
use App\Services\WebpImage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

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

    /**
     * Crea un nuevo producto en la empresa del usuario autenticado.
     */
    public function store(Request $request): JsonResponse
    {
        $empresa = $request->user()->empresa;

        if ($empresa === null) {
            return response()->json([
                'message' => 'Tu cuenta no tiene una empresa registrada.',
            ], 404);
        }

        $data = $request->validate([
            'nombre' => ['required', 'string', 'max:255'],
            'precio' => ['required', 'numeric', 'min:0'],
            'stock' => ['required', 'integer', 'min:0'],
            'stock_minimo' => ['required', 'integer', 'min:0'],
            'codigo_barras' => ['nullable', 'string', 'max:100'],
            'categoria_id' => [
                'nullable',
                Rule::exists('categorias', 'id')
                    ->where('empresa_id', $empresa->id)
                    ->whereNull('deleted_at'),
            ],
            'imagen' => ['nullable', 'image', 'max:4096'],
        ]);

        $ultimo = $empresa->productos()->withTrashed()->orderByDesc('id')->first();
        $siguiente = $ultimo ? ((int) str_replace('P-', '', $ultimo->codigo)) + 1 : 1;

        $producto = $empresa->productos()->create([
            ...collect($data)->except('imagen')->all(),
            'codigo' => 'P-'.str_pad((string) $siguiente, 3, '0', STR_PAD_LEFT),
        ]);

        if ($request->hasFile('imagen')) {
            $imagen = WebpImage::store(
                $request->file('imagen')->getContent(),
                "productos/{$empresa->id}/producto-{$producto->id}-".now()->timestamp.'.webp',
            );

            if ($imagen !== null) {
                $producto->update(['imagen_path' => $imagen]);
            }
        }

        return response()->json(['producto' => $producto->refresh()], 201);
    }

    /**
     * Actualiza un producto de la empresa (pantalla "Editar producto").
     * La imagen es opcional y se guarda como WebP; el nombre lleva un
     * sufijo de tiempo para que la app no muestre la foto vieja cacheada.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $empresa = $request->user()->empresa;

        if ($empresa === null) {
            return response()->json([
                'message' => 'Tu cuenta no tiene una empresa registrada.',
            ], 404);
        }

        $producto = $empresa->productos()->find($id);

        if ($producto === null) {
            return response()->json([
                'message' => 'El producto no existe.',
            ], 404);
        }

        $data = $request->validate([
            'nombre' => ['required', 'string', 'max:255'],
            'precio' => ['required', 'numeric', 'min:0'],
            'stock' => ['required', 'integer', 'min:0'],
            'stock_minimo' => ['required', 'integer', 'min:0'],
            'codigo_barras' => ['nullable', 'string', 'max:100'],
            'categoria_id' => [
                'nullable',
                Rule::exists('categorias', 'id')
                    ->where('empresa_id', $empresa->id)
                    ->whereNull('deleted_at'),
            ],
            'imagen' => ['nullable', 'image', 'max:4096'],
        ]);

        $producto->update(collect($data)->except('imagen')->all());

        if ($request->hasFile('imagen')) {
            $imagen = WebpImage::store(
                $request->file('imagen')->getContent(),
                "productos/{$empresa->id}/producto-{$producto->id}-".now()->timestamp.'.webp',
            );

            if ($imagen !== null) {
                $anterior = $producto->imagen_path;
                $producto->update(['imagen_path' => $imagen]);

                if ($anterior !== null && str_starts_with($anterior, '/storage/')) {
                    Storage::disk('public')->delete(substr($anterior, strlen('/storage/')));
                }
            }
        }

        return response()->json(['producto' => $producto->refresh()]);
    }
}
