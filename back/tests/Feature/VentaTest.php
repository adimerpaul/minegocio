<?php

use App\Models\User;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;

/** Crea un usuario con empresa y catálogo inicial, autenticado. */
function usuarioConCatalogo(): User
{
    Storage::fake('public');
    $user = User::factory()->create();
    Sanctum::actingAs($user);

    test()->postJson('/api/empresas', ['nombre' => 'Pollos Copacabana'])
        ->assertCreated();

    return $user->refresh();
}

it('registra la venta, congela precios y descuenta el stock', function () {
    $user = usuarioConCatalogo();
    $empresa = $user->empresa;

    $pollo = $empresa->productos()->where('nombre', 'Pollo entero')->first();
    $papas = $empresa->productos()->where('nombre', 'Papas fritas grandes')->first();

    $response = $this->postJson('/api/ventas', [
        'items' => [
            ['producto_id' => $pollo->id, 'cantidad' => 2],
            ['producto_id' => $papas->id, 'cantidad' => 3],
        ],
    ]);

    $response->assertCreated()
        ->assertJsonPath('venta.codigo', 'V-0001')
        ->assertJsonPath('venta.total', 2 * 90 + 3 * 10)
        ->assertJsonCount(2, 'venta.items');

    expect($pollo->refresh()->stock)->toBe(48)
        ->and($papas->refresh()->stock)->toBe(47);

    $this->assertDatabaseHas('venta_items', [
        'producto_id' => $pollo->id,
        'nombre' => 'Pollo entero',
        'cantidad' => 2,
        'subtotal' => 180,
    ]);
});

it('genera códigos correlativos por empresa', function () {
    $user = usuarioConCatalogo();
    $producto = $user->empresa->productos()->first();

    foreach (['V-0001', 'V-0002'] as $codigo) {
        $this->postJson('/api/ventas', [
            'items' => [['producto_id' => $producto->id, 'cantidad' => 1]],
        ])->assertCreated()->assertJsonPath('venta.codigo', $codigo);
    }
});

it('rechaza la venta si no alcanza el stock', function () {
    $user = usuarioConCatalogo();
    $producto = $user->empresa->productos()->first();
    $producto->update(['stock' => 1]);

    $this->postJson('/api/ventas', [
        'items' => [['producto_id' => $producto->id, 'cantidad' => 2]],
    ])->assertUnprocessable();

    expect($producto->refresh()->stock)->toBe(1);
    expect($user->empresa->ventas()->count())->toBe(0);
});

it('rechaza productos de otra empresa', function () {
    $user = usuarioConCatalogo();
    $ajeno = usuarioConCatalogo(); // segunda empresa con su catálogo
    $productoAjeno = $ajeno->empresa->productos()->first();

    Sanctum::actingAs($user);

    $this->postJson('/api/ventas', [
        'items' => [['producto_id' => $productoAjeno->id, 'cantidad' => 1]],
    ])->assertUnprocessable();
});

it('acumula cantidades si el mismo producto se repite en los items', function () {
    $user = usuarioConCatalogo();
    $producto = $user->empresa->productos()->first();

    $this->postJson('/api/ventas', [
        'items' => [
            ['producto_id' => $producto->id, 'cantidad' => 1],
            ['producto_id' => $producto->id, 'cantidad' => 2],
        ],
    ])->assertCreated()->assertJsonCount(1, 'venta.items');

    expect($producto->refresh()->stock)->toBe(47);
});

it('lista las ventas de la empresa con sus items', function () {
    $user = usuarioConCatalogo();
    $producto = $user->empresa->productos()->first();

    $this->postJson('/api/ventas', [
        'cliente' => 'Rosa Mamani',
        'items' => [['producto_id' => $producto->id, 'cantidad' => 1]],
    ])->assertCreated();

    $this->getJson('/api/ventas')
        ->assertOk()
        ->assertJsonCount(1, 'ventas')
        ->assertJsonPath('ventas.0.cliente', 'Rosa Mamani')
        ->assertJsonPath('ventas.0.items.0.cantidad', 1);
});

it('anula la venta y devuelve el stock de los items', function () {
    $user = usuarioConCatalogo();
    $producto = $user->empresa->productos()->first();

    $ventaId = $this->postJson('/api/ventas', [
        'items' => [['producto_id' => $producto->id, 'cantidad' => 3]],
    ])->assertCreated()->json('venta.id');

    expect($producto->refresh()->stock)->toBe(47);

    $this->postJson("/api/ventas/{$ventaId}/anular")
        ->assertOk()
        ->assertJsonPath('venta.estado', 'anulada');

    expect($producto->refresh()->stock)->toBe(50);
});

it('no permite anular dos veces la misma venta', function () {
    $user = usuarioConCatalogo();
    $producto = $user->empresa->productos()->first();

    $ventaId = $this->postJson('/api/ventas', [
        'items' => [['producto_id' => $producto->id, 'cantidad' => 2]],
    ])->json('venta.id');

    $this->postJson("/api/ventas/{$ventaId}/anular")->assertOk();
    $this->postJson("/api/ventas/{$ventaId}/anular")->assertConflict();

    // El stock se devolvió una sola vez.
    expect($producto->refresh()->stock)->toBe(50);
});

it('no permite anular ventas de otra empresa', function () {
    usuarioConCatalogo();
    $duenio = usuarioConCatalogo();

    $ventaId = $this->postJson('/api/ventas', [
        'items' => [['producto_id' => $duenio->empresa->productos()->first()->id, 'cantidad' => 1]],
    ])->json('venta.id');

    Sanctum::actingAs(User::where('id', '!=', $duenio->id)->first());

    $this->postJson("/api/ventas/{$ventaId}/anular")->assertNotFound();
});

it('exige items para vender', function () {
    usuarioConCatalogo();

    $this->postJson('/api/ventas', ['items' => []])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('items');
});

it('exige autenticación para vender', function () {
    $this->postJson('/api/ventas', ['items' => [['producto_id' => 1, 'cantidad' => 1]]])
        ->assertUnauthorized();
});
