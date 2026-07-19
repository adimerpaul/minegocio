<?php

namespace App\Http\Controllers;

use App\Models\Empresa;
use App\Models\Producto;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class TiendaController extends Controller
{
    /**
     * Muestra la tienda pública de una empresa usando su slug.
     */
    public function __invoke(Request $request, string $slug): View
    {
        $empresa = $this->buscarEmpresa($slug);

        return view('tienda.show', compact('empresa'));
    }

    /**
     * Muestra la página individual de un producto dentro de una tienda.
     * El nombreSlug es solo para SEO; la búsqueda real se hace por ID.
     * Si el slug no coincide con el nombre actual, redirige a la URL correcta.
     */
    public function producto(Request $request, string $slug, int $producto, ?string $nombreSlug = null): View|RedirectResponse
    {
        $empresa = $this->buscarEmpresa($slug);

        $productoModel = Producto::where('id', $producto)
            ->where('empresa_id', $empresa->id)
            ->whereNull('deleted_at')
            ->firstOrFail();

        $slugEsperado = $this->normalizarSlug($productoModel->nombre);

        if ($nombreSlug !== $slugEsperado) {
            return redirect()->route('tienda.producto', [
                'slug' => $empresa->slug_tienda,
                'producto' => $productoModel->id,
                'nombreSlug' => $slugEsperado,
            ], 301);
        }

        $relacionados = $empresa->productos()
            ->where('id', '!=', $productoModel->id)
            ->whereNull('deleted_at')
            ->inRandomOrder()
            ->limit(4)
            ->get();

        return view('tienda.producto', compact('empresa', 'productoModel', 'relacionados'));
    }

    /**
     * Busca la empresa por su slug normalizado y carga relaciones útiles.
     */
    private function buscarEmpresa(string $slug): Empresa
    {
        return Empresa::where('slug_tienda', $this->normalizarSlug($slug))
            ->with(['productos' => function ($query) {
                $query->whereNull('deleted_at')->orderBy('nombre');
            }, 'categorias' => function ($query) {
                $query->whereNull('deleted_at')->orderBy('nombre');
            }])
            ->firstOrFail();
    }

    /**
     * Normaliza un slug: minúsculas, sin ñ/tildes, espacios → guiones.
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

        return trim($slug, '-');
    }
}
