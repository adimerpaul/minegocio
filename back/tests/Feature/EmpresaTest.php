<?php

use App\Models\Empresa;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;

function usuarioSinEmpresa(): User
{
    return User::factory()->create();
}

it('crea la empresa y la vincula al usuario autenticado', function () {
    Storage::fake('public');
    $user = usuarioSinEmpresa();
    Sanctum::actingAs($user);

    $response = $this->postJson('/api/empresas', [
        'nombre' => 'Comercial Andina',
        'nit' => '1023456019',
        'telefono' => '+591 700 12345',
        'direccion' => 'Av. América #245, Cochabamba',
        'correo' => 'ventas@andina.bo',
        'moneda' => 'BOB',
    ]);

    $response->assertCreated()
        ->assertJsonPath('empresa.nombre', 'Comercial Andina')
        ->assertJsonPath('empresa.moneda', 'BOB')
        ->assertJsonPath('user.empresa.nit', '1023456019');

    expect($user->refresh()->empresa->nombre)->toBe('Comercial Andina');
});

it('guarda el logo como webp si se envía', function () {
    Storage::fake('public');
    Sanctum::actingAs(usuarioSinEmpresa());

    // multipart (no JSON) porque incluye un archivo
    $response = $this->post('/api/empresas', [
        'nombre' => 'Comercial Andina',
        'logo' => UploadedFile::fake()->image('logo.png'),
    ], ['Accept' => 'application/json']);

    $empresaId = $response->assertCreated()->json('empresa.id');

    expect($response->json('empresa.logo_path'))->toBe("/storage/logos/empresa-{$empresaId}.webp");
    Storage::disk('public')->assertExists("logos/empresa-{$empresaId}.webp");
});

it('rechaza registrar una segunda empresa para la misma cuenta', function () {
    $user = usuarioSinEmpresa();
    $user->empresa()->associate(Empresa::factory()->create())->save();
    Sanctum::actingAs($user);

    $this->postJson('/api/empresas', ['nombre' => 'Otra Empresa'])
        ->assertConflict();

    expect(Empresa::count())->toBe(1);
});

it('exige el nombre comercial', function () {
    Sanctum::actingAs(usuarioSinEmpresa());

    $this->postJson('/api/empresas', ['nit' => '123'])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('nombre');
});

it('exige autenticación para crear la empresa', function () {
    $this->postJson('/api/empresas', ['nombre' => 'Comercial Andina'])
        ->assertUnauthorized();
});

it('crea el catálogo de comida por defecto al registrar la empresa', function () {
    Storage::fake('public');
    $user = usuarioSinEmpresa();
    Sanctum::actingAs($user);

    $this->postJson('/api/empresas', ['nombre' => 'Pollos Copacabana'])
        ->assertCreated();

    $empresa = $user->refresh()->empresa;

    expect($empresa->categorias()->pluck('nombre')->all())
        ->toBe(['Pollos', 'Extras', 'Jugos', 'Refrescos']);
    expect($empresa->productos()->count())->toBe(16);

    $pollo = $empresa->productos()->where('nombre', 'Pollo entero')->first();
    expect($pollo->precio)->toBe(90.0)
        ->and($pollo->codigo)->toBe('P-001')
        ->and($pollo->imagen_path)->toBe("/storage/productos/{$empresa->id}/pollo-entero.webp");

    Storage::disk('public')->assertExists("productos/{$empresa->id}/pollo-entero.webp");
});

it('devuelve el catálogo de la empresa en /api/productos', function () {
    Storage::fake('public');
    $user = usuarioSinEmpresa();
    Sanctum::actingAs($user);

    $this->postJson('/api/empresas', ['nombre' => 'Pollos Copacabana'])
        ->assertCreated();

    $this->getJson('/api/productos')
        ->assertOk()
        ->assertJsonCount(4, 'categorias')
        ->assertJsonCount(16, 'productos')
        ->assertJsonPath('productos.0.nombre', 'Pollo entero')
        ->assertJsonPath('productos.0.precio', 90);
});

it('responde 404 en /api/productos si la cuenta no tiene empresa', function () {
    Sanctum::actingAs(usuarioSinEmpresa());

    $this->getJson('/api/productos')->assertNotFound();
});

it('usa la foto real empaquetada del producto, no un placeholder', function () {
    Storage::fake('public');
    $user = usuarioSinEmpresa();
    Sanctum::actingAs($user);

    $this->postJson('/api/empresas', ['nombre' => 'Pollos Copacabana'])
        ->assertCreated();

    $empresa = $user->refresh()->empresa;
    $guardada = Storage::disk('public')->get("productos/{$empresa->id}/pollo-entero.webp");

    expect($guardada)->toBe(file_get_contents(resource_path('productos/pollo-entero.webp')));
});

it('los productos y categorías usan borrado suave', function () {
    Storage::fake('public');
    $user = usuarioSinEmpresa();
    Sanctum::actingAs($user);

    $this->postJson('/api/empresas', ['nombre' => 'Pollos Copacabana'])
        ->assertCreated();

    $empresa = $user->refresh()->empresa;
    $producto = $empresa->productos()->first();
    $categoria = $empresa->categorias()->first();

    $producto->delete();
    $categoria->delete();

    $this->assertSoftDeleted('productos', ['id' => $producto->id]);
    $this->assertSoftDeleted('categorias', ['id' => $categoria->id]);

    // Los borrados no aparecen en el catálogo de la API.
    $this->getJson('/api/productos')
        ->assertOk()
        ->assertJsonCount(3, 'categorias')
        ->assertJsonCount(15, 'productos');
});

it('registra auditoría de los cambios de la empresa', function () {
    // Los tests corren "en consola"; en producción las peticiones HTTP
    // siempre se auditan.
    config(['audit.console' => true]);

    Storage::fake('public');
    $user = usuarioSinEmpresa();
    Sanctum::actingAs($user);

    $this->postJson('/api/empresas', ['nombre' => 'Pollos Copacabana'])
        ->assertCreated();

    $this->putJson('/api/empresa', ['nombre' => 'Pollos Renovados'])
        ->assertOk();

    $this->assertDatabaseHas('audits', [
        'auditable_type' => Empresa::class,
        'event' => 'created',
        'user_id' => $user->id,
    ]);
    $this->assertDatabaseHas('audits', [
        'auditable_type' => Empresa::class,
        'event' => 'updated',
        'user_id' => $user->id,
    ]);
});

it('actualiza los datos de la empresa del usuario', function () {
    $user = usuarioSinEmpresa();
    $user->empresa()->associate(Empresa::factory()->create(['nombre' => 'Original']))->save();
    Sanctum::actingAs($user);

    $this->putJson('/api/empresa', [
        'nombre' => 'Comercial Andina Renovada',
        'moneda' => 'USD',
    ])
        ->assertOk()
        ->assertJsonPath('empresa.nombre', 'Comercial Andina Renovada')
        ->assertJsonPath('empresa.moneda', 'USD');
});

it('responde 404 al actualizar si la cuenta no tiene empresa', function () {
    Sanctum::actingAs(usuarioSinEmpresa());

    $this->putJson('/api/empresa', ['nombre' => 'Lo que sea'])
        ->assertNotFound();
});
