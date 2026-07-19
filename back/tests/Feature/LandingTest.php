<?php

use App\Models\Empresa;

it('muestra la landing en la página principal', function () {
    $response = $this->get('/');

    $response->assertOk();
    $response->assertSee('Mi Negocio');
    $response->assertSee('Tu negocio y tu tienda en línea, desde el celular.');
    $response->assertDontSee('Ver tienda de ejemplo');
});

it('enlaza la tienda de ejemplo cuando hay una empresa con tienda', function () {
    config(['audit.console' => true]);

    $empresa = Empresa::create([
        'nombre' => 'Pollos Copacabana',
        'slug_tienda' => 'pollos-copacabana',
    ]);

    $response = $this->get('/');

    $response->assertOk();
    $response->assertSee('Ver tienda de ejemplo');
    $response->assertSee(route('tienda.show', $empresa->slug_tienda));
});
