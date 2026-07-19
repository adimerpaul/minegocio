<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'pedido_id',
    'producto_id',
    'nombre',
    'precio',
    'cantidad',
    'subtotal',
])]
class PedidoItem extends Model
{
    use SoftDeletes;

    protected $table = 'pedido_items';

    protected function casts(): array
    {
        return [
            'precio' => 'float',
            'subtotal' => 'float',
            'cantidad' => 'integer',
        ];
    }

    public function pedido(): BelongsTo
    {
        return $this->belongsTo(Pedido::class);
    }

    public function producto(): BelongsTo
    {
        return $this->belongsTo(Producto::class);
    }
}
