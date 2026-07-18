<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use OwenIt\Auditing\Auditable;
use OwenIt\Auditing\Contracts\Auditable as AuditableContract;

#[Fillable(['empresa_id', 'nombre', 'nit', 'telefono', 'correo', 'direccion', 'es_default'])]
class Cliente extends Model implements AuditableContract
{
    use Auditable, SoftDeletes;

    protected $table = 'clientes';

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
     * El cliente por defecto de la empresa ("S/N", sin nombre): se usa en la
     * venta cuando no se elige otro. Si la empresa aún no lo tiene (empresas
     * creadas antes de este módulo), se crea aquí.
     */
    public static function porDefecto(Empresa $empresa): self
    {
        return self::firstOrCreate(
            ['empresa_id' => $empresa->id, 'es_default' => true],
            ['nombre' => 'S/N'],
        );
    }
}
