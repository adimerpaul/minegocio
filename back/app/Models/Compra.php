<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use OwenIt\Auditing\Auditable;
use OwenIt\Auditing\Contracts\Auditable as AuditableContract;

#[Fillable(['empresa_id', 'user_id', 'codigo', 'proveedor', 'proveedor_id', 'total', 'estado'])]
class Compra extends Model implements AuditableContract
{
    use Auditable, SoftDeletes;

    protected $table = 'compras';

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

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(CompraItem::class, 'compra_id');
    }
}
