<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Empresa;
use App\Services\CatalogoInicial;
use App\Services\ClientesIniciales;
use App\Services\ProveedoresIniciales;
use App\Services\WebpImage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class EmpresaController extends Controller
{
    /**
     * Registra la empresa del usuario autenticado (pantalla "Registro de
     * empresa" del mockup) y vincula su cuenta a ella. El logo es opcional
     * y se guarda como WebP en storage/app/public/logos/. El slug de tienda
     * se genera automáticamente desde el nombre, asegurando que sea único.
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->empresa_id !== null) {
            return response()->json([
                'message' => 'Tu cuenta ya está vinculada a una empresa.',
            ], 409);
        }

        $data = $this->validated($request);
        $data['slug_tienda'] = $this->generarSlugUnico($data['nombre']);

        $empresa = Empresa::create(collect($data)->except('logo')->all());

        if ($request->hasFile('logo')) {
            $logo = WebpImage::store(
                $request->file('logo')->getContent(),
                "logos/empresa-{$empresa->id}.webp",
            );

            if ($logo !== null) {
                $empresa->update(['logo_path' => $logo]);
            }
        }

        // Sin logo propio: se copia el logo por defecto empaquetado
        // (resources/logos/default.webp, marca "mi negocio suite").
        if ($empresa->logo_path === null) {
            $origen = resource_path('logos/default.webp');

            if (is_file($origen)) {
                $archivo = "logos/empresa-{$empresa->id}.webp";
                Storage::disk('public')->makeDirectory('logos');
                copy($origen, Storage::disk('public')->path($archivo));
                $empresa->update(['logo_path' => "/storage/{$archivo}"]);
            }
        }

        $user->empresa()->associate($empresa)->save();

        // Negocio de comidas: se crea el catálogo por defecto
        // (Pollos, Extras, Jugos, Refrescos) con imágenes placeholder.
        CatalogoInicial::crear($empresa);

        // Cliente "S/N" (el de las ventas sin cliente) y 10 clientes
        // ficticios para arrancar la gestión de clientes.
        ClientesIniciales::crear($empresa);

        // Proveedor "S/N" (el de las compras sin proveedor) y 5 ficticios.
        ProveedoresIniciales::crear($empresa);

        return response()->json([
            'empresa' => $empresa->refresh(),
            'user' => $user->load('empresa'),
        ], 201);
    }

    /**
     * Actualiza los datos de la empresa del usuario (pantalla Configuración).
     * Si cambia el nombre comercial, se regenera el slug de tienda
     * automáticamente manteniendo la unicidad.
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();
        $empresa = $user->empresa;

        if ($empresa === null) {
            return response()->json([
                'message' => 'Tu cuenta no tiene una empresa registrada.',
            ], 404);
        }

        $data = $this->validated($request);

        if (array_key_exists('nombre', $data) && $data['nombre'] !== $empresa->nombre) {
            $data['slug_tienda'] = $this->generarSlugUnico($data['nombre'], $empresa);
        }

        $empresa->update(collect($data)->except('logo')->all());

        if ($request->hasFile('logo')) {
            // Nombre con sufijo de tiempo para que la app no muestre el
            // logo viejo cacheado por URL; se borra el archivo anterior.
            $logo = WebpImage::store(
                $request->file('logo')->getContent(),
                "logos/empresa-{$empresa->id}-".now()->timestamp.'.webp',
            );

            if ($logo !== null) {
                $anterior = $empresa->logo_path;
                $empresa->update(['logo_path' => $logo]);

                if ($anterior !== null && str_starts_with($anterior, '/storage/')) {
                    Storage::disk('public')->delete(substr($anterior, strlen('/storage/')));
                }
            }
        }

        return response()->json([
            'empresa' => $empresa->refresh(),
            'user' => $user->load('empresa'),
        ]);
    }

    /**
     * Verifica si un slug de tienda está disponible. Útil para previsualizar
     * o validar desde la app; la generación real se hace automáticamente.
     */
    public function slugDisponible(Request $request, ?Empresa $empresa = null): JsonResponse
    {
        $slug = $this->normalizarSlug((string) $request->route('slug'));

        if (strlen($slug) < 3) {
            return response()->json([
                'disponible' => false,
                'slug' => $slug,
                'mensaje' => 'El nombre de tienda debe tener al menos 3 caracteres válidos.',
            ]);
        }

        $query = Empresa::where('slug_tienda', $slug);
        if ($empresa !== null) {
            $query->where('id', '!=', $empresa->id);
        }

        $disponible = ! $query->exists();

        return response()->json([
            'disponible' => $disponible,
            'slug' => $slug,
            'mensaje' => $disponible
                ? 'El nombre de tienda está disponible.'
                : 'Ese nombre de tienda ya está en uso. Elige otro.',
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request): array
    {
        return $request->validate([
            'nombre' => ['required', 'string', 'max:255'],
            'nit' => ['nullable', 'string', 'max:30'],
            'telefono' => ['nullable', 'string', 'max:30'],
            'direccion' => ['nullable', 'string', 'max:255'],
            'correo' => ['nullable', 'email', 'max:255'],
            'moneda' => ['nullable', 'string', 'in:BOB,USD,PEN'],
            'logo' => ['nullable', 'image', 'max:4096'],
        ], [], [
            'nombre' => 'nombre comercial',
            'correo' => 'correo de la empresa',
        ]);
    }

    /**
     * Genera un slug de tienda único a partir del nombre. Si el slug base
     * ya existe, agrega un sufijo numérico creciente. La unicidad se controla
     * desde el backend, no desde un índice unique de la base de datos.
     */
    private function generarSlugUnico(string $nombre, ?Empresa $excepto = null): string
    {
        $base = $this->normalizarSlug($nombre);
        $slug = $base;
        $contador = 2;

        while (true) {
            $query = Empresa::where('slug_tienda', $slug);
            if ($excepto !== null) {
                $query->where('id', '!=', $excepto->id);
            }

            if (! $query->exists()) {
                break;
            }

            $slug = "{$base}-{$contador}";
            $contador++;
        }

        return $slug;
    }

    /**
     * Normaliza un texto para usarlo como slug de tienda: minúsculas, sin ñ,
     * sin tildes, sin espacios y solo letras, números y guiones.
     */
    private function normalizarSlug(string $valor): string
    {
        $slug = mb_strtolower($valor, 'UTF-8');
        $slug = str_replace('ñ', 'n', $slug);
        $slug = str_replace(
            ['á', 'é', 'í', 'ó', 'ú', 'ü', 'à', 'è', 'ì', 'ò', 'ù'],
            ['a', 'e', 'i', 'o', 'u', 'u', 'a', 'e', 'i', 'o', 'u'],
            $slug,
        );
        $slug = preg_replace('/[^a-z0-9]+/', '-', $slug);
        $slug = trim($slug, '-');

        return $slug;
    }
}
