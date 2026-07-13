<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\FirebaseTokenVerifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class GoogleAuthController extends Controller
{
    /**
     * Recibe el ID token de Firebase tras el login con Google en la app.
     * La primera vez crea el usuario con todos sus datos (google_id, foto,
     * nombre, correo); en logins posteriores solo devuelve el usuario
     * existente. Siempre emite un token de API (Sanctum).
     */
    public function __invoke(Request $request, FirebaseTokenVerifier $verifier): JsonResponse
    {
        $request->validate(['id_token' => ['required', 'string']]);

        Log::info('[auth/google] Petición recibida', [
            'ip' => $request->ip(),
            'token_len' => strlen($request->string('id_token')),
        ]);

        try {
            $claims = $verifier->verify($request->string('id_token'));
        } catch (RuntimeException $e) {
            Log::warning('[auth/google] Token rechazado: '.$e->getMessage());

            return response()->json(['message' => $e->getMessage()], 401);
        }

        // El id de la cuenta de Google viene en identities['google.com'][0];
        // no usar data_get porque la clave contiene un punto.
        $googleId = $claims['firebase']['identities']['google.com'][0] ?? null;

        $user = User::firstOrCreate(
            ['firebase_uid' => $claims['sub']],
            [
                'name' => $claims['name'] ?? $claims['email'] ?? 'Usuario',
                'email' => $claims['email'] ?? $claims['sub'].'@sin-correo.local',
                'google_id' => $googleId,
                'photo_url' => $claims['picture'] ?? null,
                'email_verified_at' => ($claims['email_verified'] ?? false) ? now() : null,
            ],
        );

        Log::info('[auth/google] Login correcto', [
            'user_id' => $user->id,
            'email' => $user->email,
            'is_new' => $user->wasRecentlyCreated,
        ]);

        return response()->json([
            'user' => $user,
            'token' => $user->createToken('app-movil')->plainTextToken,
            'is_new' => $user->wasRecentlyCreated,
        ]);
    }
}
