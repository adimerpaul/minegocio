<?php

namespace App\Services;

use App\Models\Empresa;
use App\Models\Proveedor;

/**
 * Proveedores por defecto de una empresa nueva: el "S/N" (el que usa la
 * compra cuando no se elige otro) y cinco proveedores ficticios para que
 * la gestión de proveedores no arranque vacía.
 */
class ProveedoresIniciales
{
    /**
     * [nombre, nit, teléfono].
     *
     * @var array<array{string, string, string}>
     */
    private const FICTICIOS = [
        ['Avícola San Pedro', '1023456789', '70123456'],
        ['Distribuidora El Alto', '2034567891', '71234567'],
        ['Frutas Doña Julia', '3045678912', '72345678'],
        ['Embotelladora Andina', '4056789123', '73456789'],
        ['Mercado Rodríguez', '5067891234', '74567891'],
    ];

    public static function crear(Empresa $empresa): void
    {
        Proveedor::porDefecto($empresa);

        foreach (self::FICTICIOS as [$nombre, $nit, $telefono]) {
            $empresa->proveedores()->create([
                'nombre' => $nombre,
                'nit' => $nit,
                'telefono' => $telefono,
            ]);
        }
    }
}
