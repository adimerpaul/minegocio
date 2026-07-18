<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use OwenIt\Auditing\Auditable;
use OwenIt\Auditing\Contracts\Auditable as AuditableContract;

#[Fillable(['empresa_id', 'nombre', 'nit', 'telefono', 'correo', 'direccion', 'es_default'])]
class Proveedor extends Model implements AuditableContract
{
    use Auditable, SoftDeletes;

    protected $table = 'proveedores';

    protected function casts(): array
    {
        return [
            'es_default' => 'boolean',
        ];
    }

    public function empresa(): BelongsTo
    {
        return $this->belongsTo(Empresa::class);
    }

    /**
     * El proveedor por defecto de la empresa ("S/N"): se usa en la compra
     * cuando no se elige otro. Si la empresa aún no lo tiene, se crea aquí.
     */
    public static function porDefecto(Empresa $empresa): self
    {
        return self::firstOrCreate(
            ['empresa_id' => $empresa->id, 'es_default' => true],
            ['nombre' => 'S/N'],
        );
    }
}
