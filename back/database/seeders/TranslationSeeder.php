<?php

namespace Database\Seeders;

use App\Models\Language;
use App\Models\Translation;
use Illuminate\Database\Seeder;
use RuntimeException;

class TranslationSeeder extends Seeder
{
    /**
     * Idiomas soportados. Las traducciones viven en database/seeders/i18n/{code}.json
     * como mapa plano "grupo.clave" => texto.
     */
    private const IDIOMAS = [
        ['code' => 'es', 'name' => 'Español', 'flag' => '🇪🇸'],
        ['code' => 'en', 'name' => 'English', 'flag' => '🇺🇸'],
        ['code' => 'pt', 'name' => 'Português', 'flag' => '🇧🇷'],
        ['code' => 'fr', 'name' => 'Français', 'flag' => '🇫🇷'],
    ];

    public function run(): void
    {
        foreach (self::IDIOMAS as $idioma) {
            Language::updateOrCreate(
                ['code' => $idioma['code']],
                ['name' => $idioma['name'], 'flag' => $idioma['flag'], 'active' => true],
            );

            $this->sembrarTraducciones($idioma['code']);
            Translation::limpiarCache($idioma['code']);
        }
    }

    private function sembrarTraducciones(string $locale): void
    {
        $ruta = database_path("seeders/i18n/$locale.json");

        if (! file_exists($ruta)) {
            throw new RuntimeException("Falta el archivo de traducciones $ruta");
        }

        $mapa = json_decode(file_get_contents($ruta), true, 512, JSON_THROW_ON_ERROR);

        $filas = [];
        $ahora = now();

        foreach ($mapa as $claveCompleta => $texto) {
            [$grupo, $clave] = explode('.', $claveCompleta, 2);
            $filas[] = [
                'group' => $grupo,
                'key' => $clave,
                'locale' => $locale,
                'text' => $texto,
                'created_at' => $ahora,
                'updated_at' => $ahora,
            ];
        }

        foreach (array_chunk($filas, 200) as $bloque) {
            Translation::upsert($bloque, ['group', 'key', 'locale'], ['text', 'updated_at']);
        }
    }
}
