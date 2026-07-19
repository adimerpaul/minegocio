<?php

use App\Models\Empresa;
use App\Models\User;
use App\Services\GoogleTokenVerifier;
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
        'slug_tienda' => 'comercial-andina',
        'nit' => '1023456019',
        'telefono' => '+591 700 12345',
        'direccion' => 'Av. América #245, Cochabamba',
        'correo' => 'ventas@andina.bo',
        'moneda' => 'BOB',
    ]);

    $response->assertCreated()
        ->assertJsonPath('empresa.nombre', 'Comercial Andina')
        ->assertJsonPath('empresa.slug_tienda', 'comercial-andina')
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
        'slug_tienda' => 'comercial-andina',
        'logo' => UploadedFile::fake()->image('logo.png'),
    ], ['Accept' => 'application/json']);

    $empresaId = $response->assertCreated()->json('empresa.id');

    expect($response->json('empresa.logo_path'))->toBe("/storage/logos/empresa-{$empresaId}.webp");
    Storage::disk('public')->assertExists("logos/empresa-{$empresaId}.webp");
});

it('asigna el logo por defecto si la empresa se crea sin logo', function () {
    Storage::fake('public');
    $user = usuarioSinEmpresa();
    Sanctum::actingAs($user);

    $response = $this->postJson('/api/empresas', ['nombre' => 'Comercial Andina', 'slug_tienda' => 'comercial-andina']);
    $empresaId = $response->assertCreated()->json('empresa.id');

    expect($response->json('empresa.logo_path'))
        ->toBe("/storage/logos/empresa-{$empresaId}.webp");
    expect(Storage::disk('public')->get("logos/empresa-{$empresaId}.webp"))
        ->toBe(file_get_contents(resource_path('logos/default.webp')));
});

it('rechaza registrar una segunda empresa para la misma cuenta', function () {
    $user = usuarioSinEmpresa();
    $user->empresa()->associate(Empresa::factory()->create())->save();
    Sanctum::actingAs($user);

    $this->postJson('/api/empresas', ['nombre' => 'Otra Empresa', 'slug_tienda' => 'otra-empresa'])
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
    $this->postJson('/api/empresas', ['nombre' => 'Comercial Andina', 'slug_tienda' => 'comercial-andina'])
        ->assertUnauthorized();
});

it('crea el catálogo de comida por defecto al registrar la empresa', function () {
    Storage::fake('public');
    $user = usuarioSinEmpresa();
    Sanctum::actingAs($user);

    $this->postJson('/api/empresas', ['nombre' => 'Pollos Copacabana', 'slug_tienda' => 'pollos-copacabana'])
        ->assertCreated();

    $empresa = $user->refresh()->empresa;

    expect($empresa->categorias()->pluck('nombre')->all())
        ->toBe(['Pollos', 'Extras', 'Jugos', 'Refrescos']);
    expect($empresa->productos()->count())->toBe(16);

    // Cada categoría lleva su banner empaquetado.
    $pollos = $empresa->categorias()->where('nombre', 'Pollos')->first();
    expect($pollos->imagen_path)->toBe("/storage/categorias/{$empresa->id}/pollos.webp");
    Storage::disk('public')->assertExists("categorias/{$empresa->id}/pollos.webp");

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

    $this->postJson('/api/empresas', ['nombre' => 'Pollos Copacabana', 'slug_tienda' => 'pollos-copacabana'])
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

    $this->postJson('/api/empresas', ['nombre' => 'Pollos Copacabana', 'slug_tienda' => 'pollos-copacabana'])
        ->assertCreated();

    $empresa = $user->refresh()->empresa;
    $guardada = Storage::disk('public')->get("productos/{$empresa->id}/pollo-entero.webp");

    expect($guardada)->toBe(file_get_contents(resource_path('productos/pollo-entero.webp')));
});

it('los productos y categorías usan borrado suave', function () {
    Storage::fake('public');
    $user = usuarioSinEmpresa();
    Sanctum::actingAs($user);

    $this->postJson('/api/empresas', ['nombre' => 'Pollos Copacabana', 'slug_tienda' => 'pollos-copacabana'])
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

    $this->postJson('/api/empresas', ['nombre' => 'Pollos Copacabana', 'slug_tienda' => 'pollos-copacabana'])
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

it('reemplaza el logo al actualizar y borra el archivo anterior', function () {
    Storage::fake('public');
    $user = usuarioSinEmpresa();
    Sanctum::actingAs($user);

    $this->post('/api/empresas', [
        'nombre' => 'Comercial Andina',
        'slug_tienda' => 'comercial-andina',
        'logo' => UploadedFile::fake()->image('logo.png'),
    ], ['Accept' => 'application/json'])->assertCreated();

    $empresa = $user->refresh()->empresa;
    $anterior = substr($empresa->logo_path, strlen('/storage/'));
    Storage::disk('public')->assertExists($anterior);

    // multipart con _method=PUT, como lo envía la app.
    $response = $this->post('/api/empresa', [
        '_method' => 'PUT',
        'nombre' => 'Comercial Andina',
        'logo' => UploadedFile::fake()->image('nuevo.png'),
    ], ['Accept' => 'application/json']);

    $logo = $response->assertOk()->json('empresa.logo_path');

    expect($logo)->toStartWith("/storage/logos/empresa-{$empresa->id}-")
        ->and($logo)->toEndWith('.webp');
    Storage::disk('public')->assertExists(substr($logo, strlen('/storage/')));
    Storage::disk('public')->assertMissing($anterior);
});

it('responde 404 al actualizar si la cuenta no tiene empresa', function () {
    Sanctum::actingAs(usuarioSinEmpresa());

    $this->putJson('/api/empresa', ['nombre' => 'Lo que sea'])
        ->assertNotFound();
});

it('permite crear una empresa nueva tras eliminar la cuenta anterior', function () {
    Storage::fake('public');

    // Usuario original con empresa.
    $original = User::factory()->create([
        'google_id' => '1122334455',
        'email' => 'juan@gmail.com',
    ]);
    $original->empresa()->associate(Empresa::factory()->create())->save();

    // Se elimina la cuenta (soft delete).
    $original->delete();

    // El mismo Google ID inicia sesión: se crea un usuario nuevo.
    $this->mock(GoogleTokenVerifier::class)
        ->shouldReceive('verify')
        ->andReturn([
            'iss' => 'https://accounts.google.com',
            'sub' => '1122334455',
            'name' => 'Juan Pérez',
            'email' => 'juan@gmail.com',
            'email_verified' => true,
        ]);

    $login = $this->postJson('/api/auth/google', ['id_token' => 'token-valido']);
    $login->assertOk()->assertJsonPath('is_new', true);

    $nuevoUserId = $login->json('user.id');
    expect($nuevoUserId)->not->toBe($original->id);

    // El nuevo usuario puede registrar una empresa desde cero.
    Sanctum::actingAs(User::find($nuevoUserId));

    $this->postJson('/api/empresas', ['nombre' => 'Nuevo Negocio', 'slug_tienda' => 'nuevo-negocio'])
        ->assertCreated()
        ->assertJsonPath('empresa.nombre', 'Nuevo Negocio')
        ->assertJsonPath('user.empresa.nombre', 'Nuevo Negocio');
});

it('normaliza el slug de tienda a minúsculas, sin ñ y sin espacios', function () {
    Storage::fake('public');
    Sanctum::actingAs(usuarioSinEmpresa());

    $this->postJson('/api/empresas', [
        'nombre' => 'Pollos Copacabana',
        'slug_tienda' => 'Pollos Copacabaña 2024',
    ])
        ->assertCreated()
        ->assertJsonPath('empresa.slug_tienda', 'pollos-copacabana-2024');
});

it('exige el slug de tienda al crear la empresa', function () {
    Sanctum::actingAs(usuarioSinEmpresa());

    $this->postJson('/api/empresas', ['nombre' => 'Sin Slug'])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('slug_tienda');
});

it('rechaza un slug de tienda que ya está en uso', function () {
    Storage::fake('public');
    Empresa::factory()->create(['slug_tienda' => 'mi-tienda']);
    Sanctum::actingAs(usuarioSinEmpresa());

    $this->postJson('/api/empresas', [
        'nombre' => 'Otra Tienda',
        'slug_tienda' => 'mi-tienda',
    ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('slug_tienda');
});

it('permite conservar el mismo slug al actualizar la empresa', function () {
    $user = usuarioSinEmpresa();
    $user->empresa()->associate(Empresa::factory()->create([
        'nombre' => 'Original',
        'slug_tienda' => 'mi-tienda',
    ]))->save();
    Sanctum::actingAs($user);

    $this->putJson('/api/empresa', [
        'nombre' => 'Original Renovada',
        'slug_tienda' => 'mi-tienda',
    ])
        ->assertOk()
        ->assertJsonPath('empresa.slug_tienda', 'mi-tienda');
});

it('rechaza cambiar el slug por uno que ya existe', function () {
    Empresa::factory()->create(['slug_tienda' => 'ocupado']);
    $user = usuarioSinEmpresa();
    $user->empresa()->associate(Empresa::factory()->create([
        'slug_tienda' => 'mi-tienda',
    ]))->save();
    Sanctum::actingAs($user);

    $this->putJson('/api/empresa', [
        'nombre' => $user->empresa->nombre,
        'slug_tienda' => 'ocupado',
    ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('slug_tienda');
});

it('indica disponibilidad de un slug mediante el endpoint público', function () {
    Empresa::factory()->create(['slug_tienda' => 'ocupado']);
    Sanctum::actingAs(usuarioSinEmpresa());

    $this->getJson('/api/empresas/slug-disponible/libre')
        ->assertOk()
        ->assertJsonPath('disponible', true)
        ->assertJsonPath('slug', 'libre');

    $this->getJson('/api/empresas/slug-disponible/ocupado')
        ->assertOk()
        ->assertJsonPath('disponible', false);
});
