<?php

namespace App\Services;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Verifica un ID token de Firebase Authentication sin SDK de admin:
 * valida la firma RS256 contra los certificados públicos de Google
 * y comprueba emisor y audiencia del proyecto.
 */
class FirebaseTokenVerifier
{
    private const CERTS_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

    /**
     * Devuelve los claims del token (sub, email, name, picture, firebase...).
     *
     * @return array<string, mixed>
     *
     * @throws RuntimeException si el token es inválido o expiró.
     */
    public function verify(string $idToken): array
    {
        $projectId = config('services.firebase.project_id');

        if (blank($projectId)) {
            throw new RuntimeException('FIREBASE_PROJECT_ID no está configurado en el .env.');
        }

        try {
            $payload = (array) JWT::decode($idToken, $this->publicKeys());
        } catch (\Throwable $e) {
            throw new RuntimeException('Token de Firebase inválido: '.$e->getMessage(), previous: $e);
        }

        $validIssuer = "https://securetoken.google.com/{$projectId}";

        if (($payload['iss'] ?? null) !== $validIssuer || ($payload['aud'] ?? null) !== $projectId) {
            throw new RuntimeException('El token no pertenece a este proyecto de Firebase.');
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
        $certs = Cache::remember('firebase.securetoken.certs', now()->addHour(), function (): array {
            return Http::timeout(10)->get(self::CERTS_URL)->throw()->json();
        });

        return collect($certs)
            ->map(fn (string $cert) => new Key(openssl_pkey_get_public($cert), 'RS256'))
            ->all();
    }
}
