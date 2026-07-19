<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

#[Fillable(['group', 'key', 'locale', 'text'])]
class Translation extends Model
{
    /**
     * Mapa plano "grupo.clave" => texto de un idioma, con caché.
     * La caché se invalida al guardar/borrar cualquier traducción.
     */
    public static function mapa(string $locale): array
    {
        return Cache::rememberForever("translations.$locale", function () use ($locale) {
            return static::where('locale', $locale)
                ->orderBy('group')
                ->orderBy('key')
                ->get()
                ->mapWithKeys(fn (Translation $t) => ["{$t->group}.{$t->key}" => $t->text])
                ->all();
        });
    }

    /**
     * Versión del catálogo de un idioma: cambia cuando cambia alguna traducción.
     */
    public static function version(string $locale): string
    {
        return Cache::rememberForever("translations.version.$locale", function () use ($locale) {
            $agregado = static::where('locale', $locale)
                ->selectRaw('COUNT(*) as total, MAX(updated_at) as ultimo')
                ->first();

            return md5(($agregado->total ?? 0).'|'.($agregado->ultimo ?? ''));
        });
    }

    public static function limpiarCache(string $locale): void
    {
        Cache::forget("translations.$locale");
        Cache::forget("translations.version.$locale");
    }

    protected static function booted(): void
    {
        $limpiar = fn (Translation $t) => static::limpiarCache($t->locale);
        static::saved($limpiar);
        static::deleted($limpiar);
    }
}
