<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class WebpImage
{
    /**
     * Convierte una imagen (binario) a WebP y la guarda en el disco público.
     * Devuelve la ruta pública (/storage/...), o null si el binario no es
     * una imagen válida o si no se pudo escribir el archivo (permisos del
     * servidor, o PHP-GD sin soporte WebP) — en ese caso queda un aviso en
     * storage/logs/laravel.log en vez de fallar en silencio.
     */
    public static function store(string $binary, string $filename, int $quality = 85): ?string
    {
        $image = @imagecreatefromstring($binary);

        if ($image === false) {
            return null;
        }

        imagepalettetotruecolor($image);

        Storage::disk('public')->makeDirectory(dirname($filename));
        $ruta = Storage::disk('public')->path($filename);
        $guardado = imagewebp($image, $ruta, $quality);
        imagedestroy($image);

        if (! $guardado || ! is_file($ruta)) {
            Log::warning("WebpImage: no se pudo escribir {$ruta}. Verifica los permisos de storage/app/public y que PHP-GD tenga soporte WebP (gd_info()).");

            return null;
        }

        return "/storage/{$filename}";
    }
}
