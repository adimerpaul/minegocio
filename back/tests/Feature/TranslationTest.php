<?php

use App\Models\Language;
use App\Models\Translation;
use Database\Seeders\TranslationSeeder;

it('lista los idiomas activos con su versión', function () {
    $this->seed(TranslationSeeder::class);

    $response = $this->getJson('/api/languages');

    $response->assertOk();
    $response->assertJsonCount(4);
    expect(collect($response->json())->pluck('code')->all())
        ->toBe(['es', 'en', 'pt', 'fr']);
    expect($response->json()[0])->toHaveKeys(['code', 'name', 'flag', 'version']);
});

it('no lista idiomas inactivos', function () {
    $this->seed(TranslationSeeder::class);
    Language::where('code', 'fr')->update(['active' => false]);

    $response = $this->getJson('/api/languages');

    $response->assertOk();
    $response->assertJsonCount(3);
});

it('devuelve las traducciones de un idioma como mapa plano', function () {
    $this->seed(TranslationSeeder::class);

    $response = $this->getJson('/api/translations/es');

    $response->assertOk();
    $response->assertJsonStructure(['locale', 'version', 'translations']);
    expect($response->json('locale'))->toBe('es');
    expect($response->json('translations'))->toHaveKey('comun.guardar');
    expect($response->json('translations')['comun.guardar'])->toBe('Guardar');
});

it('responde 404 para un idioma inexistente', function () {
    $this->seed(TranslationSeeder::class);

    $this->getJson('/api/translations/de')->assertNotFound();
});

it('cambia la versión cuando se edita una traducción', function () {
    $this->seed(TranslationSeeder::class);

    $versionInicial = Translation::version('es');

    $traduccion = Translation::where('locale', 'es')
        ->where('group', 'comun')
        ->where('key', 'guardar')
        ->first();
    $traduccion->text = 'Registrar';
    $traduccion->updated_at = now()->addMinute();
    $traduccion->save();

    expect(Translation::version('es'))->not->toBe($versionInicial);
    expect(Translation::mapa('es')['comun.guardar'])->toBe('Registrar');
});

it('todos los idiomas tienen las mismas claves de traducción', function () {
    foreach (['en', 'pt', 'fr'] as $locale) {
        $es = json_decode(file_get_contents(database_path('seeders/i18n/es.json')), true);
        $otro = json_decode(file_get_contents(database_path("seeders/i18n/$locale.json")), true);

        expect(array_keys($otro))->toBe(array_keys($es), "Las claves de $locale.json no coinciden con es.json");
    }
});
