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
        Schema::create('proveedores', function (Blueprint $table) {
            $table->id();
            $table->foreignId('empresa_id')->constrained('empresas')->cascadeOnDelete();
            $table->string('nombre');
            $table->string('nit', 30)->nullable();
            $table->string('telefono', 30)->nullable();
            $table->string('correo')->nullable();
            $table->string('direccion')->nullable();
            // Proveedor "S/N": el de las compras sin proveedor; no se borra.
            $table->boolean('es_default')->default(false);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('compras', function (Blueprint $table) {
            $table->id();
            $table->foreignId('empresa_id')->constrained('empresas')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('codigo', 20);
            // Nombre del proveedor congelado al momento de comprar.
            $table->string('proveedor');
            $table->foreignId('proveedor_id')
                ->nullable()
                ->constrained('proveedores')
                ->nullOnDelete();
            $table->decimal('total', 10, 2);
            $table->string('estado', 20)->default('completada');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['empresa_id', 'codigo']);
        });

        Schema::create('compra_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('compra_id')->constrained('compras')->cascadeOnDelete();
            $table->foreignId('producto_id')->nullable()->constrained('productos')->nullOnDelete();
            // Copia del nombre y costo al momento de comprar.
            $table->string('nombre');
            $table->decimal('costo', 10, 2);
            $table->integer('cantidad');
            $table->decimal('subtotal', 10, 2);
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('compra_items');
        Schema::dropIfExists('compras');
        Schema::dropIfExists('proveedores');
    }
};
