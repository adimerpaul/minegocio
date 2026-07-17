<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['venta_id', 'producto_id', 'nombre', 'precio', 'cantidad', 'subtotal'])]
class VentaItem extends Model
{
    use SoftDeletes;

    protected $table = 'venta_items';

    protected function casts(): array
    {
        return [
            'precio' => 'float',
            'subtotal' => 'float',
            'cantidad' => 'integer',
        ];
    }

    public function venta(): BelongsTo
    {
        return $this->belongsTo(Venta::class);
    }

    public function producto(): BelongsTo
    {
        return $this->belongsTo(Producto::class);
    }
}
