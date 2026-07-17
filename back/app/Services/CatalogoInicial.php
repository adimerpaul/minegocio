<?php

namespace App\Services;

use App\Models\Empresa;
use App\Models\Producto;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Catálogo por defecto para un negocio de venta de comidas. Se crea junto
 * con la empresa: categorías (Pollos, Extras, Jugos, Refrescos), productos
 * con precios de referencia y la foto de cada producto.
 *
 * Las fotos vienen empaquetadas en resources/productos/{slug}.webp y se
 * copian a storage/app/public/productos/{empresa}/{slug}.webp; si algún
 * producto no tiene foto se genera un placeholder. Se pueden reemplazar
 * por otras fotos conservando el mismo nombre de archivo.
 */
class CatalogoInicial
{
    /**
     * Categoría => [descripción, color RGB del placeholder, productos [nombre, precio Bs]].
     *
     * @var array<string, array{string, array{int, int, int}, array<array{string, float}>}>
     */
    private const CATALOGO = [
        'Pollos' => [
            'Pollo a la brasa por porciones',
            [247, 216, 186],
            [
                ['Pollo entero', 90.0],
                ['Medio pollo', 48.0],
                ['Cuarto de pollo', 25.0],
                ['Octavo de pollo', 13.0],
            ],
        ],
        'Extras' => [
            'Acompañamientos y porciones',
            [250, 235, 190],
            [
                ['Papas fritas grandes', 10.0],
                ['Papas fritas medianas', 7.0],
                ['Porción de arroz', 5.0],
                ['Plátano frito', 6.0],
                ['Ensalada', 5.0],
            ],
        ],
        'Jugos' => [
            'Jugos naturales',
            [214, 238, 205],
            [
                ['Jugo de naranja', 8.0],
                ['Jugo de piña', 8.0],
                ['Limonada', 7.0],
            ],
        ],
        'Refrescos' => [
            'Gaseosas y agua',
            [205, 224, 245],
            [
                ['Coca-Cola 2 L', 14.0],
                ['Coca-Cola 600 ml', 7.0],
                ['Fanta 600 ml', 7.0],
                ['Agua Vital 600 ml', 5.0],
            ],
        ],
    ];

    private const STOCK_INICIAL = 50;

    public static function crear(Empresa $empresa): void
    {
        $numero = 1;

        foreach (self::CATALOGO as $nombreCategoria => [$descripcion, $rgb, $productos]) {
            $categoria = $empresa->categorias()->create([
                'nombre' => $nombreCategoria,
                'descripcion' => $descripcion,
            ]);

            foreach ($productos as [$nombre, $precio]) {
                $producto = $empresa->productos()->create([
                    'categoria_id' => $categoria->id,
                    'codigo' => sprintf('P-%03d', $numero++),
                    'nombre' => $nombre,
                    'precio' => $precio,
                    'stock' => self::STOCK_INICIAL,
                ]);

                $imagen = self::copiarFoto($empresa, $producto)
                    ?? self::imagenPlaceholder($empresa, $producto, $rgb);

                if ($imagen !== null) {
                    $producto->update(['imagen_path' => $imagen]);
                }
            }
        }
    }

    /**
     * Copia la foto empaquetada del producto (resources/productos/{slug}.webp)
     * al disco público de la empresa. Devuelve la ruta pública, o null si
     * el producto no tiene foto empaquetada.
     */
    private static function copiarFoto(Empresa $empresa, Producto $producto): ?string
    {
        $slug = Str::slug($producto->nombre);
        $origen = resource_path("productos/{$slug}.webp");

        if (! is_file($origen)) {
            return null;
        }

        $archivo = "productos/{$empresa->id}/{$slug}.webp";
        Storage::disk('public')->makeDirectory(dirname($archivo));
        copy($origen, Storage::disk('public')->path($archivo));

        return "/storage/{$archivo}";
    }

    /**
     * Genera una imagen placeholder (400x300, color de la categoría y el
     * nombre del producto centrado). Devuelve la ruta pública, o null si
     * GD falla (el catálogo no depende de las imágenes).
     *
     * @param  array{int, int, int}  $rgb
     */
    private static function imagenPlaceholder(Empresa $empresa, Producto $producto, array $rgb): ?string
    {
        try {
            $imagen = imagecreatetruecolor(400, 300);

            $fondo = imagecolorallocate($imagen, $rgb[0], $rgb[1], $rgb[2]);
            imagefill($imagen, 0, 0, $fondo);

            $tinta = imagecolorallocate($imagen, 90, 62, 40);

            // Fuente incorporada de GD (5): 9px de ancho por carácter.
            $lineas = self::partirEnLineas(Str::ascii($producto->nombre));
            $altoLinea = 22;
            $y = (int) (150 - (count($lineas) * $altoLinea) / 2);

            foreach ($lineas as $linea) {
                $x = (int) ((400 - strlen($linea) * 9) / 2);
                imagestring($imagen, 5, max($x, 6), $y, $linea, $tinta);
                $y += $altoLinea;
            }

            $archivo = 'productos/'.$empresa->id.'/'.Str::slug($producto->nombre).'.webp';
            Storage::disk('public')->makeDirectory(dirname($archivo));
            imagewebp($imagen, Storage::disk('public')->path($archivo), 85);
            imagedestroy($imagen);

            return "/storage/{$archivo}";
        } catch (\Throwable) {
            return null;
        }
    }

    /**
     * Parte el nombre en líneas de hasta 20 caracteres sin cortar palabras.
     *
     * @return list<string>
     */
    private static function partirEnLineas(string $texto): array
    {
        $lineas = [];
        $actual = '';

        foreach (explode(' ', mb_strtoupper($texto)) as $palabra) {
            if ($actual !== '' && strlen($actual.' '.$palabra) > 20) {
                $lineas[] = $actual;
                $actual = $palabra;
            } else {
                $actual = $actual === '' ? $palabra : $actual.' '.$palabra;
            }
        }

        if ($actual !== '') {
            $lineas[] = $actual;
        }

        return $lineas;
    }
}
