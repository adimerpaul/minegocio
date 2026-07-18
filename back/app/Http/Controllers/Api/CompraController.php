<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Compra;
use App\Models\Producto;
use App\Models\Proveedor;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CompraController extends Controller
{
    /**
     * Compras de la empresa (las más recientes primero), con sus ítems.
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
            'compras' => $empresa->compras()
                ->with('items')
                ->orderByDesc('id')
                ->limit(200)
                ->get(),
        ]);
    }

    /**
     * Registra una compra: congela nombre del producto y costo unitario en
     * los ítems, aumenta el inventario y genera el código correlativo
     * (C-0001, C-0002, …). El proveedor es el elegido o el "S/N".
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

        // Un ítem puede ser un producto del catálogo (producto_id, aumenta
        // stock) o un gasto libre (solo nombre: aceite, gas, bolsas…).
        $data = $request->validate([
            'proveedor_id' => ['nullable', 'integer'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.producto_id' => ['nullable', 'integer'],
            'items.*.nombre' => ['required_without:items.*.producto_id', 'nullable', 'string', 'max:255'],
            'items.*.cantidad' => ['required', 'integer', 'min:1'],
            'items.*.costo' => ['required', 'numeric', 'min:0'],
        ]);

        // Proveedor de la compra: el elegido (debe ser de la empresa) o el
        // "S/N". Su nombre se congela en la columna `proveedor`.
        if (isset($data['proveedor_id'])) {
            $proveedor = $empresa->proveedores()->find($data['proveedor_id']);

            if ($proveedor === null) {
                throw ValidationException::withMessages([
                    'proveedor_id' => ['El proveedor no existe en tu empresa.'],
                ]);
            }
        } else {
            $proveedor = Proveedor::porDefecto($empresa);
        }

        $compra = DB::transaction(function () use ($data, $empresa, $user, $proveedor) {
            $productos = $empresa->productos()
                ->whereIn('id', collect($data['items'])->pluck('producto_id'))
                ->get()
                ->keyBy('id');

            $total = 0.0;
            $items = [];

            foreach ($data['items'] as $item) {
                $productoId = $item['producto_id'] ?? null;
                $producto = null;

                if ($productoId !== null) {
                    $producto = $productos->get($productoId);

                    if ($producto === null) {
                        throw ValidationException::withMessages([
                            'items' => ["El producto {$productoId} no existe en tu empresa."],
                        ]);
                    }
                }

                $subtotal = round($item['costo'] * $item['cantidad'], 2);
                $total += $subtotal;

                $items[] = [
                    'producto_id' => $producto?->id,
                    'nombre' => $producto?->nombre ?? $item['nombre'],
                    'costo' => $item['costo'],
                    'cantidad' => $item['cantidad'],
                    'subtotal' => $subtotal,
                ];
            }

            // Correlativo por empresa; incluye las borradas para no repetir.
            $numero = Compra::withTrashed()
                ->where('empresa_id', $empresa->id)
                ->count() + 1;

            $compra = $empresa->compras()->create([
                'user_id' => $user->id,
                'codigo' => sprintf('C-%04d', $numero),
                'proveedor' => $proveedor->nombre,
                'proveedor_id' => $proveedor->id,
                'total' => round($total, 2),
                'estado' => 'completada',
            ]);

            $compra->items()->createMany($items);

            foreach ($items as $item) {
                if ($item['producto_id'] !== null) {
                    $productos[$item['producto_id']]->increment('stock', $item['cantidad']);
                }
            }

            return $compra;
        });

        return response()->json([
            'compra' => $compra->load('items'),
        ], 201);
    }

    /**
     * Anula una compra: marca el estado y descuenta del inventario las
     * cantidades de todos sus ítems.
     */
    public function anular(Request $request, int $compraId): JsonResponse
    {
        $empresa = $request->user()->empresa;

        if ($empresa === null) {
            return response()->json([
                'message' => 'Tu cuenta no tiene una empresa registrada.',
            ], 404);
        }

        $compra = $empresa->compras()->with('items')->find($compraId);

        if ($compra === null) {
            return response()->json(['message' => 'La compra no existe.'], 404);
        }

        if ($compra->estado === 'anulada') {
            return response()->json(['message' => 'La compra ya está anulada.'], 409);
        }

        DB::transaction(function () use ($compra) {
            foreach ($compra->items as $item) {
                if ($item->producto_id === null) {
                    continue;
                }

                // withTrashed: el stock se descuenta aunque el producto se
                // haya borrado (suave) después de la compra.
                Producto::withTrashed()
                    ->whereKey($item->producto_id)
                    ->decrement('stock', $item->cantidad);
            }

            $compra->update(['estado' => 'anulada']);
        });

        return response()->json([
            'compra' => $compra->refresh()->load('items'),
        ]);
    }
}
