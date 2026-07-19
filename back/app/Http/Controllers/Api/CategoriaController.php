<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\WebpImage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class CategoriaController extends Controller
{
    /**
     * Lista las categorías de la empresa del usuario autenticado.
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
            'categorias' => $empresa->categorias()->orderBy('nombre')->get(),
        ]);
    }

    /**
     * Crea una nueva categoría en la empresa del usuario.
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
            'descripcion' => ['nullable', 'string', 'max:500'],
            'imagen' => ['nullable', 'image', 'max:4096'],
        ]);

        $categoria = $empresa->categorias()->create([
            'nombre' => $data['nombre'],
            'descripcion' => $data['descripcion'] ?? null,
        ]);

        if ($request->hasFile('imagen')) {
            $imagen = WebpImage::store(
                $request->file('imagen')->getContent(),
                "categorias/{$empresa->id}/categoria-{$categoria->id}-".now()->timestamp.'.webp',
            );

            if ($imagen !== null) {
                $categoria->update(['imagen_path' => $imagen]);
            }
        }

        return response()->json(['categoria' => $categoria->refresh()], 201);
    }

    /**
     * Actualiza una categoría de la empresa.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $empresa = $request->user()->empresa;

        if ($empresa === null) {
            return response()->json([
                'message' => 'Tu cuenta no tiene una empresa registrada.',
            ], 404);
        }

        $categoria = $empresa->categorias()->find($id);

        if ($categoria === null) {
            return response()->json([
                'message' => 'La categoría no existe.',
            ], 404);
        }

        $data = $request->validate([
            'nombre' => ['required', 'string', 'max:255'],
            'descripcion' => ['nullable', 'string', 'max:500'],
            'imagen' => ['nullable', 'image', 'max:4096'],
        ]);

        $categoria->update([
            'nombre' => $data['nombre'],
            'descripcion' => $data['descripcion'] ?? null,
        ]);

        if ($request->hasFile('imagen')) {
            $imagen = WebpImage::store(
                $request->file('imagen')->getContent(),
                "categorias/{$empresa->id}/categoria-{$categoria->id}-".now()->timestamp.'.webp',
            );

            if ($imagen !== null) {
                $anterior = $categoria->imagen_path;
                $categoria->update(['imagen_path' => $imagen]);

                if ($anterior !== null && str_starts_with($anterior, '/storage/')) {
                    Storage::disk('public')->delete(substr($anterior, strlen('/storage/')));
                }
            }
        }

        return response()->json(['categoria' => $categoria->refresh()]);
    }

    /**
     * Elimina una categoría de la empresa. No se permite si tiene productos.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $empresa = $request->user()->empresa;

        if ($empresa === null) {
            return response()->json([
                'message' => 'Tu cuenta no tiene una empresa registrada.',
            ], 404);
        }

        $categoria = $empresa->categorias()->find($id);

        if ($categoria === null) {
            return response()->json([
                'message' => 'La categoría no existe.',
            ], 404);
        }

        if ($categoria->productos()->exists()) {
            return response()->json([
                'message' => 'No se puede eliminar la categoría porque tiene productos asociados.',
            ], 409);
        }

        $categoria->delete();

        return response()->json(['message' => 'Categoría eliminada.']);
    }
}
