<?php

namespace App\Http\Controllers;

use App\Models\Empresa;
use Illuminate\Http\Request;
use Illuminate\View\View;

class TiendaController extends Controller
{
    /**
     * Muestra la tienda pública de una empresa usando su slug.
     */
    public function __invoke(Request $request, string $slug): View
    {
        $empresa = Empresa::where('slug_tienda', $this->normalizarSlug($slug))
            ->with(['productos' => function ($query) {
                $query->whereNull('deleted_at')
                    ->where('stock', '>', 0)
                    ->orderBy('nombre');
            }, 'categorias' => function ($query) {
                $query->whereNull('deleted_at')->orderBy('nombre');
            }])
            ->firstOrFail();

        return view('tienda.show', compact('empresa'));
    }

    /**
     * Normaliza un slug de la misma forma que el controlador de API.
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
