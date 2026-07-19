<?php

use App\Models\Categoria;
use App\Models\Empresa;

it('crea una categoría en la empresa autenticada', function () {
    $user = usuarioConCatalogo();
    $empresa = $user->empresa;

    $this->postJson('/api/categorias', [
        'nombre' => 'Bebidas',
        'descripcion' => 'Jugos y refrescos',
    ])
        ->assertCreated()
        ->assertJsonPath('categoria.nombre', 'Bebidas')
        ->assertJsonPath('categoria.descripcion', 'Jugos y refrescos')
        ->assertJsonPath('categoria.empresa_id', $empresa->id);
});

it('actualiza una categoría de la empresa', function () {
    $user = usuarioConCatalogo();
    $categoria = $user->empresa->categorias()->first();

    $this->putJson("/api/categorias/{$categoria->id}", [
        'nombre' => 'Bebidas frías',
        'descripcion' => 'Refrescantes',
    ])
        ->assertOk()
        ->assertJsonPath('categoria.nombre', 'Bebidas frías')
        ->assertJsonPath('categoria.descripcion', 'Refrescantes');
});

it('elimina una categoría sin productos', function () {
    $user = usuarioConCatalogo();
    $categoria = $user->empresa->categorias()->create([
        'nombre' => 'Temporal',
    ]);

    $this->deleteJson("/api/categorias/{$categoria->id}")
        ->assertOk()
        ->assertJsonPath('message', 'Categoría eliminada.');

    expect(Categoria::find($categoria->id))->toBeNull();
});

it('no elimina una categoría con productos', function () {
    $user = usuarioConCatalogo();
    $categoria = $user->empresa->categorias()->first();

    $this->deleteJson("/api/categorias/{$categoria->id}")
        ->assertStatus(409);
});

it('no permite editar categorías de otra empresa', function () {
    $user = usuarioConCatalogo();
    $otraEmpresa = Empresa::factory()->create();
    $ajena = $otraEmpresa->categorias()->create(['nombre' => 'Ajena']);

    $this->putJson("/api/categorias/{$ajena->id}", [
        'nombre' => 'Hackeada',
    ])->assertNotFound();

    expect($ajena->refresh()->nombre)->toBe('Ajena');
});

it('no permite eliminar categorías de otra empresa', function () {
    $user = usuarioConCatalogo();
    $otraEmpresa = Empresa::factory()->create();
    $ajena = $otraEmpresa->categorias()->create(['nombre' => 'Ajena']);

    $this->deleteJson("/api/categorias/{$ajena->id}")->assertNotFound();

    expect($ajena->fresh())->not->toBeNull();
});

it('rechaza crear una categoría sin nombre', function () {
    usuarioConCatalogo();

    $this->postJson('/api/categorias', [])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('nombre');
});
