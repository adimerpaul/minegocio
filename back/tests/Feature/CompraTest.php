<?php

use App\Models\User;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;

/** Crea un usuario con empresa (catálogo y proveedores iniciales), autenticado. */
function usuarioConCompras(): User
{
    Storage::fake('public');
    $user = User::factory()->create();
    Sanctum::actingAs($user);

    test()->postJson('/api/empresas', [
        'nombre' => 'Pollos Copacabana',
        'slug_tienda' => 'pollos-copacabana-'.$user->id,
    ])->assertCreated();

    return $user->refresh();
}

it('crea el proveedor S/N y 5 ficticios al registrar la empresa', function () {
    $user = usuarioConCompras();

    expect($user->empresa->proveedores()->count())->toBe(6)
        ->and($user->empresa->proveedores()->where('es_default', true)->first()->nombre)->toBe('S/N');
});

it('lista los proveedores con el S/N primero', function () {
    usuarioConCompras();

    $response = $this->getJson('/api/proveedores')->assertOk();

    expect($response->json('proveedores'))->toHaveCount(6)
        ->and($response->json('proveedores.0.nombre'))->toBe('S/N')
        ->and($response->json('proveedores.0.es_default'))->toBeTrue();
});

it('registra, edita y borra un proveedor', function () {
    usuarioConCompras();

    $id = $this->postJson('/api/proveedores', [
        'nombre' => 'Granja Los Andes',
        'telefono' => '70000009',
    ])->assertCreated()->json('proveedor.id');

    $this->putJson("/api/proveedores/{$id}", ['nombre' => 'Granja Los Andes SRL'])
        ->assertOk()
        ->assertJsonPath('proveedor.nombre', 'Granja Los Andes SRL');

    $this->deleteJson("/api/proveedores/{$id}")->assertOk();
    $this->assertSoftDeleted('proveedores', ['id' => $id]);
});

it('no permite editar ni borrar el proveedor S/N', function () {
    $user = usuarioConCompras();
    $default = $user->empresa->proveedores()->where('es_default', true)->first();

    $this->putJson("/api/proveedores/{$default->id}", ['nombre' => 'Otro'])
        ->assertConflict();
    $this->deleteJson("/api/proveedores/{$default->id}")->assertConflict();
});

it('no permite tocar proveedores de otra empresa', function () {
    $ajeno = usuarioConCompras();
    $proveedorAjeno = $ajeno->empresa->proveedores()->where('es_default', false)->first();

    usuarioConCompras();

    $this->putJson("/api/proveedores/{$proveedorAjeno->id}", ['nombre' => 'X'])
        ->assertNotFound();
    $this->deleteJson("/api/proveedores/{$proveedorAjeno->id}")->assertNotFound();
});

it('registra la compra, congela costos y aumenta el stock', function () {
    $user = usuarioConCompras();
    $empresa = $user->empresa;

    $pollo = $empresa->productos()->where('nombre', 'Pollo entero')->first();
    $papas = $empresa->productos()->where('nombre', 'Papas fritas grandes')->first();

    $response = $this->postJson('/api/compras', [
        'items' => [
            ['producto_id' => $pollo->id, 'cantidad' => 10, 'costo' => 60],
            ['producto_id' => $papas->id, 'cantidad' => 20, 'costo' => 4.5],
        ],
    ]);

    $response->assertCreated()
        ->assertJsonPath('compra.codigo', 'C-0001')
        ->assertJsonPath('compra.proveedor', 'S/N')
        ->assertJsonPath('compra.total', 690)
        ->assertJsonCount(2, 'compra.items');

    expect($pollo->refresh()->stock)->toBe(60)
        ->and($papas->refresh()->stock)->toBe(70);

    $this->assertDatabaseHas('compra_items', [
        'producto_id' => $pollo->id,
        'nombre' => 'Pollo entero',
        'costo' => 60,
        'cantidad' => 10,
        'subtotal' => 600,
    ]);
});

it('genera códigos correlativos de compra por empresa', function () {
    $user = usuarioConCompras();
    $producto = $user->empresa->productos()->first();

    foreach (['C-0001', 'C-0002'] as $codigo) {
        $this->postJson('/api/compras', [
            'items' => [['producto_id' => $producto->id, 'cantidad' => 1, 'costo' => 10]],
        ])->assertCreated()->assertJsonPath('compra.codigo', $codigo);
    }
});

it('la compra congela el nombre del proveedor elegido', function () {
    $user = usuarioConCompras();
    $producto = $user->empresa->productos()->first();
    $proveedor = $user->empresa->proveedores()->where('nombre', 'Avícola San Pedro')->first();

    $this->postJson('/api/compras', [
        'proveedor_id' => $proveedor->id,
        'items' => [['producto_id' => $producto->id, 'cantidad' => 1, 'costo' => 10]],
    ])->assertCreated()
        ->assertJsonPath('compra.proveedor', 'Avícola San Pedro');

    $proveedor->delete();
    $this->getJson('/api/compras')
        ->assertOk()
        ->assertJsonPath('compras.0.proveedor', 'Avícola San Pedro');
});

it('rechaza la compra con proveedor o producto de otra empresa', function () {
    $ajeno = usuarioConCompras();
    $proveedorAjeno = $ajeno->empresa->proveedores()->first();
    $productoAjeno = $ajeno->empresa->productos()->first();

    $user = usuarioConCompras();
    $producto = $user->empresa->productos()->first();

    $this->postJson('/api/compras', [
        'proveedor_id' => $proveedorAjeno->id,
        'items' => [['producto_id' => $producto->id, 'cantidad' => 1, 'costo' => 10]],
    ])->assertUnprocessable()->assertJsonValidationErrors('proveedor_id');

    $this->postJson('/api/compras', [
        'items' => [['producto_id' => $productoAjeno->id, 'cantidad' => 1, 'costo' => 10]],
    ])->assertUnprocessable()->assertJsonValidationErrors('items');
});

it('anula la compra y descuenta el stock de los items', function () {
    $user = usuarioConCompras();
    $producto = $user->empresa->productos()->first();

    $compraId = $this->postJson('/api/compras', [
        'items' => [['producto_id' => $producto->id, 'cantidad' => 5, 'costo' => 10]],
    ])->assertCreated()->json('compra.id');

    expect($producto->refresh()->stock)->toBe(55);

    $this->postJson("/api/compras/{$compraId}/anular")
        ->assertOk()
        ->assertJsonPath('compra.estado', 'anulada');

    expect($producto->refresh()->stock)->toBe(50);

    // No se puede anular dos veces.
    $this->postJson("/api/compras/{$compraId}/anular")->assertConflict();
    expect($producto->refresh()->stock)->toBe(50);
});

it('acepta gastos libres sin producto y no tocan el stock', function () {
    $user = usuarioConCompras();
    $producto = $user->empresa->productos()->first();

    // Compra mixta: un producto del catálogo y dos gastos libres.
    $response = $this->postJson('/api/compras', [
        'items' => [
            ['producto_id' => $producto->id, 'cantidad' => 2, 'costo' => 10],
            ['nombre' => 'Aceite 5 L', 'cantidad' => 3, 'costo' => 40],
            ['nombre' => 'Garrafa de gas', 'cantidad' => 1, 'costo' => 22.5],
        ],
    ]);

    $response->assertCreated()
        ->assertJsonPath('compra.total', 2 * 10 + 3 * 40 + 22.5)
        ->assertJsonCount(3, 'compra.items')
        ->assertJsonPath('compra.items.1.nombre', 'Aceite 5 L')
        ->assertJsonPath('compra.items.1.producto_id', null);

    // Solo el producto del catálogo aumentó el stock.
    expect($producto->refresh()->stock)->toBe(52);

    // Al anular, solo se descuenta el stock del producto del catálogo.
    $compraId = $response->json('compra.id');
    $this->postJson("/api/compras/{$compraId}/anular")->assertOk();
    expect($producto->refresh()->stock)->toBe(50);
});

it('exige nombre en los items sin producto', function () {
    usuarioConCompras();

    $this->postJson('/api/compras', [
        'items' => [['cantidad' => 1, 'costo' => 10]],
    ])->assertUnprocessable()
        ->assertJsonValidationErrors('items.0.nombre');
});

it('exige items y costo para comprar', function () {
    $user = usuarioConCompras();
    $producto = $user->empresa->productos()->first();

    $this->postJson('/api/compras', ['items' => []])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('items');

    $this->postJson('/api/compras', [
        'items' => [['producto_id' => $producto->id, 'cantidad' => 1]],
    ])->assertUnprocessable();
});

it('exige autenticación para compras y proveedores', function () {
    $this->getJson('/api/proveedores')->assertUnauthorized();
    $this->getJson('/api/compras')->assertUnauthorized();
    $this->postJson('/api/compras', [])->assertUnauthorized();
});
