<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cliente;
use App\Models\Producto;
use App\Models\Venta;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class VentaController extends Controller
{
    /**
     * Ventas de la empresa (las más recientes primero), con sus ítems.
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
            'ventas' => $empresa->ventas()
                ->with('items')
                ->orderByDesc('id')
                ->limit(200)
                ->get(),
        ]);
    }

    /**
     * Registra una venta del punto de venta (Venta rápida): valida el stock,
     * congela nombre y precio de cada producto en los ítems, descuenta el
     * inventario y genera el código correlativo (V-0001, V-0002, …).
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        $empresa = $user->empresa;

        if ($empresa === null) {
            return response()->json([
                'message' => 'Tu cuenta no tiene una empresa registrada.',
            ], 404);
        }

        $data = $request->validate([
            'cliente' => ['nullable', 'string', 'max:255'],
            'cliente_id' => ['nullable', 'integer'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.producto_id' => ['required', 'integer'],
            'items.*.cantidad' => ['required', 'integer', 'min:1'],
        ]);

        // Cliente de la venta: el elegido (debe ser de la empresa) o el
        // "S/N" por defecto. Su nombre se congela en la columna `cliente`.
        if (isset($data['cliente_id'])) {
            $cliente = $empresa->clientes()->find($data['cliente_id']);

            if ($cliente === null) {
                throw ValidationException::withMessages([
                    'cliente_id' => ['El cliente no existe en tu empresa.'],
                ]);
            }
        } else {
            $cliente = Cliente::porDefecto($empresa);
        }

        $venta = DB::transaction(function () use ($data, $empresa, $user, $cliente) {
            $cantidades = collect($data['items'])
                ->groupBy('producto_id')
                ->map(fn ($items) => $items->sum('cantidad'));

            $productos = $empresa->productos()
                ->whereIn('id', $cantidades->keys())
                ->get()
                ->keyBy('id');

            $total = 0.0;
            $items = [];

            foreach ($cantidades as $productoId => $cantidad) {
                $producto = $productos->get($productoId);

                if ($producto === null) {
                    throw ValidationException::withMessages([
                        'items' => ["El producto {$productoId} no existe en tu empresa."],
                    ]);
                }

                if ($producto->stock < $cantidad) {
                    throw ValidationException::withMessages([
                        'items' => ["Stock insuficiente para {$producto->nombre} (quedan {$producto->stock})."],
                    ]);
                }

                $subtotal = round($producto->precio * $cantidad, 2);
                $total += $subtotal;

                $items[] = [
                    'producto_id' => $producto->id,
                    'nombre' => $producto->nombre,
                    'precio' => $producto->precio,
                    'cantidad' => $cantidad,
                    'subtotal' => $subtotal,
                ];
            }

            // Correlativo por empresa; incluye las borradas para no repetir.
            $numero = Venta::withTrashed()
                ->where('empresa_id', $empresa->id)
                ->count() + 1;

            $venta = $empresa->ventas()->create([
                'user_id' => $user->id,
                'codigo' => sprintf('V-%04d', $numero),
                'cliente' => $data['cliente'] ?? $cliente->nombre,
                'cliente_id' => $cliente->id,
                'total' => round($total, 2),
                'estado' => 'completada',
            ]);

            $venta->items()->createMany($items);

            foreach ($items as $item) {
                $productos[$item['producto_id']]->decrement('stock', $item['cantidad']);
            }

            return $venta;
        });

        return response()->json([
            'venta' => $venta->load('items'),
        ], 201);
    }

    /**
     * Anula una venta: marca el estado y devuelve al inventario las
     * cantidades de todos sus ítems.
     */
    public function anular(Request $request, int $ventaId): JsonResponse
    {
        $empresa = $request->user()->empresa;

        if ($empresa === null) {
            return response()->json([
                'message' => 'Tu cuenta no tiene una empresa registrada.',
            ], 404);
        }

        $venta = $empresa->ventas()->with('items')->find($ventaId);

        if ($venta === null) {
            return response()->json(['message' => 'La venta no existe.'], 404);
        }

        if ($venta->estado === 'anulada') {
            return response()->json(['message' => 'La venta ya está anulada.'], 409);
        }

        DB::transaction(function () use ($venta) {
            foreach ($venta->items as $item) {
                if ($item->producto_id === null) {
                    continue;
                }

                // withTrashed: el stock se devuelve aunque el producto
                // se haya borrado (suave) después de la venta.
                Producto::withTrashed()
                    ->whereKey($item->producto_id)
                    ->increment('stock', $item->cantidad);
            }

            $venta->update(['estado' => 'anulada']);
        });

        return response()->json([
            'venta' => $venta->refresh()->load('items'),
        ]);
    }
}
