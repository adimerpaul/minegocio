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
