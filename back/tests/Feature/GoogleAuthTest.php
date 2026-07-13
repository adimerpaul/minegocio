<?php

use App\Models\User;
use App\Services\FirebaseTokenVerifier;

function fakeClaims(array $overrides = []): array
{
    return array_merge([
        'sub' => 'firebase-uid-123',
        'name' => 'Juan Pérez',
        'email' => 'juan@gmail.com',
        'email_verified' => true,
        'picture' => 'https://lh3.googleusercontent.com/foto.jpg',
        'firebase' => [
            'identities' => ['google.com' => ['1122334455']],
            'sign_in_provider' => 'google.com',
        ],
    ], $overrides);
}

it('crea el usuario con sus datos de Google la primera vez', function () {
    $this->mock(FirebaseTokenVerifier::class)
        ->shouldReceive('verify')
        ->andReturn(fakeClaims());

    $response = $this->postJson('/api/auth/google', ['id_token' => 'token-valido']);

    $response->assertOk()
        ->assertJsonPath('is_new', true)
        ->assertJsonPath('user.email', 'juan@gmail.com')
        ->assertJsonPath('user.google_id', '1122334455')
        ->assertJsonPath('user.photo_url', 'https://lh3.googleusercontent.com/foto.jpg');

    expect($response->json('token'))->toBeString()->not->toBeEmpty();

    $this->assertDatabaseHas('users', [
        'firebase_uid' => 'firebase-uid-123',
        'google_id' => '1122334455',
        'name' => 'Juan Pérez',
    ]);
});

it('no duplica ni sobrescribe al usuario en logins posteriores', function () {
    User::create([
        'firebase_uid' => 'firebase-uid-123',
        'google_id' => '1122334455',
        'name' => 'Nombre Editado',
        'email' => 'juan@gmail.com',
        'photo_url' => 'https://ejemplo.com/otra-foto.jpg',
    ]);

    $this->mock(FirebaseTokenVerifier::class)
        ->shouldReceive('verify')
        ->andReturn(fakeClaims());

    $response = $this->postJson('/api/auth/google', ['id_token' => 'token-valido']);

    $response->assertOk()
        ->assertJsonPath('is_new', false)
        ->assertJsonPath('user.name', 'Nombre Editado');

    expect(User::count())->toBe(1);
});

it('rechaza un token inválido', function () {
    $this->mock(FirebaseTokenVerifier::class)
        ->shouldReceive('verify')
        ->andThrow(new RuntimeException('Token de Firebase inválido.'));

    $this->postJson('/api/auth/google', ['id_token' => 'token-malo'])
        ->assertUnauthorized();
});

it('exige el id_token', function () {
    $this->postJson('/api/auth/google', [])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('id_token');
});
