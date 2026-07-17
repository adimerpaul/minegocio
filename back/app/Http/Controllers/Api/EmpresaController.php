<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Empresa;
use App\Services\WebpImage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EmpresaController extends Controller
{
    /**
     * Registra la empresa del usuario autenticado (pantalla "Registro de
     * empresa" del mockup) y vincula su cuenta a ella. El logo es opcional
     * y se guarda como WebP en storage/app/public/logos/.
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->empresa_id !== null) {
            return response()->json([
                'message' => 'Tu cuenta ya está vinculada a una empresa.',
            ], 409);
        }

        $data = $this->validated($request);

        $empresa = Empresa::create(collect($data)->except('logo')->all());

        if ($request->hasFile('logo')) {
            $logo = WebpImage::store(
                $request->file('logo')->getContent(),
                "logos/empresa-{$empresa->id}.webp",
            );

            if ($logo !== null) {
                $empresa->update(['logo_path' => $logo]);
            }
        }

        $user->empresa()->associate($empresa)->save();

        return response()->json([
            'empresa' => $empresa->refresh(),
            'user' => $user->load('empresa'),
        ], 201);
    }

    /**
     * Actualiza los datos de la empresa del usuario (pantalla Configuración).
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();
        $empresa = $user->empresa;

        if ($empresa === null) {
            return response()->json([
                'message' => 'Tu cuenta no tiene una empresa registrada.',
            ], 404);
        }

        $data = $this->validated($request);

        $empresa->update(collect($data)->except('logo')->all());

        if ($request->hasFile('logo')) {
            $logo = WebpImage::store(
                $request->file('logo')->getContent(),
                "logos/empresa-{$empresa->id}.webp",
            );

            if ($logo !== null) {
                $empresa->update(['logo_path' => $logo]);
            }
        }

        return response()->json([
            'empresa' => $empresa->refresh(),
            'user' => $user->load('empresa'),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request): array
    {
        return $request->validate([
            'nombre' => ['required', 'string', 'max:255'],
            'nit' => ['nullable', 'string', 'max:30'],
            'telefono' => ['nullable', 'string', 'max:30'],
            'direccion' => ['nullable', 'string', 'max:255'],
            'correo' => ['nullable', 'email', 'max:255'],
            'moneda' => ['nullable', 'string', 'in:BOB,USD,PEN'],
            'logo' => ['nullable', 'image', 'max:4096'],
        ], [], [
            'nombre' => 'nombre comercial',
            'correo' => 'correo de la empresa',
        ]);
    }
}
