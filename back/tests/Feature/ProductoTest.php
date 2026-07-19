<?php

use App\Models\Empresa;
use App\Models\Producto;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;

// usuarioConCatalogo() está definido en VentaTest.php (Pest comparte los
// helpers de archivo entre tests de Feature).

it('crea un producto en la empresa autenticada', function () {
    $user = usuarioConCatalogo();
    $empresa = $user->empresa;
    $categoria = $empresa->categorias()->first();

    $this->postJson('/api/productos', [
        'nombre' => 'Pollo broaster',
        'precio' => 85,
        'stock' => 20,
        'stock_minimo' => 5,
        'codigo_barras' => '1234567890123',
        'categoria_id' => $categoria->id,
    ])
        ->assertCreated()
        ->assertJsonPath('producto.nombre', 'Pollo broaster')
        ->assertJsonPath('producto.precio', 85)
        ->assertJsonPath('producto.stock', 20)
        ->assertJsonPath('producto.categoria_id', $categoria->id);

    $this->assertDatabaseHas('productos', [
        'empresa_id' => $empresa->id,
        'nombre' => 'Pollo broaster',
    ]);

    $creado = $empresa->productos()->where('nombre', 'Pollo broaster')->first();
    expect($creado->codigo)->toMatch('/^P-\d{3}$/');
});

it('actualiza los datos de un producto', function () {
    $user = usuarioConCatalogo();
    $empresa = $user->empresa;

    $producto = $empresa->productos()->where('nombre', 'Pollo entero')->first();
    $extras = $empresa->categorias()->where('nombre', 'Extras')->first();

    $this->putJson("/api/productos/{$producto->id}", [
        'nombre' => 'Pollo entero especial',
        'precio' => 95.5,
        'stock' => 30,
        'stock_minimo' => 8,
        'codigo_barras' => '7771234567890',
        'categoria_id' => $extras->id,
    ])
        ->assertOk()
        ->assertJsonPath('producto.nombre', 'Pollo entero especial')
        ->assertJsonPath('producto.precio', 95.5)
        ->assertJsonPath('producto.stock', 30)
        ->assertJsonPath('producto.stock_minimo', 8)
        ->assertJsonPath('producto.codigo_barras', '7771234567890')
        ->assertJsonPath('producto.categoria_id', $extras->id);

    expect($producto->refresh()->nombre)->toBe('Pollo entero especial');
});

it('permite borrar el código de barras enviándolo vacío', function () {
    $user = usuarioConCatalogo();
    $producto = $user->empresa->productos()->first();
    $producto->update(['codigo_barras' => '123']);

    $this->putJson("/api/productos/{$producto->id}", [
        'nombre' => $producto->nombre,
        'precio' => $producto->precio,
        'stock' => $producto->stock,
        'stock_minimo' => 5,
        'codigo_barras' => '',
    ])
        ->assertOk()
        ->assertJsonPath('producto.codigo_barras', null);
});

it('permite dejar el producto sin categoría', function () {
    $user = usuarioConCatalogo();
    $producto = $user->empresa->productos()->first();

    $this->putJson("/api/productos/{$producto->id}", [
        'nombre' => $producto->nombre,
        'precio' => $producto->precio,
        'stock' => $producto->stock,
        'stock_minimo' => 5,
        'categoria_id' => null,
    ])
        ->assertOk()
        ->assertJsonPath('producto.categoria_id', null);
});

it('guarda la imagen nueva como webp y borra la anterior', function () {
    $user = usuarioConCatalogo();
    $empresa = $user->empresa;
    $producto = $empresa->productos()->first();

    $anterior = substr($producto->imagen_path, strlen('/storage/'));
    Storage::disk('public')->assertExists($anterior);

    // multipart (no JSON) porque incluye un archivo; _method=PUT como
    // lo envía la app (PHP no parsea multipart en PUT directo).
    $response = $this->post("/api/productos/{$producto->id}", [
        '_method' => 'PUT',
        'nombre' => $producto->nombre,
        'precio' => $producto->precio,
        'stock' => $producto->stock,
        'stock_minimo' => 5,
        'imagen' => UploadedFile::fake()->image('foto.png'),
    ], ['Accept' => 'application/json']);

    $imagen = $response->assertOk()->json('producto.imagen_path');

    expect($imagen)->toStartWith("/storage/productos/{$empresa->id}/producto-{$producto->id}-")
        ->and($imagen)->toEndWith('.webp');
    Storage::disk('public')->assertExists(substr($imagen, strlen('/storage/')));
    Storage::disk('public')->assertMissing($anterior);
});

it('rechaza categorías de otra empresa', function () {
    $user = usuarioConCatalogo();
    $producto = $user->empresa->productos()->first();

    $otraEmpresa = Empresa::factory()->create();
    $ajena = $otraEmpresa->categorias()->create(['nombre' => 'Ajena']);

    $this->putJson("/api/productos/{$producto->id}", [
        'nombre' => $producto->nombre,
        'precio' => $producto->precio,
        'stock' => $producto->stock,
        'stock_minimo' => 5,
        'categoria_id' => $ajena->id,
    ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('categoria_id');
});

it('responde 404 con un producto de otra empresa', function () {
    $user = usuarioConCatalogo();
    $producto = $user->empresa->productos()->first();

    $intruso = User::factory()->create();
    $intruso->empresa()->associate(Empresa::factory()->create())->save();
    Sanctum::actingAs($intruso);

    $this->putJson("/api/productos/{$producto->id}", [
        'nombre' => 'Hackeado',
        'precio' => 1,
        'stock' => 1,
        'stock_minimo' => 1,
    ])->assertNotFound();

    expect($producto->refresh()->nombre)->not->toBe('Hackeado');
});

it('valida los campos obligatorios del producto', function () {
    $user = usuarioConCatalogo();
    $producto = $user->empresa->productos()->first();

    $this->putJson("/api/productos/{$producto->id}", [
        'precio' => -5,
        'stock' => 'muchos',
    ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['nombre', 'precio', 'stock', 'stock_minimo']);
});

it('registra auditoría al modificar el producto', function () {
    config(['audit.console' => true]);

    $user = usuarioConCatalogo();
    $producto = $user->empresa->productos()->first();

    $this->putJson("/api/productos/{$producto->id}", [
        'nombre' => 'Pollo auditado',
        'precio' => 99,
        'stock' => 10,
        'stock_minimo' => 2,
    ])->assertOk();

    $this->assertDatabaseHas('audits', [
        'auditable_type' => Producto::class,
        'auditable_id' => $producto->id,
        'event' => 'updated',
        'user_id' => $user->id,
    ]);
});
