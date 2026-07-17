<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use OwenIt\Auditing\Auditable;
use OwenIt\Auditing\Contracts\Auditable as AuditableContract;

#[Fillable(['empresa_id', 'categoria_id', 'codigo', 'nombre', 'precio', 'stock', 'imagen_path'])]
class Producto extends Model implements AuditableContract
{
    use Auditable, SoftDeletes;

    protected $table = 'productos';

    protected function casts(): array
    {
        return [
            'precio' => 'float',
            'stock' => 'integer',
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
