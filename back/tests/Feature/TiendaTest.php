<?php

use App\Models\Empresa;

it('muestra la tienda pública de una empresa por su slug', function () {
    $empresa = Empresa::factory()->create([
        'nombre' => 'La Canasta Market',
        'slug_tienda' => 'la-canasta-market',
        'telefono' => '+591 700 12345',
        'moneda' => 'BOB',
    ]);

    $categoria = $empresa->categorias()->create([
        'nombre' => 'Abarrotes',
    ]);

    $empresa->productos()->create([
        'categoria_id' => $categoria->id,
        'nombre' => 'Arroz Extra 1kg',
        'precio' => 9.5,
        'stock' => 10,
        'codigo' => 'P-001',
    ]);

    $this->get('/tienda/la-canasta-market')
        ->assertOk()
        ->assertSee('La Canasta Market')
        ->assertSee('Arroz Extra 1kg')
        ->assertSee('BOB 9.50');
});

it('normaliza el slug en la URL de la tienda pública', function () {
    Empresa::factory()->create([
        'nombre' => 'Pollos Copacabana',
        'slug_tienda' => 'pollos-copacabana',
    ]);

    $this->get('/tienda/Pollos-Copacabaña')
        ->assertOk()
        ->assertSee('Pollos Copacabana');
});

it('responde 404 si el slug de tienda no existe', function () {
    $this->get('/tienda/no-existe')->assertNotFound();
});

it('muestra la página individual de un producto con slug SEO', function () {
    $empresa = Empresa::factory()->create([
        'nombre' => 'La Canasta Market',
        'slug_tienda' => 'la-canasta-market',
        'moneda' => 'BOB',
    ]);

    $categoria = $empresa->categorias()->create(['nombre' => 'Abarrotes']);
    $producto = $empresa->productos()->create([
        'categoria_id' => $categoria->id,
        'nombre' => 'Arroz Extra 1kg',
        'precio' => 9.5,
        'stock' => 10,
        'codigo' => 'P-001',
    ]);

    $this->get("/tienda/{$empresa->slug_tienda}/producto/{$producto->id}/arroz-extra-1kg")
        ->assertOk()
        ->assertSee('Arroz Extra 1kg')
        ->assertSee('BOB 9.50');
});

it('redirige al slug correcto si el nombre del producto cambió', function () {
    $empresa = Empresa::factory()->create([
        'nombre' => 'La Canasta Market',
        'slug_tienda' => 'la-canasta-market',
    ]);

    $producto = $empresa->productos()->create([
        'nombre' => 'Arroz Extra 1kg',
        'precio' => 9.5,
        'stock' => 10,
        'codigo' => 'P-001',
    ]);

    $this->get("/tienda/{$empresa->slug_tienda}/producto/{$producto->id}/nombre-viejo")
        ->assertRedirect("/tienda/{$empresa->slug_tienda}/producto/{$producto->id}/arroz-extra-1kg");
});
