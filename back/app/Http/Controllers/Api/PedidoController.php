<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Empresa;
use App\Models\Pedido;
use App\Models\Producto;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PedidoController extends Controller
{
    /**
     * Recibe un pedido desde la tienda pública. No requiere autenticación.
     * Valida que los productos pertenezcan a la empresa indicada y que haya
     * stock suficiente. Luego crea el pedido con sus items.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'empresa_id' => ['required', 'integer', 'exists:empresas,id'],
            'cliente_nombre' => ['nullable', 'string', 'max:255'],
            'cliente_telefono' => ['nullable', 'string', 'max:30'],
            'direccion' => ['nullable', 'string', 'max:255'],
            'notas' => ['nullable', 'string', 'max:1000'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.producto_id' => ['required', 'integer', 'exists:productos,id'],
            'items.*.cantidad' => ['required', 'integer', 'min:1'],
        ], [], [
            'empresa_id' => 'empresa',
            'items' => 'productos del pedido',
            'items.*.producto_id' => 'producto',
            'items.*.cantidad' => 'cantidad',
        ]);

        $empresa = Empresa::findOrFail($data['empresa_id']);

        return DB::transaction(function () use ($data, $empresa) {
            $itemsFinales = [];
            $total = 0;

            foreach ($data['items'] as $item) {
                $producto = Producto::where('id', $item['producto_id'])
                    ->where('empresa_id', $empresa->id)
                    ->whereNull('deleted_at')
                    ->first();

                if ($producto === null) {
                    return response()->json([
                        'message' => 'Uno de los productos no pertenece a esta tienda.',
                    ], 422);
                }

                if ($producto->stock < $item['cantidad']) {
                    return response()->json([
                        'message' => "No hay stock suficiente para {$producto->nombre}.",
                    ], 422);
                }

                $subtotal = $producto->precio * $item['cantidad'];
                $itemsFinales[] = [
                    'producto_id' => $producto->id,
                    'nombre' => $producto->nombre,
                    'precio' => $producto->precio,
                    'cantidad' => $item['cantidad'],
                    'subtotal' => $subtotal,
                ];
                $total += $subtotal;

                // Se descuenta el stock al recibir el pedido. Si el pedido se
                // cancela más adelante, se debe devolver el stock.
                $producto->decrement('stock', $item['cantidad']);
            }

            $pedido = Pedido::create([
                'empresa_id' => $empresa->id,
                'cliente_nombre' => $data['cliente_nombre'] ?? null,
                'cliente_telefono' => $data['cliente_telefono'] ?? null,
                'direccion' => $data['direccion'] ?? null,
                'total' => $total,
                'estado' => 'pendiente',
                'notas' => $data['notas'] ?? null,
                'metodo_contacto' => 'whatsapp',
            ]);

            $pedido->items()->createMany($itemsFinales);

            return response()->json([
                'pedido' => $pedido->load('items'),
                'mensaje' => 'Pedido recibido correctamente.',
            ], 201);
        });
    }

    /**
     * Lista los pedidos de la empresa del usuario autenticado.
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
            'pedidos' => $empresa->pedidos()
                ->with('items')
                ->orderByDesc('id')
                ->limit(200)
                ->get(),
        ]);
    }

    /**
     * Muestra el detalle de un pedido de la empresa del usuario autenticado.
     */
    public function show(Request $request, Pedido $pedido): JsonResponse
    {
        $empresa = $request->user()->empresa;

        if ($empresa === null || $pedido->empresa_id !== $empresa->id) {
            return response()->json([
                'message' => 'Pedido no encontrado.',
            ], 404);
        }

        return response()->json($pedido->load('items.producto'));
    }

    /**
     * Actualiza el estado de un pedido (confirmado, entregado, cancelado).
     * Si se cancela, se devuelve el stock.
     */
    public function update(Request $request, Pedido $pedido): JsonResponse
    {
        $empresa = $request->user()->empresa;

        if ($empresa === null || $pedido->empresa_id !== $empresa->id) {
            return response()->json([
                'message' => 'Pedido no encontrado.',
            ], 404);
        }

        $data = $request->validate([
            'estado' => ['required', 'string', 'in:pendiente,confirmado,entregado,cancelado'],
        ]);

        $estadoAnterior = $pedido->estado;
        $nuevoEstado = $data['estado'];

        if ($estadoAnterior !== 'cancelado' && $nuevoEstado === 'cancelado') {
            foreach ($pedido->items as $item) {
                if ($item->producto_id !== null) {
                    $item->producto->increment('stock', $item->cantidad);
                }
            }
        }

        if ($estadoAnterior === 'cancelado' && $nuevoEstado !== 'cancelado') {
            foreach ($pedido->items as $item) {
                if ($item->producto_id !== null) {
                    $item->producto->decrement('stock', $item->cantidad);
                }
            }
        }

        $pedido->update(['estado' => $nuevoEstado]);

        return response()->json($pedido->load('items'));
    }
}
