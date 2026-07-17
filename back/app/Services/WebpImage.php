<?php

namespace App\Services;

use Illuminate\Support\Facades\Storage;

class WebpImage
{
    /**
     * Convierte una imagen (binario) a WebP y la guarda en el disco público.
     * Devuelve la ruta pública (/storage/...), o null si el binario no es
     * una imagen válida.
     */
    public static function store(string $binary, string $filename, int $quality = 85): ?string
    {
        $image = @imagecreatefromstring($binary);

        if ($image === false) {
            return null;
        }

        imagepalettetotruecolor($image);

        Storage::disk('public')->makeDirectory(dirname($filename));
        imagewebp($image, Storage::disk('public')->path($filename), $quality);
        imagedestroy($image);

        return "/storage/{$filename}";
    }
}
