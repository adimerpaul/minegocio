<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use OwenIt\Auditing\Auditable;
use OwenIt\Auditing\Contracts\Auditable as AuditableContract;

#[Fillable(['empresa_id', 'categoria_id', 'codigo', 'codigo_barras', 'nombre', 'precio', 'stock', 'stock_minimo', 'imagen_path'])]
class Producto extends Model implements AuditableContract
{
    use Auditable, SoftDeletes;

    protected $table = 'productos';

    protected function casts(): array
    {
        return [
            'precio' => 'float',
            'stock' => 'integer',
            'stock_minimo' => 'integer',
        ];
    }

    public function empresa(): BelongsTo
    {
        return $this->belongsTo(Empresa::class);
    }

    public function categoria(): BelongsTo
    {
        return $this->belongsTo(Categoria::class);
    }
}
