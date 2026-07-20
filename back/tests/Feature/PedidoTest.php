<?php

use App\Models\Empresa;
use App\Models\Pedido;

it('recibe un pedido desde la tienda pública y descuenta stock', function () {
    $empresa = Empresa::factory()->create([
        'nombre' => 'Pollos Copacabana',
        'slug_tienda' => 'pollos-copacabana',
        'telefono' => '+591 700 12345',
    ]);

    $categoria = $empresa->categorias()->create(['nombre' => 'Pollos']);
    $producto = $empresa->productos()->create([
        'categoria_id' => $categoria->id,
        'nombre' => 'Pollo entero',
        'precio' => 90,
        'stock' => 10,
        'codigo' => 'P-001',
    ]);

    $response = $this->postJson('/api/pedidos', [
        'empresa_id' => $empresa->id,
        'cliente_nombre' => 'Juan Pérez',
        'cliente_telefono' => '70012345',
        'direccion' => 'Av. América #245',
        'notas' => 'Sin picante',
        'items' => [
            ['producto_id' => $producto->id, 'cantidad' => 2],
        ],
    ]);

    $response->assertCreated()
        ->assertJsonPath('pedido.estado', 'pendiente')
        ->assertJsonPath('pedido.total', 180)
        ->assertJsonPath('pedido.cliente_nombre', 'Juan Pérez')
        ->assertJsonCount(1, 'pedido.items');

    expect($producto->refresh()->stock)->toBe(8);

    $this->assertDatabaseHas('pedidos', [
        'empresa_id' => $empresa->id,
        'cliente_telefono' => '70012345',
        'total' => 180,
        'estado' => 'pendiente',
    ]);

    $this->assertDatabaseHas('pedido_items', [
        'producto_id' => $producto->id,
        'nombre' => 'Pollo entero',
        'precio' => 90,
        'cantidad' => 2,
        'subtotal' => 180,
    ]);
});

it('guarda un pedido sin datos de contacto: solo los productos son obligatorios', function () {
    $empresa = Empresa::factory()->create([
        'nombre' => 'Pollos Copacabana',
        'slug_tienda' => 'pollos-copacabana',
    ]);

    $categoria = $empresa->categorias()->create(['nombre' => 'Pollos']);
    $producto = $empresa->productos()->create([
        'categoria_id' => $categoria->id,
        'nombre' => 'Pollo entero',
        'precio' => 90,
        'stock' => 10,
        'codigo' => 'P-001',
    ]);

    $response = $this->postJson('/api/pedidos', [
        'empresa_id' => $empresa->id,
        'items' => [
            ['producto_id' => $producto->id, 'cantidad' => 1],
        ],
    ]);

    $response->assertCreated()
        ->assertJsonPath('pedido.estado', 'pendiente')
        ->assertJsonPath('pedido.cliente_nombre', null)
        ->assertJsonPath('pedido.cliente_telefono', null)
        ->assertJsonPath('pedido.direccion', null)
        ->assertJsonPath('pedido.notas', null);

    $this->assertDatabaseHas('pedidos', [
        'empresa_id' => $empresa->id,
        'cliente_nombre' => null,
        'cliente_telefono' => null,
        'total' => 90,
        'estado' => 'pendiente',
    ]);

    expect($producto->refresh()->stock)->toBe(9);
});

it('rechaza un pedido de otra empresa', function () {
    $empresa = Empresa::factory()->create([
        'nombre' => 'Pollos Copacabana',
        'slug_tienda' => 'pollos-copacabana',
    ]);

    $otraEmpresa = Empresa::factory()->create([
        'nombre' => 'Otra Tienda',
        'slug_tienda' => 'otra-tienda',
    ]);

    $categoria = $otraEmpresa->categorias()->create(['nombre' => 'General']);
    $producto = $otraEmpresa->productos()->create([
        'categoria_id' => $categoria->id,
        'nombre' => 'Producto ajeno',
        'precio' => 10,
        'stock' => 10,
        'codigo' => 'P-001',
    ]);

    $this->postJson('/api/pedidos', [
        'empresa_id' => $empresa->id,
        'cliente_nombre' => 'Juan',
        'cliente_telefono' => '70012345',
        'items' => [
            ['producto_id' => $producto->id, 'cantidad' => 1],
        ],
    ])->assertUnprocessable();
});

it('rechaza un pedido si no alcanza el stock', function () {
    $empresa = Empresa::factory()->create([
        'nombre' => 'Pollos Copacabana',
        'slug_tienda' => 'pollos-copacabana',
    ]);

    $categoria = $empresa->categorias()->create(['nombre' => 'Pollos']);
    $producto = $empresa->productos()->create([
        'categoria_id' => $categoria->id,
        'nombre' => 'Pollo entero',
        'precio' => 90,
        'stock' => 1,
        'codigo' => 'P-001',
    ]);

    $this->postJson('/api/pedidos', [
        'empresa_id' => $empresa->id,
        'cliente_nombre' => 'Juan',
        'cliente_telefono' => '70012345',
        'items' => [
            ['producto_id' => $producto->id, 'cantidad' => 2],
        ],
    ])->assertUnprocessable();

    expect($producto->refresh()->stock)->toBe(1);
});

it('devuelve stock al cancelar un pedido', function () {
    $user = usuarioConCatalogo();
    $empresa = $user->empresa;
    $producto = $empresa->productos()->first();

    $pedido = Pedido::create([
        'empresa_id' => $empresa->id,
        'cliente_nombre' => 'Juan',
        'cliente_telefono' => '70012345',
        'total' => $producto->precio,
        'estado' => 'pendiente',
    ]);

    $pedido->items()->create([
        'producto_id' => $producto->id,
        'nombre' => $producto->nombre,
        'precio' => $producto->precio,
        'cantidad' => 2,
        'subtotal' => $producto->precio * 2,
    ]);

    $producto->decrement('stock', 2);
    $stockAntes = $producto->refresh()->stock;

    $this->putJson("/api/pedidos/{$pedido->id}", ['estado' => 'cancelado'])
        ->assertOk()
        ->assertJsonPath('estado', 'cancelado');

    expect($producto->refresh()->stock)->toBe($stockAntes + 2);
});

it('lista los pedidos de la empresa autenticada', function () {
    $user = usuarioConCatalogo();
    $empresa = $user->empresa;
    $producto = $empresa->productos()->first();

    $pedido = Pedido::create([
        'empresa_id' => $empresa->id,
        'cliente_nombre' => 'Juan',
        'cliente_telefono' => '70012345',
        'total' => $producto->precio,
        'estado' => 'pendiente',
    ]);

    $pedido->items()->create([
        'producto_id' => $producto->id,
        'nombre' => $producto->nombre,
        'precio' => $producto->precio,
        'cantidad' => 1,
        'subtotal' => $producto->precio,
    ]);

    $this->getJson('/api/pedidos')
        ->assertOk()
        ->assertJsonPath('pedidos.0.id', $pedido->id)
        ->assertJsonPath('pedidos.0.cliente_nombre', 'Juan');
});
