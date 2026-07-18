<?php

namespace App\Services;

use App\Models\Cliente;
use App\Models\Empresa;

/**
 * Clientes por defecto de una empresa nueva: el cliente "S/N" (sin nombre,
 * el que usa la venta cuando no se elige otro) y diez clientes ficticios
 * para que la gestión de clientes no arranque vacía.
 */
class ClientesIniciales
{
    /**
     * [nombre, nit, teléfono].
     *
     * @var array<array{string, string, string}>
     */
    private const FICTICIOS = [
        ['Rosa Mamani', '4587921015', '70412358'],
        ['Juan Quispe', '6723481019', '71589264'],
        ['María Condori', '5391756012', '72946135'],
        ['Carlos Choque', '7845213016', '73158942'],
        ['Ana Flores', '3652894017', '74863251'],
        ['Pedro Huanca', '9134567013', '75294816'],
        ['Lucía Vargas', '2478135018', '76531498'],
        ['Miguel Ticona', '8563214011', '77845962'],
        ['Elena Apaza', '1936874014', '78216354'],
        ['Jorge Colque', '6285493010', '79462583'],
    ];

    public static function crear(Empresa $empresa): void
    {
        Cliente::porDefecto($empresa);

        foreach (self::FICTICIOS as [$nombre, $nit, $telefono]) {
            $empresa->clientes()->create([
                'nombre' => $nombre,
                'nit' => $nit,
                'telefono' => $telefono,
            ]);
        }
    }
}
