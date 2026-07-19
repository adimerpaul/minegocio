<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $productoModel->nombre }} — {{ $empresa->nombre }}</title>
    <meta name="description" content="{{ $productoModel->nombre }} a {{ $empresa->moneda }} {{ number_format($productoModel->precio, 2) }} en {{ $empresa->nombre }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --naranja: #ea580c;
            --naranja-oscuro: #c2410c;
            --fondo: #faf7f4;
            --texto: #221d18;
            --texto-medio: #6b6055;
            --texto-suave: #a89a8c;
            --borde: #f0e9e2;
            --borde-fuerte: #eee4da;
            --blanco: #ffffff;
            --whatsapp: #25D366;
            --sombra: 0 4px 16px rgba(34, 29, 24, 0.08);
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: var(--fondo);
            color: var(--texto);
            line-height: 1.45;
        }

        header {
            background: var(--blanco);
            border-bottom: 1px solid var(--borde);
            position: sticky;
            top: 0;
            z-index: 30;
        }

        .header-inner {
            max-width: 1120px;
            margin: 0 auto;
            padding: 10px 16px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 9px;
            min-width: 0;
            text-decoration: none;
            color: var(--texto);
        }

        .brand img {
            width: 32px;
            height: 32px;
            border-radius: 9px;
            object-fit: cover;
            flex-shrink: 0;
            background: var(--fondo);
        }

        .brand-name {
            font-family: 'Sora', sans-serif;
            font-weight: 800;
            font-size: 16px;
            letter-spacing: -0.01em;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .header-actions {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .icon-btn, .app-btn {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            height: 36px;
            border-radius: 10px;
            text-decoration: none;
            font-size: 13px;
            font-weight: 700;
        }

        .icon-btn {
            width: 36px;
            background: var(--blanco);
            color: var(--texto);
            border: 1px solid var(--borde-fuerte);
        }

        .app-btn {
            padding: 0 12px;
            background: var(--naranja);
            color: var(--blanco);
            border: none;
        }

        .container {
            max-width: 1120px;
            margin: 0 auto;
            padding: 16px;
        }

        .breadcrumbs {
            font-size: 12px;
            color: var(--texto-suave);
            margin-bottom: 16px;
        }

        .breadcrumbs a {
            color: var(--texto-suave);
            text-decoration: none;
        }

        .breadcrumbs a:hover {
            color: var(--naranja);
        }

        .product-detail {
            background: var(--blanco);
            border-radius: 16px;
            padding: 20px;
            display: grid;
            grid-template-columns: 1fr;
            gap: 24px;
            box-shadow: var(--sombra);
        }

        @media (min-width: 640px) {
            .product-detail { grid-template-columns: 1fr 1fr; }
        }

        .product-image {
            aspect-ratio: 1 / 1;
            border-radius: 13px;
            overflow: hidden;
            background: #f5efe9;
            display: grid;
            place-items: center;
        }

        .product-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .product-image .placeholder {
            font-size: 80px;
        }

        .product-info {
            display: flex;
            flex-direction: column;
        }

        .product-category {
            display: inline-block;
            background: #fdeadd;
            color: var(--naranja);
            font-size: 12px;
            font-weight: 700;
            padding: 5px 10px;
            border-radius: 8px;
            margin-bottom: 12px;
            align-self: flex-start;
        }

        .product-name {
            font-family: 'Sora', sans-serif;
            font-size: 24px;
            font-weight: 800;
            margin: 0 0 12px;
            line-height: 1.2;
        }

        .product-price {
            font-family: 'Sora', sans-serif;
            font-size: 28px;
            font-weight: 800;
            color: var(--naranja-oscuro);
            margin-bottom: 20px;
        }

        .product-stock {
            font-size: 13px;
            color: var(--texto-suave);
            margin-bottom: 20px;
        }

        .product-stock.agotado {
            color: var(--naranja-oscuro);
            font-weight: 700;
        }

        .actions {
            display: flex;
            gap: 10px;
            margin-top: auto;
            flex-wrap: wrap;
        }

        .btn-primary {
            flex: 1;
            min-width: 160px;
            background: var(--naranja);
            color: var(--blanco);
            border: none;
            border-radius: 12px;
            padding: 14px 20px;
            font-size: 15px;
            font-weight: 700;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .btn-primary:disabled {
            background: var(--borde);
            color: #c9bcae;
            cursor: not-allowed;
        }

        .btn-whatsapp {
            flex: 1;
            min-width: 160px;
            background: var(--whatsapp);
            color: var(--blanco);
            text-decoration: none;
            border-radius: 12px;
            padding: 14px 20px;
            font-size: 15px;
            font-weight: 700;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .section-title {
            font-family: 'Sora', sans-serif;
            font-size: 16px;
            font-weight: 700;
            margin: 32px 0 14px;
        }

        .products {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
            gap: 12px;
        }

        .product {
            background: var(--blanco);
            border-radius: 13px;
            padding: 9px;
            display: flex;
            flex-direction: column;
            gap: 7px;
            box-shadow: var(--sombra);
            text-decoration: none;
            color: var(--texto);
        }

        .product-img-wrap {
            position: relative;
            aspect-ratio: 1 / 1;
            border-radius: 9px;
            overflow: hidden;
            background: #f5efe9;
        }

        .product-img-wrap img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .product-img-wrap .placeholder {
            width: 100%;
            height: 100%;
            display: grid;
            place-items: center;
            font-size: 32px;
        }

        .product-card-name {
            font-size: 12.5px;
            font-weight: 600;
            line-height: 1.3;
            min-height: 32px;
            margin: 0;
        }

        .product-card-price {
            font-family: 'Sora', sans-serif;
            font-weight: 800;
            font-size: 14.5px;
            margin-top: auto;
        }

        footer {
            background: var(--blanco);
            border-top: 1px solid var(--borde);
            padding: 20px 16px;
            text-align: center;
            color: var(--texto-suave);
            font-size: 12px;
            margin-top: 40px;
        }

        .modal-overlay {
            position: fixed;
            inset: 0;
            z-index: 40;
            background: rgba(34, 29, 24, 0.35);
            opacity: 0;
            visibility: hidden;
            transition: opacity 0.2s ease;
            display: flex;
            align-items: flex-end;
            justify-content: center;
        }

        .modal-overlay.open {
            opacity: 1;
            visibility: visible;
        }

        .modal-panel {
            background: var(--blanco);
            width: 100%;
            max-width: 480px;
            max-height: 92vh;
            overflow-y: auto;
            border-radius: 18px 18px 0 0;
            padding: 20px;
            transform: translateY(100%);
            transition: transform 0.25s ease;
        }

        .modal-overlay.open .modal-panel {
            transform: translateY(0);
        }

        .modal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 16px;
        }

        .modal-header h3 {
            font-family: 'Sora', sans-serif;
            font-size: 17px;
            font-weight: 700;
            margin: 0;
        }

        .modal-close {
            background: none;
            border: none;
            font-size: 24px;
            color: var(--texto-suave);
            cursor: pointer;
            line-height: 1;
        }

        .modal-form {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .modal-form label {
            font-size: 12px;
            font-weight: 600;
            color: var(--texto-medio);
        }

        .modal-form input,
        .modal-form textarea {
            border: 1px solid var(--borde-fuerte);
            border-radius: 10px;
            padding: 10px 12px;
            font-size: 14px;
            font-family: inherit;
            color: var(--texto);
            background: var(--blanco);
        }

        .modal-form input:focus,
        .modal-form textarea:focus {
            outline: none;
            border-color: var(--naranja);
        }

        .modal-form textarea {
            resize: vertical;
            min-height: 70px;
        }

        .modal-total {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin: 14px 0 6px;
            font-size: 15px;
            font-weight: 700;
        }

        .modal-total span:first-child {
            color: var(--texto-medio);
        }

        .modal-submit {
            width: 100%;
            padding: 13px;
            border: none;
            border-radius: 12px;
            background: var(--whatsapp);
            color: var(--blanco);
            font-size: 15px;
            font-weight: 700;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .modal-submit:disabled {
            background: var(--borde);
            color: #c9bcae;
            cursor: not-allowed;
        }

        @media (min-width: 520px) {
            .modal-overlay { align-items: center; }
            .modal-panel { border-radius: 18px; max-height: 88vh; }
        }

        @media (max-width: 480px) {
            .app-btn span { display: none; }
            .product-name { font-size: 20px; }
            .product-price { font-size: 24px; }
            .products { grid-template-columns: repeat(2, 1fr); }
        }
    </style>
</head>
<body>
    <header>
        <div class="header-inner">
            <a href="{{ route('tienda.show', $empresa->slug_tienda) }}" class="brand">
                @if($empresa->logo_path)
                    <img src="{{ url($empresa->logo_path) }}" alt="{{ $empresa->nombre }}">
                @else
                    <div style="width:32px;height:32px;border-radius:9px;background:#fdeadd;display:grid;place-items:center;font-size:16px">🏪</div>
                @endif
                <span class="brand-name">{{ $empresa->nombre }}</span>
            </a>
            <div class="header-actions">
                <button class="icon-btn" id="shareProductBtn" title="Compartir producto">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.6" y1="10.5" x2="15.4" y2="6.5"/><line x1="8.6" y1="13.5" x2="15.4" y2="17.5"/></svg>
                </button>
                <a href="#" class="app-btn" id="openAppBtn">
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
                    <span>Abrir app</span>
                </a>
            </div>
        </div>
    </header>

    <main class="container">
        <nav class="breadcrumbs">
            <a href="{{ route('tienda.show', $empresa->slug_tienda) }}">Tienda</a>
            &nbsp;/&nbsp;
            {{ $productoModel->nombre }}
        </nav>

        <article class="product-detail">
            <div class="product-image">
                @if($productoModel->imagen_path)
                    <img src="{{ url($productoModel->imagen_path) }}" alt="{{ $productoModel->nombre }}">
                @else
                    <div class="placeholder">🛍️</div>
                @endif
            </div>
            <div class="product-info">
                @if($productoModel->categoria)
                    <span class="product-category">{{ $productoModel->categoria->nombre }}</span>
                @endif
                <h1 class="product-name">{{ $productoModel->nombre }}</h1>
                <div class="product-price">{{ $empresa->moneda }} {{ number_format($productoModel->precio, 2) }}</div>
                <div class="product-stock {{ $productoModel->stock <= 0 ? 'agotado' : '' }}">
                    @if($productoModel->stock <= 0)
                        Agotado
                    @else
                        {{ $productoModel->stock }} unidades disponibles
                    @endif
                </div>
                <div class="actions">
                    <button class="btn-primary" id="addToCartBtn" @disabled($productoModel->stock <= 0)>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/></svg>
                        Agregar a la canasta
                    </button>
                    @if($empresa->telefono && $productoModel->stock > 0)
                        <button class="btn-whatsapp" id="pedirAhoraBtn" type="button">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.5 2 2 6.5 2 12c0 1.8.5 3.6 1.4 5.1L2 22l5-1.3c1.4.8 3.1 1.2 4.9 1.2h.1c5.5 0 10-4.5 10-10S17.5 2 12 2zm0 18.3h-.1c-1.6 0-3.2-.4-4.5-1.2l-.3-.2-3 .8.8-2.9-.2-.3C3.8 15.2 3.3 13.6 3.3 12c0-4.8 3.9-8.7 8.7-8.7s8.7 3.9 8.7 8.7-3.9 8.7-8.7 8.7z"/></svg>
                            Pedir ahora
                        </button>
                    @endif
                </div>
            </div>
        </article>

        @if($relacionados->isNotEmpty())
            <h2 class="section-title">También te puede interesar</h2>
            <div class="products">
                @foreach($relacionados as $rel)
                    @php
                        $slugRel = \Illuminate\Support\Str::slug($rel->nombre);
                        $imagenRel = $rel->imagen_path ? url($rel->imagen_path) : '';
                    @endphp
                    <a href="{{ route('tienda.producto', ['slug' => $empresa->slug_tienda, 'producto' => $rel->id, 'nombreSlug' => $slugRel]) }}" class="product">
                        <div class="product-img-wrap">
                            @if($imagenRel)
                                <img src="{{ $imagenRel }}" alt="{{ $rel->nombre }}" loading="lazy">
                            @else
                                <div class="placeholder">🛍️</div>
                            @endif
                        </div>
                        <h3 class="product-card-name">{{ $rel->nombre }}</h3>
                        <span class="product-card-price">{{ $empresa->moneda }} {{ number_format($rel->precio, 2) }}</span>
                    </a>
                @endforeach
            </div>
        @endif
    </main>

    <footer>
        {{ $empresa->nombre }} · {{ $empresa->telefono }} · {{ $empresa->direccion }}
    </footer>

    <div class="modal-overlay" id="pedidoModalOverlay">
        <div class="modal-panel">
            <div class="modal-header">
                <h3>Tu pedido</h3>
                <button class="modal-close" id="cerrarModalBtn">×</button>
            </div>
            <div class="modal-form">
                <label for="clienteNombre">Tu nombre</label>
                <input type="text" id="clienteNombre" placeholder="Ej. Juan Pérez">
                <label for="clienteTelefono">Teléfono</label>
                <input type="tel" id="clienteTelefono" placeholder="Ej. 70012345">
                <label for="clienteDireccion">Dirección de entrega</label>
                <input type="text" id="clienteDireccion" placeholder="Ej. Av. América #245">
                <label for="pedidoNotas">Notas adicionales</label>
                <textarea id="pedidoNotas" placeholder="Ej. Sin picante, entregar por la tarde..."></textarea>
            </div>
            <div class="modal-total">
                <span>Total</span>
                <span id="modalTotal">{{ $empresa->moneda }} {{ number_format($productoModel->precio, 2) }}</span>
            </div>
            <button class="modal-submit" id="confirmarPedidoBtn" type="button">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.5 2 2 6.5 2 12c0 1.8.5 3.6 1.4 5.1L2 22l5-1.3c1.4.8 3.1 1.2 4.9 1.2h.1c5.5 0 10-4.5 10-10S17.5 2 12 2zm0 18.3h-.1c-1.6 0-3.2-.4-4.5-1.2l-.3-.2-3 .8.8-2.9-.2-.3C3.8 15.2 3.3 13.6 3.3 12c0-4.8 3.9-8.7 8.7-8.7s8.7 3.9 8.7 8.7-3.9 8.7-8.7 8.7zm5.5-5.9c-.3-.1-1.6-.8-1.9-.9-.2-.1-.4-.1-.6.1-.2.3-.7.9-.8 1-.2.2-.3.2-.5.1-.3-.1-1.2-.4-2.2-1.4-.8-.8-1.4-1.7-1.5-2-.2-.3 0-.5.1-.6.1-.1.3-.3.4-.5.1-.1.2-.3.2-.5.1-.2 0-.4 0-.5-.1-.1-.6-1.5-.8-2-.2-.5-.4-.5-.6-.5h-.5c-.2 0-.5.1-.7.3-.2.3-.9.9-.9 2.2s1 2.6 1.1 2.7c.1.2 2 3 4.7 4.2.7.3 1.2.5 1.6.6.7.2 1.3.2 1.8.1.5-.1 1.6-.7 1.9-1.3.2-.6.2-1.1.2-1.2-.1-.2-.3-.2-.5-.3z"/></svg>
                Confirmar y pedir por WhatsApp
            </button>
        </div>
    </div>

    <script>
        const TELEFONO = '{{ $empresa->telefono }}';
        const EMPRESA_ID = {{ $empresa->id }};
        const EMPRESA_NOMBRE = '{{ $empresa->nombre }}';
        const PRODUCTO_ID = {{ $productoModel->id }};
        const PRODUCTO_NOMBRE = '{{ $productoModel->nombre }}';
        const PRODUCTO_PRECIO = {{ $productoModel->precio }};
        const PRODUCTO_IMAGEN = '{{ $productoModel->imagen_path ? url($productoModel->imagen_path) : '' }}';
        const MONEDA = '{{ $empresa->moneda }}';
        const URL_ACTUAL = window.location.href;

        function formatearPrecio(precio) {
            return MONEDA + ' ' + precio.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
        }

        document.getElementById('shareProductBtn').addEventListener('click', function () {
            const texto = `${PRODUCTO_NOMBRE} — ${EMPRESA_NOMBRE}`;
            if (navigator.share) {
                navigator.share({ title: PRODUCTO_NOMBRE, text: texto, url: URL_ACTUAL }).catch(() => {});
            } else {
                window.open('https://wa.me/?text=' + encodeURIComponent(texto + ' ' + URL_ACTUAL), '_blank');
            }
        });

        document.getElementById('addToCartBtn').addEventListener('click', function () {
            const SLUG = '{{ $empresa->slug_tienda }}';
            let carrito = {};
            const guardado = localStorage.getItem('tienda_' + SLUG + '_carrito');
            if (guardado) {
                try { carrito = JSON.parse(guardado); } catch (e) { carrito = {}; }
            }

            const id = String(PRODUCTO_ID);
            if (carrito[id]) {
                carrito[id].cantidad += 1;
            } else {
                carrito[id] = {
                    id: id,
                    nombre: PRODUCTO_NOMBRE,
                    precio: PRODUCTO_PRECIO,
                    imagen: PRODUCTO_IMAGEN,
                    cantidad: 1
                };
            }

            localStorage.setItem('tienda_' + SLUG + '_carrito', JSON.stringify(carrito));
            this.textContent = '¡Agregado!';
            setTimeout(() => {
                this.innerHTML = `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/></svg> Agregar a la canasta`;
            }, 1500);
        });

        // Modal de pedido rápido desde la página individual.
        const modalOverlay = document.getElementById('pedidoModalOverlay');
        const pedirAhoraBtn = document.getElementById('pedirAhoraBtn');
        const cerrarModalBtn = document.getElementById('cerrarModalBtn');
        const confirmarPedidoBtn = document.getElementById('confirmarPedidoBtn');

        function abrirModal() {
            modalOverlay.classList.add('open');
            document.body.style.overflow = 'hidden';
        }

        function cerrarModal() {
            modalOverlay.classList.remove('open');
            document.body.style.overflow = '';
        }

        async function confirmarPedido() {
            if (!TELEFONO) {
                alert('Esta tienda aún no tiene un teléfono configurado.');
                return;
            }

            const clienteNombre = document.getElementById('clienteNombre').value.trim();
            const clienteTelefono = document.getElementById('clienteTelefono').value.trim();
            const clienteDireccion = document.getElementById('clienteDireccion').value.trim();
            const pedidoNotas = document.getElementById('pedidoNotas').value.trim();

            if (!clienteNombre || !clienteTelefono) {
                alert('Por favor ingresa tu nombre y teléfono para continuar.');
                return;
            }

            confirmarPedidoBtn.disabled = true;
            confirmarPedidoBtn.textContent = 'Guardando pedido…';

            try {
                const respuesta = await fetch('/api/pedidos', {
                    method: 'POST',
                    headers: {
                        'Accept': 'application/json',
                        'Content-Type': 'application/json',
                        'X-Requested-With': 'XMLHttpRequest'
                    },
                    body: JSON.stringify({
                        empresa_id: EMPRESA_ID,
                        cliente_nombre: clienteNombre,
                        cliente_telefono: clienteTelefono,
                        direccion: clienteDireccion,
                        notas: pedidoNotas,
                        items: [
                            { producto_id: PRODUCTO_ID, cantidad: 1 }
                        ]
                    })
                });

                const datos = await respuesta.json().catch(() => ({}));

                if (!respuesta.ok) {
                    throw new Error(datos.message || 'No se pudo guardar el pedido. Inténtalo de nuevo.');
                }

                const pedido = datos.pedido;
                const numeroPedido = pedido ? pedido.id : '';
                const mensaje = `Hola ${EMPRESA_NOMBRE}, quisiera hacer este pedido:\n- 1x ${PRODUCTO_NOMBRE} (${formatearPrecio(PRODUCTO_PRECIO)})\nTotal: ${formatearPrecio(PRODUCTO_PRECIO)}${numeroPedido ? '\nN° pedido: ' + numeroPedido : ''}`;

                cerrarModal();
                window.open('https://wa.me/' + TELEFONO.replace(/\D/g, '') + '?text=' + encodeURIComponent(mensaje), '_blank');
            } catch (error) {
                alert(error.message);
            } finally {
                confirmarPedidoBtn.disabled = false;
                confirmarPedidoBtn.innerHTML = `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.5 2 2 6.5 2 12c0 1.8.5 3.6 1.4 5.1L2 22l5-1.3c1.4.8 3.1 1.2 4.9 1.2h.1c5.5 0 10-4.5 10-10S17.5 2 12 2zm0 18.3h-.1c-1.6 0-3.2-.4-4.5-1.2l-.3-.2-3 .8.8-2.9-.2-.3C3.8 15.2 3.3 13.6 3.3 12c0-4.8 3.9-8.7 8.7-8.7s8.7 3.9 8.7 8.7-3.9 8.7-8.7 8.7zm5.5-5.9c-.3-.1-1.6-.8-1.9-.9-.2-.1-.4-.1-.6.1-.2.3-.7.9-.8 1-.2.2-.3.2-.5.1-.3-.1-1.2-.4-2.2-1.4-.8-.8-1.4-1.7-1.5-2-.2-.3 0-.5.1-.6.1-.1.3-.3.4-.5.1-.1.2-.3.2-.5.1-.2 0-.4 0-.5-.1-.1-.6-1.5-.8-2-.2-.5-.4-.5-.6-.5h-.5c-.2 0-.5.1-.7.3-.2.3-.9.9-.9 2.2s1 2.6 1.1 2.7c.1.2 2 3 4.7 4.2.7.3 1.2.5 1.6.6.7.2 1.3.2 1.8.1.5-.1 1.6-.7 1.9-1.3.2-.6.2-1.1.2-1.2-.1-.2-.3-.2-.5-.3z"/></svg> Confirmar y pedir por WhatsApp`;
            }
        }

        if (pedirAhoraBtn) pedirAhoraBtn.addEventListener('click', abrirModal);
        if (cerrarModalBtn) cerrarModalBtn.addEventListener('click', cerrarModal);
        if (modalOverlay) modalOverlay.addEventListener('click', function (e) {
            if (e.target === modalOverlay) cerrarModal();
        });
        if (confirmarPedidoBtn) confirmarPedidoBtn.addEventListener('click', confirmarPedido);

        // Enlace a la app: intenta abrir el deep link; si no existe, lleva a descarga.
        document.getElementById('openAppBtn').addEventListener('click', function (e) {
            e.preventDefault();
            window.location.href = 'minegocio://tienda/{{ $empresa->slug_tienda }}';
            setTimeout(function () {
                window.location.href = 'https://play.google.com/store/apps/details?id=com.example.minegocio';
            }, 1500);
        });
    </script>
</body>
</html>
