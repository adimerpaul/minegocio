<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $empresa->nombre }} — Tienda en línea</title>
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

        .font-sora { font-family: 'Sora', sans-serif; }

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

        .icon-btn {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 36px;
            height: 36px;
            background: var(--blanco);
            color: var(--texto);
            border: 1px solid var(--borde-fuerte);
            border-radius: 10px;
            cursor: pointer;
        }

        .app-btn {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            height: 36px;
            padding: 0 12px;
            background: var(--naranja);
            color: var(--blanco);
            border: none;
            border-radius: 10px;
            font-size: 13px;
            font-weight: 700;
            text-decoration: none;
            cursor: pointer;
        }

        .cart-btn {
            position: relative;
            display: flex;
            align-items: center;
            gap: 7px;
            background: var(--naranja);
            color: var(--blanco);
            border: none;
            padding: 8px 14px;
            border-radius: 10px;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
        }

        .cart-btn .count {
            background: var(--blanco);
            color: var(--naranja);
            font-size: 11px;
            font-weight: 800;
            min-width: 18px;
            height: 18px;
            border-radius: 999px;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 0 4px;
        }

        .container {
            max-width: 1120px;
            margin: 0 auto;
            padding: 14px 16px;
        }

        .hero {
            background: var(--naranja);
            border-radius: 16px;
            padding: clamp(20px, 3.5vw, 32px);
            color: var(--blanco);
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 20px;
            flex-wrap: wrap;
        }

        .hero h1 {
            font-family: 'Sora', sans-serif;
            font-size: clamp(20px, 3.2vw, 28px);
            font-weight: 800;
            margin: 0 0 6px;
            line-height: 1.15;
            letter-spacing: -0.02em;
        }

        .hero p {
            margin: 0;
            font-size: 13px;
            opacity: 0.85;
        }

        .hero a {
            background: var(--blanco);
            color: var(--naranja);
            text-decoration: none;
            font-weight: 700;
            font-size: 13px;
            padding: 10px 18px;
            border-radius: 10px;
            flex-shrink: 0;
        }

        .categories {
            display: flex;
            gap: 8px;
            margin: 16px 0;
            flex-wrap: wrap;
        }

        .cat-btn {
            border: 1px solid var(--borde-fuerte);
            background: var(--blanco);
            color: var(--texto-medio);
            padding: 7px 14px;
            border-radius: 10px;
            font-size: 12.5px;
            font-weight: 600;
            cursor: pointer;
        }

        .cat-btn.active {
            border-color: var(--naranja);
            background: #fdeadd;
            color: var(--naranja);
        }

        .section-header {
            display: flex;
            align-items: baseline;
            justify-content: space-between;
            margin-bottom: 10px;
        }

        .section-header h2 {
            font-family: 'Sora', sans-serif;
            font-size: 16px;
            font-weight: 700;
            margin: 0;
        }

        .section-header span {
            font-size: 12px;
            color: var(--texto-suave);
        }

        .products {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
            gap: 12px;
            padding-bottom: 50px;
        }

        .product {
            background: var(--blanco);
            border-radius: 13px;
            padding: 9px;
            display: flex;
            flex-direction: column;
            gap: 7px;
            box-shadow: var(--sombra);
            animation: fadeUp .35s ease both;
            position: relative;
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

        .badge {
            position: absolute;
            top: 6px;
            left: 6px;
            background: var(--texto);
            color: var(--blanco);
            font-size: 10px;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 999px;
            pointer-events: none;
        }

        .share-product {
            position: absolute;
            top: 6px;
            right: 6px;
            width: 26px;
            height: 26px;
            border-radius: 50%;
            background: rgba(255,255,255,0.95);
            border: none;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            box-shadow: 0 1px 4px rgba(0,0,0,0.1);
        }

        .product-name {
            font-size: 12.5px;
            font-weight: 600;
            line-height: 1.3;
            min-height: 32px;
            margin: 0;
        }

        .product-footer {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 6px;
            margin-top: auto;
        }

        .product-price {
            font-family: 'Sora', sans-serif;
            font-weight: 800;
            font-size: 14.5px;
        }

        .product-actions {
            display: flex;
            align-items: center;
            gap: 5px;
        }

        .qty-badge {
            font-size: 12px;
            font-weight: 800;
            color: var(--naranja);
        }

        .add-btn {
            width: 28px;
            height: 28px;
            border-radius: 8px;
            border: none;
            background: var(--naranja);
            color: var(--blanco);
            font-size: 16px;
            font-weight: 700;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            line-height: 1;
        }

        .add-btn:disabled {
            background: #f5efe9;
            color: #c9bcae;
            cursor: not-allowed;
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: var(--texto-suave);
        }

        .empty-state svg {
            width: 64px;
            height: 64px;
            stroke: var(--borde-fuerte);
            margin-bottom: 16px;
        }

        /* Drawer */
        .cart-overlay {
            position: fixed;
            inset: 0;
            z-index: 40;
            background: rgba(34, 29, 24, 0.35);
            opacity: 0;
            visibility: hidden;
            transition: opacity 0.2s ease;
        }

        .cart-overlay.open {
            opacity: 1;
            visibility: visible;
        }

        .cart-panel {
            position: fixed;
            top: 0;
            right: 0;
            bottom: 0;
            z-index: 50;
            width: min(360px, 92vw);
            background: var(--blanco);
            box-shadow: -8px 0 30px rgba(0,0,0,0.12);
            display: flex;
            flex-direction: column;
            transform: translateX(100%);
            transition: transform 0.25s ease;
        }

        .cart-panel.open {
            transform: translateX(0);
        }

        .cart-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 18px;
            border-bottom: 1px solid var(--borde);
        }

        .cart-header h3 {
            font-family: 'Sora', sans-serif;
            font-weight: 700;
            font-size: 16px;
            margin: 0;
        }

        .close-cart {
            background: none;
            border: none;
            font-size: 20px;
            cursor: pointer;
            color: var(--texto-suave);
            line-height: 1;
        }

        .cart-items {
            flex: 1;
            overflow-y: auto;
            padding: 12px 18px;
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .cart-item {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .cart-item img {
            width: 48px;
            height: 48px;
            object-fit: cover;
            border-radius: 8px;
            background: var(--fondo);
        }

        .cart-item-thumb {
            width: 48px;
            height: 48px;
            border-radius: 8px;
            background: var(--fondo);
            display: grid;
            place-items: center;
            font-size: 20px;
        }

        .cart-item-info {
            flex: 1;
            min-width: 0;
        }

        .cart-item-name {
            font-size: 13px;
            font-weight: 600;
            margin: 0;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .cart-item-price {
            font-size: 12px;
            color: var(--texto-suave);
            margin: 2px 0 0;
        }

        .qty-controls {
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .qty-controls button {
            width: 24px;
            height: 24px;
            border-radius: 7px;
            border: 1px solid var(--borde-fuerte);
            background: var(--blanco);
            cursor: pointer;
            font-weight: 700;
            color: var(--texto);
            line-height: 1;
        }

        .qty-controls span {
            font-size: 13px;
            font-weight: 700;
            min-width: 18px;
            text-align: center;
        }

        .cart-item-subtotal {
            font-size: 13px;
            font-weight: 700;
            min-width: 64px;
            text-align: right;
        }

        .cart-empty {
            text-align: center;
            color: var(--texto-suave);
            font-size: 13px;
            padding: 40px 0;
        }

        .cart-footer {
            border-top: 1px solid var(--borde);
            padding: 14px 18px;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .cart-form {
            display: flex;
            flex-direction: column;
            gap: 8px;
            margin-bottom: 6px;
        }

        .cart-form label {
            font-size: 12px;
            font-weight: 600;
            color: var(--texto-medio);
        }

        .cart-form input,
        .cart-form textarea {
            border: 1px solid var(--borde-fuerte);
            border-radius: 9px;
            padding: 9px 11px;
            font-size: 13px;
            font-family: inherit;
            color: var(--texto);
            background: var(--blanco);
        }

        .cart-form input:focus,
        .cart-form textarea:focus {
            outline: none;
            border-color: var(--naranja);
        }

        .cart-form textarea {
            resize: vertical;
            min-height: 60px;
        }

        .cart-total {
            display: flex;
            justify-content: space-between;
            font-size: 14px;
        }

        .cart-total span:first-child {
            color: var(--texto-suave);
            font-weight: 600;
        }

        .cart-total span:last-child {
            font-family: 'Sora', sans-serif;
            font-weight: 800;
            font-size: 18px;
        }

        .checkout-btn {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            width: 100%;
            padding: 12px;
            border: none;
            border-radius: 11px;
            font-weight: 700;
            font-size: 14px;
            cursor: pointer;
        }

        .checkout-btn.active {
            background: var(--whatsapp);
            color: var(--blanco);
        }

        .checkout-btn:disabled {
            background: var(--borde);
            color: #c9bcae;
            cursor: not-allowed;
        }

        footer {
            background: var(--blanco);
            border-top: 1px solid var(--borde);
            padding: 20px 16px;
            text-align: center;
            color: var(--texto-suave);
            font-size: 12px;
        }

        @keyframes fadeUp {
            from { opacity: 0; transform: translateY(8px); }
            to { opacity: 1; transform: translateY(0); }
        }

        @media (max-width: 480px) {
            .products { grid-template-columns: repeat(2, 1fr); }
        }
    </style>
</head>
<body>
    <header>
        <div class="header-inner">
            <div class="brand">
                @if($empresa->logo_path)
                    <img src="{{ url($empresa->logo_path) }}" alt="{{ $empresa->nombre }}">
                @else
                    <div style="width:32px;height:32px;border-radius:9px;background:#fdeadd;display:grid;place-items:center;font-size:16px">🏪</div>
                @endif
                <span class="brand-name">{{ $empresa->nombre }}</span>
            </div>
            <div class="header-actions">
                <button class="icon-btn" id="shareStoreBtn" title="Compartir tienda">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.6" y1="10.5" x2="15.4" y2="6.5"/><line x1="8.6" y1="13.5" x2="15.4" y2="17.5"/></svg>
                </button>
                <a href="#" class="app-btn" id="openAppBtn">
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
                    <span>Abrir app</span>
                </a>
                <button class="cart-btn" id="cartBtn">
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/></svg>
                    Canasta
                    <span class="count" id="cartCount" style="display:none">0</span>
                </button>
            </div>
        </div>
    </header>

    <div class="container">
        <section class="hero">
            <div>
                <h1>Arma tu canasta y pide por WhatsApp</h1>
                <p>Agrega productos con el botón + y envíanos tu pedido completo en un mensaje.</p>
            </div>
            @if($empresa->telefono)
                <a href="https://wa.me/{{ preg_replace('/\D/', '', $empresa->telefono) }}" target="_blank">Escríbenos</a>
            @endif
        </section>

        @php
            $categorias = $empresa->categorias->pluck('nombre')->sort()->values()->all();
        @endphp

        @if(!empty($categorias))
            <div class="categories" id="categories">
                <button class="cat-btn active" data-cat="Todos">Todos</button>
                @foreach($categorias as $categoria)
                    <button class="cat-btn" data-cat="{{ $categoria }}">{{ $categoria }}</button>
                @endforeach
            </div>
        @endif

        <div class="section-header">
            <h2>Productos</h2>
            <span id="totalLabel">{{ $empresa->productos->count() }} artículos</span>
        </div>

        @if($empresa->productos->isEmpty())
            <div class="empty-state">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/></svg>
                <p>La tienda aún no tiene productos disponibles.</p>
            </div>
        @else
            <div class="products" id="products">
                @foreach($empresa->productos as $producto)
                    @php
                        $categoriaNombre = $producto->categoria?->nombre ?? 'Sin categoría';
                        $agotado = $producto->stock <= 0;
                        $imagen = $producto->imagen_path ? url($producto->imagen_path) : '';
                    @endphp
                    @php
                        $productoSlug = \Illuminate\Support\Str::slug($producto->nombre);
                        $productoUrl = route('tienda.producto', ['slug' => $empresa->slug_tienda, 'producto' => $producto->id, 'nombreSlug' => $productoSlug]);
                    @endphp
                    <article class="product" data-id="{{ $producto->id }}" data-url="{{ $productoUrl }}" data-cat="{{ $categoriaNombre }}" data-nombre="{{ $producto->nombre }}" data-precio="{{ $producto->precio }}" data-imagen="{{ $imagen }}" data-agotado="{{ $agotado ? '1' : '0' }}" style="display:flex">
                        <div class="product-img-wrap">
                            @if($imagen)
                                <img src="{{ $imagen }}" alt="{{ $producto->nombre }}" loading="lazy">
                            @else
                                <div class="placeholder">🛍️</div>
                            @endif
                            @if($agotado)
                                <span class="badge">Agotado</span>
                            @endif
                            <button class="share-product" data-id="{{ $producto->id }}" title="Compartir producto">
                                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#221d18" stroke-width="2.2" stroke-linecap="round"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.6" y1="10.5" x2="15.4" y2="6.5"/><line x1="8.6" y1="13.5" x2="15.4" y2="17.5"/></svg>
                            </button>
                        </div>
                        <h4 class="product-name">{{ $producto->nombre }}</h4>
                        <div class="product-footer">
                            <span class="product-price">{{ $empresa->moneda }} {{ number_format($producto->precio, 2) }}</span>
                            <div class="product-actions">
                                <span class="qty-badge" data-qty-id="{{ $producto->id }}" style="display:none"></span>
                                <button class="add-btn" data-id="{{ $producto->id }}" @disabled($agotado)>+</button>
                            </div>
                        </div>
                    </article>
                @endforeach
            </div>
        @endif
    </div>

    <footer>
        {{ $empresa->nombre }} · {{ $empresa->telefono }} · {{ $empresa->direccion }}
    </footer>

    <div class="cart-overlay" id="cartOverlay"></div>
    <aside class="cart-panel" id="cartPanel">
        <div class="cart-header">
            <h3>Mi canasta</h3>
            <button class="close-cart" id="closeCart">×</button>
        </div>
        <div class="cart-items" id="cartItems">
            <div class="cart-empty">Tu canasta está vacía.<br>Agrega productos con el botón +</div>
        </div>
        <div class="cart-footer">
            <div class="cart-form">
                <label for="clienteNombre">Tu nombre</label>
                <input type="text" id="clienteNombre" placeholder="Ej. Juan Pérez">
                <label for="clienteTelefono">Teléfono</label>
                <input type="tel" id="clienteTelefono" placeholder="Ej. 70012345">
                <label for="clienteDireccion">Dirección de entrega</label>
                <input type="text" id="clienteDireccion" placeholder="Ej. Av. América #245">
                <label for="pedidoNotas">Notas adicionales</label>
                <textarea id="pedidoNotas" placeholder="Ej. Sin picante, entregar por la tarde..."></textarea>
            </div>
            <div class="cart-total">
                <span>Total</span>
                <span id="cartTotal">{{ $empresa->moneda }} 0.00</span>
            </div>
            <button class="checkout-btn" id="checkoutBtn" disabled>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.5 2 2 6.5 2 12c0 1.8.5 3.6 1.4 5.1L2 22l5-1.3c1.4.8 3.1 1.2 4.9 1.2h.1c5.5 0 10-4.5 10-10S17.5 2 12 2zm0 18.3h-.1c-1.6 0-3.2-.4-4.5-1.2l-.3-.2-3 .8.8-2.9-.2-.3C3.8 15.2 3.3 13.6 3.3 12c0-4.8 3.9-8.7 8.7-8.7s8.7 3.9 8.7 8.7-3.9 8.7-8.7 8.7zm5.5-5.9c-.3-.1-1.6-.8-1.9-.9-.2-.1-.4-.1-.6.1-.2.3-.7.9-.8 1-.2.2-.3.2-.5.1-.3-.1-1.2-.4-2.2-1.4-.8-.8-1.4-1.7-1.5-2-.2-.3 0-.5.1-.6.1-.1.3-.3.4-.5.1-.1.2-.3.2-.5.1-.2 0-.4 0-.5-.1-.1-.6-1.5-.8-2-.2-.5-.4-.5-.6-.5h-.5c-.2 0-.5.1-.7.3-.2.3-.9.9-.9 2.2s1 2.6 1.1 2.7c.1.2 2 3 4.7 4.2.7.3 1.2.5 1.6.6.7.2 1.3.2 1.8.1.5-.1 1.6-.7 1.9-1.3.2-.6.2-1.1.2-1.2-.1-.2-.3-.2-.5-.3z"/></svg>
                <span id="checkoutText">Pedir por WhatsApp</span>
            </button>
        </div>
    </aside>

    <script>
        const MONEDA = '{{ $empresa->moneda }}';
        const TELEFONO = '{{ $empresa->telefono }}';
        const SLUG = '{{ $empresa->slug_tienda }}';
        const EMPRESA_ID = {{ $empresa->id }};
        const EMPRESA_NOMBRE = '{{ $empresa->nombre }}';

        let carrito = {};
        let categoriaActiva = 'Todos';

        const cartBtn = document.getElementById('cartBtn');
        const cartOverlay = document.getElementById('cartOverlay');
        const cartPanel = document.getElementById('cartPanel');
        const closeCart = document.getElementById('closeCart');
        const cartCount = document.getElementById('cartCount');
        const cartItems = document.getElementById('cartItems');
        const cartTotal = document.getElementById('cartTotal');
        const checkoutBtn = document.getElementById('checkoutBtn');

        function abrirCarrito() {
            cartOverlay.classList.add('open');
            cartPanel.classList.add('open');
            document.body.style.overflow = 'hidden';
        }

        function cerrarCarrito() {
            cartOverlay.classList.remove('open');
            cartPanel.classList.remove('open');
            document.body.style.overflow = '';
        }

        function guardarCarrito() {
            localStorage.setItem('tienda_' + SLUG + '_carrito', JSON.stringify(carrito));
        }

        function cargarCarrito() {
            const guardado = localStorage.getItem('tienda_' + SLUG + '_carrito');
            if (guardado) {
                try { carrito = JSON.parse(guardado); } catch (e) { carrito = {}; }
            }
        }

        function totalCarrito() {
            return Object.values(carrito).reduce((sum, item) => sum + (item.precio * item.cantidad), 0);
        }

        function cantidadCarrito() {
            return Object.values(carrito).reduce((sum, item) => sum + item.cantidad, 0);
        }

        function formatearPrecio(precio) {
            return MONEDA + ' ' + precio.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
        }

        function actualizarBadgeProducto(id) {
            const badge = document.querySelector('[data-qty-id="' + id + '"]');
            if (!badge) return;
            const cantidad = carrito[id]?.cantidad || 0;
            badge.textContent = cantidad;
            badge.style.display = cantidad > 0 ? 'inline' : 'none';
        }

        function renderCarrito() {
            const items = Object.values(carrito);
            const total = totalCarrito();
            const cantidad = cantidadCarrito();

            cartCount.textContent = cantidad;
            cartCount.style.display = cantidad > 0 ? 'grid' : 'none';
            cartTotal.textContent = formatearPrecio(total);

            checkoutBtn.disabled = cantidad === 0;
            checkoutBtn.classList.toggle('active', cantidad > 0);

            if (items.length === 0) {
                cartItems.innerHTML = '<div class="cart-empty">Tu canasta está vacía.<br>Agrega productos con el botón +</div>';
            } else {
                cartItems.innerHTML = items.map(item => `
                    <div class="cart-item">
                        ${item.imagen ? '<img src="' + item.imagen + '" alt="' + item.nombre + '">' : '<div class="cart-item-thumb">🛍️</div>'}
                        <div class="cart-item-info">
                            <p class="cart-item-name">${item.nombre}</p>
                            <p class="cart-item-price">${formatearPrecio(item.precio)} c/u</p>
                        </div>
                        <div class="qty-controls">
                            <button data-id="${item.id}" data-action="restar">−</button>
                            <span>${item.cantidad}</span>
                            <button data-id="${item.id}" data-action="sumar">+</button>
                        </div>
                        <span class="cart-item-subtotal">${formatearPrecio(item.precio * item.cantidad)}</span>
                    </div>
                `).join('');
            }

            items.forEach(item => actualizarBadgeProducto(item.id));
        }

        function agregarProducto(id, nombre, precio, imagen) {
            const card = document.querySelector('.product[data-id="' + id + '"]');
            if (card && card.dataset.agotado === '1') return;

            if (carrito[id]) {
                carrito[id].cantidad += 1;
            } else {
                carrito[id] = { id, nombre, precio, imagen, cantidad: 1 };
            }
            guardarCarrito();
            renderCarrito();
        }

        function cambiarCantidad(id, delta) {
            if (!carrito[id]) return;
            carrito[id].cantidad += delta;
            if (carrito[id].cantidad <= 0) delete carrito[id];
            guardarCarrito();
            renderCarrito();
        }

        async function enviarPedido() {
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

            const items = Object.values(carrito).map(i => ({
                producto_id: parseInt(i.id),
                cantidad: i.cantidad
            }));

            checkoutBtn.disabled = true;
            checkoutText.textContent = 'Guardando pedido…';

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
                        items: items
                    })
                });

                const datos = await respuesta.json().catch(() => ({}));

                if (!respuesta.ok) {
                    throw new Error(datos.message || 'No se pudo guardar el pedido. Inténtalo de nuevo.');
                }

                const pedido = datos.pedido;
                const numeroPedido = pedido ? pedido.id : '';

                const resumenItems = Object.values(carrito).map(i =>
                    `- ${i.cantidad}x ${i.nombre} (${formatearPrecio(i.precio * i.cantidad)})`
                ).join('\n');
                const mensaje = `Hola ${EMPRESA_NOMBRE}, quisiera hacer este pedido:\n${resumenItems}\nTotal: ${formatearPrecio(totalCarrito())}${numeroPedido ? '\nN° pedido: ' + numeroPedido : ''}`;

                // Limpia el carrito una vez guardado el pedido.
                carrito = {};
                guardarCarrito();
                renderCarrito();
                cerrarCarrito();

                window.open('https://wa.me/' + TELEFONO.replace(/\D/g, '') + '?text=' + encodeURIComponent(mensaje), '_blank');
            } catch (error) {
                alert(error.message);
            } finally {
                checkoutBtn.disabled = cantidadCarrito() === 0;
                checkoutText.textContent = 'Pedir por WhatsApp';
            }
        }

        function filtrarCategoria(cat) {
            categoriaActiva = cat;
            document.querySelectorAll('.cat-btn').forEach(btn => {
                btn.classList.toggle('active', btn.dataset.cat === cat);
            });

            const productos = document.querySelectorAll('.product');
            let visibles = 0;
            productos.forEach(p => {
                const mostrar = cat === 'Todos' || p.dataset.cat === cat;
                p.style.display = mostrar ? 'flex' : 'none';
                if (mostrar) visibles++;
            });

            const totalLabel = document.getElementById('totalLabel');
            if (totalLabel) totalLabel.textContent = visibles + ' artículos';
        }

        function compartirProducto(id) {
            const card = document.querySelector('.product[data-id="' + id + '"]');
            if (!card) return;
            const nombre = card.dataset.nombre;
            const precio = parseFloat(card.dataset.precio);
            const url = card.dataset.url;
            const texto = `${nombre} - ${formatearPrecio(precio)} en ${EMPRESA_NOMBRE}`;

            if (navigator.share) {
                navigator.share({ title: nombre, text: texto, url }).catch(() => {});
            } else {
                window.open('https://wa.me/?text=' + encodeURIComponent(texto + ' ' + url), '_blank');
            }
        }

        function compartirTienda() {
            const url = window.location.href;
            const texto = `Mira la tienda de ${EMPRESA_NOMBRE}`;
            if (navigator.share) {
                navigator.share({ title: EMPRESA_NOMBRE, text: texto, url }).catch(() => {});
            } else {
                window.open('https://wa.me/?text=' + encodeURIComponent(texto + ' ' + url), '_blank');
            }
        }

        document.getElementById('products').addEventListener('click', function (e) {
            const addBtn = e.target.closest('.add-btn');
            if (addBtn) {
                const card = addBtn.closest('.product');
                agregarProducto(card.dataset.id, card.dataset.nombre, parseFloat(card.dataset.precio), card.dataset.imagen);
                return;
            }

            const shareBtn = e.target.closest('.share-product');
            if (shareBtn) {
                e.stopPropagation();
                compartirProducto(shareBtn.dataset.id);
                return;
            }

            const card = e.target.closest('.product');
            if (card && card.dataset.url) {
                window.location.href = card.dataset.url;
            }
        });

        cartItems.addEventListener('click', function (e) {
            const btn = e.target.closest('[data-action]');
            if (btn) cambiarCantidad(btn.dataset.id, btn.dataset.action === 'sumar' ? 1 : -1);
        });

        document.getElementById('categories').addEventListener('click', function (e) {
            const btn = e.target.closest('.cat-btn');
            if (btn) filtrarCategoria(btn.dataset.cat);
        });

        document.getElementById('shareStoreBtn').addEventListener('click', compartirTienda);
        document.getElementById('openAppBtn').addEventListener('click', function (e) {
            e.preventDefault();
            window.location.href = 'minegocio://tienda/{{ $empresa->slug_tienda }}';
            setTimeout(function () {
                window.location.href = 'https://play.google.com/store/apps/details?id=com.example.minegocio';
            }, 1500);
        });
        cartBtn.addEventListener('click', abrirCarrito);
        closeCart.addEventListener('click', cerrarCarrito);
        cartOverlay.addEventListener('click', cerrarCarrito);
        checkoutBtn.addEventListener('click', enviarPedido);

        cargarCarrito();
        renderCarrito();

        // Resaltar producto compartido por URL
        const params = new URLSearchParams(window.location.search);
        const productoId = params.get('producto');
        if (productoId) {
            const card = document.querySelector('.product[data-id="' + productoId + '"]');
            if (card) {
                setTimeout(() => {
                    card.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    card.style.outline = '2px solid #ea580c';
                    setTimeout(() => card.style.outline = '', 1500);
                }, 300);
            }
        }
    </script>
</body>
</html>
