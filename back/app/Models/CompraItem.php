<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use OwenIt\Auditing\Auditable;
use OwenIt\Auditing\Contracts\Auditable as AuditableContract;

#[Fillable(['compra_id', 'producto_id', 'nombre', 'costo', 'cantidad', 'subtotal'])]
class CompraItem extends Model implements AuditableContract
{
    use Auditable, SoftDeletes;

    protected $table = 'compra_items';

    protected function casts(): array
    {
        return [
            'costo' => 'float',
            'cantidad' => 'integer',
            'subtotal' => 'float',
        ];
    }

    public function compra(): BelongsTo
    {
        return $this->belongsTo(Compra::class);
    }

    public function producto(): BelongsTo
    {
        return $this->belongsTo(Producto::class);
    }
}
