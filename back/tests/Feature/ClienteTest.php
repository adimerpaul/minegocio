<?php

use App\Models\User;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;

/** Crea un usuario con empresa (catálogo y clientes iniciales), autenticado. */
function usuarioConClientes(): User
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

it('crea el cliente S/N y 10 ficticios al registrar la empresa', function () {
    $user = usuarioConClientes();

    expect($user->empresa->clientes()->count())->toBe(11)
        ->and($user->empresa->clientes()->where('es_default', true)->count())->toBe(1)
        ->and($user->empresa->clientes()->where('es_default', true)->first()->nombre)->toBe('S/N');
});

it('lista los clientes con el S/N primero', function () {
    usuarioConClientes();

    $response = $this->getJson('/api/clientes')->assertOk();

    expect($response->json('clientes'))->toHaveCount(11)
        ->and($response->json('clientes.0.nombre'))->toBe('S/N')
        ->and($response->json('clientes.0.es_default'))->toBeTrue();
});

it('siembra los clientes iniciales al listar si la empresa nunca tuvo', function () {
    $user = usuarioConClientes();
    $user->empresa->clientes()->forceDelete(); // como una empresa anterior al módulo

    $response = $this->getJson('/api/clientes')->assertOk();

    expect($response->json('clientes'))->toHaveCount(11)
        ->and($response->json('clientes.0.nombre'))->toBe('S/N');
});

it('solo repone el S/N si la empresa ya tuvo clientes', function () {
    $user = usuarioConClientes();
    $user->empresa->clientes()->delete(); // borrado suave: sí tuvo clientes

    $response = $this->getJson('/api/clientes')->assertOk();

    expect($response->json('clientes'))->toHaveCount(1)
        ->and($response->json('clientes.0.nombre'))->toBe('S/N');
});

it('registra, edita y borra un cliente', function () {
    usuarioConClientes();

    $id = $this->postJson('/api/clientes', [
        'nombre' => 'Julia Poma',
        'telefono' => '70000001',
    ])->assertCreated()->json('cliente.id');

    $this->putJson("/api/clientes/{$id}", ['nombre' => 'Julia Poma Vda. de Rojas'])
        ->assertOk()
        ->assertJsonPath('cliente.nombre', 'Julia Poma Vda. de Rojas');

    $this->deleteJson("/api/clientes/{$id}")->assertOk();
    $this->assertSoftDeleted('clientes', ['id' => $id]);
});

it('no permite editar ni borrar el cliente S/N', function () {
    $user = usuarioConClientes();
    $default = $user->empresa->clientes()->where('es_default', true)->first();

    $this->putJson("/api/clientes/{$default->id}", ['nombre' => 'Otro'])
        ->assertConflict();
    $this->deleteJson("/api/clientes/{$default->id}")->assertConflict();
});

it('no permite tocar clientes de otra empresa', function () {
    $ajeno = usuarioConClientes();
    $clienteAjeno = $ajeno->empresa->clientes()->where('es_default', false)->first();

    usuarioConClientes();

    $this->putJson("/api/clientes/{$clienteAjeno->id}", ['nombre' => 'Hackeado'])
        ->assertNotFound();
    $this->deleteJson("/api/clientes/{$clienteAjeno->id}")->assertNotFound();
});

it('la venta usa el cliente S/N si no se elige uno', function () {
    $user = usuarioConClientes();
    $producto = $user->empresa->productos()->first();

    $this->postJson('/api/ventas', [
        'items' => [['producto_id' => $producto->id, 'cantidad' => 1]],
    ])->assertCreated()
        ->assertJsonPath('venta.cliente', 'S/N');

    $default = $user->empresa->clientes()->where('es_default', true)->first();
    $this->assertDatabaseHas('ventas', ['cliente_id' => $default->id]);
});

it('la venta congela el nombre del cliente elegido', function () {
    $user = usuarioConClientes();
    $producto = $user->empresa->productos()->first();
    $cliente = $user->empresa->clientes()->where('nombre', 'Rosa Mamani')->first();

    $this->postJson('/api/ventas', [
        'cliente_id' => $cliente->id,
        'items' => [['producto_id' => $producto->id, 'cantidad' => 1]],
    ])->assertCreated()
        ->assertJsonPath('venta.cliente', 'Rosa Mamani')
        ->assertJsonPath('venta.cliente_id', $cliente->id);

    // Aunque el cliente se borre después, la venta conserva su nombre.
    $cliente->delete();
    $this->getJson('/api/ventas')
        ->assertOk()
        ->assertJsonPath('ventas.0.cliente', 'Rosa Mamani');
});

it('rechaza la venta con un cliente de otra empresa', function () {
    $ajeno = usuarioConClientes();
    $clienteAjeno = $ajeno->empresa->clientes()->first();

    $user = usuarioConClientes();
    $producto = $user->empresa->productos()->first();

    $this->postJson('/api/ventas', [
        'cliente_id' => $clienteAjeno->id,
        'items' => [['producto_id' => $producto->id, 'cantidad' => 1]],
    ])->assertUnprocessable()
        ->assertJsonValidationErrors('cliente_id');
});

it('exige autenticación para los clientes', function () {
    $this->getJson('/api/clientes')->assertUnauthorized();
});
