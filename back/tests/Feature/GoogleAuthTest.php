<?php

use App\Models\User;
use App\Services\GoogleTokenVerifier;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;

function fakeClaims(array $overrides = []): array
{
    return array_merge([
        'iss' => 'https://accounts.google.com',
        'sub' => '1122334455',
        'name' => 'Juan Pérez',
        'email' => 'juan@gmail.com',
        'email_verified' => true,
        'picture' => 'https://lh3.googleusercontent.com/foto.jpg',
    ], $overrides);
}

/** PNG de 1x1 generado con GD, para simular la foto de Google. */
function fakePngBytes(): string
{
    $image = imagecreatetruecolor(1, 1);
    ob_start();
    imagepng($image);
    imagedestroy($image);

    return ob_get_clean();
}

it('crea el usuario, guarda su foto en webp y devuelve un token la primera vez', function () {
    Storage::fake('public');
    Http::fake(['lh3.googleusercontent.com/*' => Http::response(fakePngBytes())]);

    $this->mock(GoogleTokenVerifier::class)
        ->shouldReceive('verify')
        ->andReturn(fakeClaims());

    $response = $this->postJson('/api/auth/google', ['id_token' => 'token-valido']);

    $response->assertOk()
        ->assertJsonPath('is_new', true)
        ->assertJsonPath('user.email', 'juan@gmail.com')
        ->assertJsonPath('user.google_id', '1122334455');

    expect($response->json('token'))->toBeString()->not->toBeEmpty();

    $userId = $response->json('user.id');
    expect($response->json('user.photo_url'))->toBe("/storage/avatars/user-{$userId}.webp");
    Storage::disk('public')->assertExists("avatars/user-{$userId}.webp");

    $this->assertDatabaseHas('users', [
        'google_id' => '1122334455',
        'name' => 'Juan Pérez',
    ]);
});

it('mantiene la foto de Google si la descarga falla', function () {
    Storage::fake('public');
    Http::fake(['lh3.googleusercontent.com/*' => Http::response(status: 500)]);

    $this->mock(GoogleTokenVerifier::class)
        ->shouldReceive('verify')
        ->andReturn(fakeClaims());

    $this->postJson('/api/auth/google', ['id_token' => 'token-valido'])
        ->assertOk()
        ->assertJsonPath('user.photo_url', 'https://lh3.googleusercontent.com/foto.jpg');
});

it('no duplica ni sobrescribe al usuario en logins posteriores', function () {
    User::create([
        'google_id' => '1122334455',
        'name' => 'Nombre Editado',
        'email' => 'juan@gmail.com',
        'photo_url' => '/storage/avatars/user-1.webp',
    ]);

    $this->mock(GoogleTokenVerifier::class)
        ->shouldReceive('verify')
        ->andReturn(fakeClaims());

    $response = $this->postJson('/api/auth/google', ['id_token' => 'token-valido']);

    $response->assertOk()
        ->assertJsonPath('is_new', false)
        ->assertJsonPath('user.name', 'Nombre Editado')
        ->assertJsonPath('user.photo_url', '/storage/avatars/user-1.webp');

    expect(User::count())->toBe(1);
});

it('crea una cuenta nueva si el usuario anterior fue eliminado (soft delete)', function () {
    $user = User::create([
        'google_id' => '1122334455',
        'name' => 'Juan Pérez',
        'email' => 'juan@gmail.com',
    ]);
    $user->delete();

    $this->mock(GoogleTokenVerifier::class)
        ->shouldReceive('verify')
        ->andReturn(fakeClaims());

    $response = $this->postJson('/api/auth/google', ['id_token' => 'token-valido']);

    $response->assertOk()
        ->assertJsonPath('is_new', true)
        ->assertJsonPath('user.email', 'juan@gmail.com')
        ->assertJsonPath('user.google_id', '1122334455');

    expect($response->json('user.id'))->not->toBe($user->id);
    expect($user->fresh()->google_id)->toBe('1122334455');
    expect(User::count())->toBe(1);
    expect(User::withTrashed()->count())->toBe(2);
});

it('rechaza un token inválido', function () {
    $this->mock(GoogleTokenVerifier::class)
        ->shouldReceive('verify')
        ->andThrow(new RuntimeException('Token de Google inválido.'));

    $this->postJson('/api/auth/google', ['id_token' => 'token-malo'])
        ->assertUnauthorized();
});

it('exige el id_token', function () {
    $this->postJson('/api/auth/google', [])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('id_token');
});
