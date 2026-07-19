<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'empresa_id',
    'cliente_nombre',
    'cliente_telefono',
    'direccion',
    'total',
    'estado',
    'notas',
    'metodo_contacto',
])]
class Pedido extends Model
{
    use SoftDeletes;

    protected function casts(): array
    {
        return [
            'total' => 'float',
        ];
    }

    public function empresa(): BelongsTo
    {
        return $this->belongsTo(Empresa::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(PedidoItem::class);
    }
}
