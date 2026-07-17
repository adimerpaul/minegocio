<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\GoogleTokenVerifier;
use App\Services\WebpImage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class GoogleAuthController extends Controller
{
    /**
     * Recibe el ID token de Google tras el login en la app.
     * La primera vez crea el usuario (google_id, nombre, correo) y guarda
     * su foto como WebP en el backend; en logins posteriores solo devuelve
     * el usuario existente. Siempre emite un token de API (Sanctum).
     */
    public function __invoke(Request $request, GoogleTokenVerifier $verifier): JsonResponse
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

        $user = User::withTrashed()->firstOrCreate(
            ['google_id' => $claims['sub']],
            [
                'name' => $claims['name'] ?? $claims['email'] ?? 'Usuario',
                'email' => $claims['email'] ?? $claims['sub'].'@sin-correo.local',
                'photo_url' => $claims['picture'] ?? null,
                'email_verified_at' => ($claims['email_verified'] ?? false) ? now() : null,
            ],
        );

        // Cuenta con borrado suave que vuelve a iniciar sesión: se restaura
        // (el google_id es único, no se crea un duplicado).
        if ($user->trashed()) {
            $user->restore();
        }

        if ($user->wasRecentlyCreated && filled($claims['picture'] ?? null)) {
            $localPhoto = $this->storeAvatarAsWebp($user, $claims['picture']);

            if ($localPhoto !== null) {
                $user->update(['photo_url' => $localPhoto]);
            }
        }

        Log::info('[auth/google] Login correcto', [
            'user_id' => $user->id,
            'email' => $user->email,
            'is_new' => $user->wasRecentlyCreated,
        ]);

        return response()->json([
            'user' => $user->load('empresa'),
            'token' => $user->createToken('app-movil')->plainTextToken,
            'is_new' => $user->wasRecentlyCreated,
        ]);
    }

    /**
     * Descarga la foto de Google y la guarda como WebP en el disco público.
     * Devuelve la ruta relativa (/storage/avatars/...), o null si falla
     * (el login no debe romperse por la foto).
     */
    private function storeAvatarAsWebp(User $user, string $photoUrl): ?string
    {
        try {
            $binary = Http::timeout(10)->get($photoUrl)->throw()->body();

            $path = WebpImage::store($binary, "avatars/user-{$user->id}.webp");

            if ($path === null) {
                Log::warning('[avatar] La foto descargada no es una imagen válida', ['user_id' => $user->id]);
            }

            return $path;
        } catch (\Throwable $e) {
            Log::warning('[avatar] No se pudo guardar la foto: '.$e->getMessage(), ['user_id' => $user->id]);

            return null;
        }
    }
}
