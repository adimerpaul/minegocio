<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cliente;
use App\Models\Empresa;
use App\Services\ClientesIniciales;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClienteController extends Controller
{
    /**
     * Clientes de la empresa: primero el "S/N" (por defecto) y el resto
     * en orden alfabético. Si la empresa aún no tiene el S/N, se crea.
     */
    public function index(Request $request): JsonResponse
    {
        $empresa = $this->empresa($request);

        if ($empresa === null) {
            return $this->sinEmpresa();
        }

        // Empresas creadas antes de este módulo: si nunca tuvieron clientes
        // se siembran los iniciales (S/N + ficticios); si no, solo se
        // garantiza el S/N.
        if ($empresa->clientes()->withTrashed()->count() === 0) {
            ClientesIniciales::crear($empresa);
        } else {
            Cliente::porDefecto($empresa);
        }

        return response()->json([
            'clientes' => $empresa->clientes()
                ->orderByDesc('es_default')
                ->orderBy('nombre')
                ->get(),
        ]);
    }

    /**
     * Registra un cliente de la empresa.
     */
    public function store(Request $request): JsonResponse
    {
        $empresa = $this->empresa($request);

        if ($empresa === null) {
            return $this->sinEmpresa();
        }

        $cliente = $empresa->clientes()->create($this->validated($request));

        return response()->json(['cliente' => $cliente], 201);
    }

    /**
     * Actualiza un cliente de la empresa. El cliente "S/N" no se edita:
     * es el comodín de las ventas sin cliente.
     */
    public function update(Request $request, int $clienteId): JsonResponse
    {
        $empresa = $this->empresa($request);

        if ($empresa === null) {
            return $this->sinEmpresa();
        }

        $cliente = $empresa->clientes()->find($clienteId);

        if ($cliente === null) {
            return response()->json(['message' => 'El cliente no existe.'], 404);
        }

        if ($cliente->es_default) {
            return response()->json([
                'message' => 'El cliente S/N no se puede editar.',
            ], 409);
        }

        $cliente->update($this->validated($request));

        return response()->json(['cliente' => $cliente->refresh()]);
    }

    /**
     * Borra (suave) un cliente. El "S/N" no se puede borrar y las ventas
     * ya registradas conservan el nombre congelado del cliente.
     */
    public function destroy(Request $request, int $clienteId): JsonResponse
    {
        $empresa = $this->empresa($request);

        if ($empresa === null) {
            return $this->sinEmpresa();
        }

        $cliente = $empresa->clientes()->find($clienteId);

        if ($cliente === null) {
            return response()->json(['message' => 'El cliente no existe.'], 404);
        }

        if ($cliente->es_default) {
            return response()->json([
                'message' => 'El cliente S/N no se puede borrar.',
            ], 409);
        }

        $cliente->delete();

        return response()->json(['message' => 'Cliente borrado.']);
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
