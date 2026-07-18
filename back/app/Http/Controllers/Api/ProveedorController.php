<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Empresa;
use App\Models\Proveedor;
use App\Services\ProveedoresIniciales;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProveedorController extends Controller
{
    /**
     * Proveedores de la empresa: primero el "S/N" (por defecto) y el resto
     * en orden alfabético. Empresas creadas antes de este módulo: si nunca
     * tuvieron proveedores se siembran los iniciales.
     */
    public function index(Request $request): JsonResponse
    {
        $empresa = $this->empresa($request);

        if ($empresa === null) {
            return $this->sinEmpresa();
        }

        if ($empresa->proveedores()->withTrashed()->count() === 0) {
            ProveedoresIniciales::crear($empresa);
        } else {
            Proveedor::porDefecto($empresa);
        }

        return response()->json([
            'proveedores' => $empresa->proveedores()
                ->orderByDesc('es_default')
                ->orderBy('nombre')
                ->get(),
        ]);
    }

    /**
     * Registra un proveedor de la empresa.
     */
    public function store(Request $request): JsonResponse
    {
        $empresa = $this->empresa($request);

        if ($empresa === null) {
            return $this->sinEmpresa();
        }

        $proveedor = $empresa->proveedores()->create($this->validated($request));

        return response()->json(['proveedor' => $proveedor], 201);
    }

    /**
     * Actualiza un proveedor. El "S/N" no se edita: es el comodín de las
     * compras sin proveedor.
     */
    public function update(Request $request, int $proveedorId): JsonResponse
    {
        $empresa = $this->empresa($request);

        if ($empresa === null) {
            return $this->sinEmpresa();
        }

        $proveedor = $empresa->proveedores()->find($proveedorId);

        if ($proveedor === null) {
            return response()->json(['message' => 'El proveedor no existe.'], 404);
        }

        if ($proveedor->es_default) {
            return response()->json([
                'message' => 'El proveedor S/N no se puede editar.',
            ], 409);
        }

        $proveedor->update($this->validated($request));

        return response()->json(['proveedor' => $proveedor->refresh()]);
    }

    /**
     * Borra (suave) un proveedor. El "S/N" no se puede borrar y las compras
     * ya registradas conservan el nombre congelado del proveedor.
     */
    public function destroy(Request $request, int $proveedorId): JsonResponse
    {
        $empresa = $this->empresa($request);

        if ($empresa === null) {
            return $this->sinEmpresa();
        }

        $proveedor = $empresa->proveedores()->find($proveedorId);

        if ($proveedor === null) {
            return response()->json(['message' => 'El proveedor no existe.'], 404);
        }

        if ($proveedor->es_default) {
            return response()->json([
                'message' => 'El proveedor S/N no se puede borrar.',
            ], 409);
        }

        $proveedor->delete();

        return response()->json(['message' => 'Proveedor borrado.']);
    }

    private function empresa(Request $request): ?Empresa
    {
        return $request->user()->empresa;
    }

    private function sinEmpresa(): JsonResponse
    {
        return response()->json([
            'message' => 'Tu cuenta no tiene una empresa registrada.',
        ], 404);
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
            'correo' => ['nullable', 'email', 'max:255'],
            'direccion' => ['nullable', 'string', 'max:255'],
        ]);
    }
}
