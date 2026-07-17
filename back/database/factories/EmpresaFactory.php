<?php

namespace Database\Factories;

use App\Models\Empresa;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Empresa>
 */
class EmpresaFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'nombre' => fake()->company(),
            'nit' => (string) fake()->numberBetween(1000000, 999999999),
            'telefono' => fake()->phoneNumber(),
            'direccion' => fake()->address(),
            'correo' => fake()->companyEmail(),
            'moneda' => 'BOB',
        ];
    }
}
