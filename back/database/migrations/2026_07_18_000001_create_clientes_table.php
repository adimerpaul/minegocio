<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('clientes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('empresa_id')->constrained('empresas')->cascadeOnDelete();
            $table->string('nombre');
            $table->string('nit', 30)->nullable();
            $table->string('telefono', 30)->nullable();
            $table->string('correo')->nullable();
            $table->string('direccion')->nullable();
            // Cliente "S/N" (sin nombre): el que usa la venta cuando no se
            // elige otro; no se puede borrar.
            $table->boolean('es_default')->default(false);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::table('ventas', function (Blueprint $table) {
            $table->foreignId('cliente_id')
                ->nullable()
                ->after('cliente')
                ->constrained('clientes')
                ->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('ventas', function (Blueprint $table) {
            $table->dropConstrainedForeignId('cliente_id');
        });

        Schema::dropIfExists('clientes');
    }
};
