<?php

namespace App\Services;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Verifica un ID token de Google (google_sign_in en la app) sin SDK:
 * valida la firma RS256 contra los certificados públicos de Google
 * y comprueba que el emisor y la audiencia correspondan a esta app.
 */
class GoogleTokenVerifier
{
    private const CERTS_URL = 'https://www.googleapis.com/oauth2/v1/certs';

    private const VALID_ISSUERS = ['https://accounts.google.com', 'accounts.google.com'];

    /**
     * Devuelve los claims del token (sub, email, name, picture...).
     *
     * @return array<string, mixed>
     *
     * @throws RuntimeException si el token es inválido o expiró.
     */
    public function verify(string $idToken): array
    {
        $clientId = config('services.google.client_id');

        if (blank($clientId)) {
            throw new RuntimeException('GOOGLE_CLIENT_ID no está configurado en el .env.');
        }

        try {
            $payload = (array) JWT::decode($idToken, $this->publicKeys());
        } catch (\Throwable $e) {
            throw new RuntimeException('Token de Google inválido: '.$e->getMessage(), previous: $e);
        }

        if (! in_array($payload['iss'] ?? null, self::VALID_ISSUERS, true) || ($payload['aud'] ?? null) !== $clientId) {
            throw new RuntimeException('El token no pertenece a esta aplicación.');
        }

        if (blank($payload['sub'] ?? null)) {
            throw new RuntimeException('El token no contiene un usuario válido.');
        }

        return json_decode(json_encode($payload), true);
    }

    /**
     * Certificados públicos de Google, cacheados una hora.
     *
     * @return array<string, Key>
     */
    private function publicKeys(): array
    {
        $certs = Cache::remember('google.oauth2.certs', now()->addHour(), function (): array {
            return Http::timeout(10)->get(self::CERTS_URL)->throw()->json();
        });

        return collect($certs)
            ->map(fn (string $cert) => new Key(openssl_pkey_get_public($cert), 'RS256'))
            ->all();
    }
}
