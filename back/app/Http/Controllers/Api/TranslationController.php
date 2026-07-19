<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Language;
use App\Models\Translation;
use Illuminate\Http\JsonResponse;

class TranslationController extends Controller
{
    /**
     * Idiomas activos con la versión de su catálogo de traducciones.
     * La app compara la versión guardada para saber si debe re-sincronizar.
     */
    public function languages(): JsonResponse
    {
        $idiomas = Language::where('active', true)
            ->orderBy('id')
            ->get(['code', 'name', 'flag'])
            ->map(fn (Language $idioma) => [
                'code' => $idioma->code,
                'name' => $idioma->name,
                'flag' => $idioma->flag,
                'version' => Translation::version($idioma->code),
            ]);

        return response()->json($idiomas);
    }

    /**
     * Todas las traducciones de un idioma como mapa plano "grupo.clave" => texto.
     */
    public function show(string $locale): JsonResponse
    {
        abort_unless(
            Language::where('code', $locale)->where('active', true)->exists(),
            404,
            'Idioma no disponible',
        );

        return response()->json([
            'locale' => $locale,
            'version' => Translation::version($locale),
            'translations' => Translation::mapa($locale),
        ]);
    }
}
