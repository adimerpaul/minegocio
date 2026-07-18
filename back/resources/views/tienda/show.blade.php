<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $empresa->nombre }} — Tienda en línea</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --fondo: #FAF8F6;
            --texto: #221A15;
            --texto-medio: #5D5148;
            --texto-suave: #8A7D73;
            --primario: #F4632C;
            --primario-oscuro: #9A3D12;
            --tinte: #FFF3EC;
            --borde: #E4DDD6;
            --borde-suave: #EEE7E1;
            --blanco: #FFFFFF;
            --alerta: #B91C1C;
            --sombra: 0 4px 20px rgba(34, 26, 21, 0.08);
        }

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: 'Instrument Sans', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: var(--fondo);
            color: var(--texto);
            line-height: 1.5;
        }

        header {
            background: var(--blanco);
            border-bottom: 1px solid var(--borde-suave);
            position: sticky;
            top: 0;
            z-index: 10;
        }

        .header-inner {
            max-width: 900px;
            margin: 0 auto;
            padding: 16px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            min-width: 0;
        }

        .brand img {
            width: 48px;
            height: 48px;
            object-fit: cover;
            border-radius: 12px;
            flex-shrink: 0;
            background: var(--tinte);
        }

        .brand h1 {
            margin: 0;
            font-size: 18px;
            font-weight: 700;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .cart-btn {
            position: relative;
            background: var(--primario);
            color: var(--blanco);
            border: none;
            border-radius: 12px;
            padding: 10px 14px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 6px;
            flex-shrink: 0;
        }

        .cart-btn .count {
            position: absolute;
            top: -6px;
            right: -6px;
            background: var(--texto);
            color: var(--blanco);
            font-size: 11px;
            font-weight: 700;
            min-width: 20px;
            height: 20px;
            border-radius: 999px;
            display: grid;
            place-items: center;
            padding: 0 5px;
        }

        main {
            max-width: 900px;
            margin: 0 auto;
            padding: 24px 20px 120px;
        }

        .hero {
            background: var(--tinte);
            border-radius: 20px;
            padding: 28px 24px;
            margin-bottom: 28px;
            text-align: center;
        }

        .hero h2 {
            margin: 0 0 8px;
            font-size: 24px;
            font-weight: 700;
        }

        .hero p {
            margin: 0;
            color: var(--texto-medio);
            font-size: 15px;
        }

        .section-title {
            font-size: 16px;
            font-weight: 700;
            margin: 28px 0 14px;
            color: var(--texto);
        }

        .products {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
            gap: 16px;
        }

        .product {
            background: var(--blanco);
            border: 1px solid var(--borde-suave);
            border-radius: 16px;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            box-shadow: var(--sombra);
            transition: transform 0.15s ease;
        }

        .product:active {
            transform: scale(0.98);
        }

        .product-img {
            aspect-ratio: 1 / 1;
            background: var(--fondo);
            display: grid;
            place-items: center;
            overflow: hidden;
        }

        .product-img img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .product-img .placeholder {
            font-size: 36px;
            color: var(--borde);
        }

        .product-body {
            padding: 14px;
            flex: 1;
            display: flex;
            flex-direction: column;
        }

        .product-name {
            font-size: 14px;
            font-weight: 600;
            margin: 0 0 4px;
            line-height: 1.35;
        }

        .product-cat {
            font-size: 12px;
            color: var(--texto-suave);
            margin-bottom: 10px;
        }

        .product-footer {
            margin-top: auto;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 8px;
        }

        .product-price {
            font-size: 16px;
            font-weight: 700;
            color: var(--primario-oscuro);
        }

        .add-btn {
            background: var(--primario);
            color: var(--blanco);
            border: none;
            border-radius: 10px;
            width: 34px;
            height: 34px;
            font-size: 20px;
            cursor: pointer;
            display: grid;
            place-items: center;
        }

        .add-btn:disabled {
            background: var(--borde);
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
            stroke: var(--borde);
            margin-bottom: 16px;
        }

        /* Carrito lateral */
        .cart-overlay {
            position: fixed;
            inset: 0;
            background: rgba(34, 26, 21, 0.45);
            opacity: 0;
            visibility: hidden;
            transition: opacity 0.2s ease;
            z-index: 20;
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
            width: min(100%, 380px);
            background: var(--blanco);
            transform: translateX(100%);
            transition: transform 0.25s ease;
            z-index: 21;
            display: flex;
            flex-direction: column;
        }

        .cart-panel.open {
            transform: translateX(0);
        }

        .cart-header {
            padding: 20px;
            border-bottom: 1px solid var(--borde-suave);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .cart-header h3 {
            margin: 0;
            font-size: 18px;
        }

        .close-cart {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: var(--texto-medio);
        }

        .cart-items {
            flex: 1;
            overflow-y: auto;
            padding: 16px 20px;
        }

        .cart-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 0;
            border-bottom: 1px solid var(--borde-suave);
        }

        .cart-item img {
            width: 48px;
            height: 48px;
            object-fit: cover;
            border-radius: 8px;
            background: var(--fondo);
        }

        .cart-item-info {
            flex: 1;
            min-width: 0;
        }

        .cart-item-name {
            font-size: 14px;
            font-weight: 600;
            margin: 0;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .cart-item-price {
            font-size: 13px;
            color: var(--texto-suave);
            margin: 2px 0 0;
        }

        .qty-controls {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .qty-controls button {
            width: 26px;
            height: 26px;
            border: 1px solid var(--borde);
            background: var(--blanco);
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
        }

        .qty-controls span {
            font-size: 14px;
            font-weight: 600;
            min-width: 20px;
            text-align: center;
        }

        .cart-footer {
            padding: 20px;
            border-top: 1px solid var(--borde-suave);
        }

        .cart-total {
            display: flex;
            justify-content: space-between;
            font-size: 18px;
            font-weight: 700;
            margin-bottom: 14px;
        }

        .checkout-btn {
            width: 100%;
            background: var(--primario);
            color: var(--blanco);
            border: none;
            border-radius: 14px;
            padding: 16px;
            font-size: 16px;
            font-weight: 700;
            cursor: pointer;
        }

        .checkout-btn:disabled {
            background: var(--borde);
            cursor: not-allowed;
        }

        .cart-empty {
            text-align: center;
            color: var(--texto-suave);
            padding: 40px 0;
        }

        footer {
            text-align: center;
            padding: 28px 20px;
            color: var(--texto-suave);
            font-size: 13px;
        }

        @media (max-width: 480px) {
            .hero h2 { font-size: 20px; }
            .products { grid-template-columns: repeat(2, 1fr); gap: 12px; }
            .product-body { padding: 12px; }
        }
    </style>
</head>
<body>
    <header>
        <div class="header-inner">
            <div class="brand">
                @if($empresa->logo_path)
                    <img src="{{ url($empresa->logo_path) }}" alt="{{ $empresa->nombre }}">
                @endif
                <h1>{{ $empresa->nombre }}</h1>
            </div>
            <button class="cart-btn" id="cartBtn" aria-label="Ver carrito">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path></svg>
                Carrito
                <span class="count" id="cartCount" style="display:none">0</span>
            </button>
        </div>
    </header>

    <main>
        <div class="hero">
            <h2>¡Bienvenido a {{ $empresa->nombre }}!</h2>
            <p>Explora nuestro catálogo y haz tu pedido en línea.</p>
        </div>

        @if($empresa->productos->isEmpty())
            <div class="empty-state">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"></path><line x1="3" y1="6" x2="21" y2="6"></line><path d="M16 10a4 4 0 0 1-8 0"></path></svg>
                <p>La tienda aún no tiene productos disponibles.</p>
            </div>
        @else
            <h3 class="section-title">Nuestros productos</h3>
            <div class="products" id="products">
                @foreach($empresa->productos as $producto)
                    <article class="product" data-id="{{ $producto->id }}" data-nombre="{{ $producto->nombre }}" data-precio="{{ $producto->precio }}" data-imagen="{{ $producto->imagen_path ? url($producto->imagen_path) : '' }}">
                        <div class="product-img">
                            @if($producto->imagen_path)
                                <img src="{{ url($producto->imagen_path) }}" alt="{{ $producto->nombre }}">
                            @else
                                <span class="placeholder">🛍️</span>
                            @endif
                        </div>
                        <div class="product-body">
                            <h4 class="product-name">{{ $producto->nombre }}</h4>
                            <span class="product-cat">{{ $producto->categoria?->nombre ?? 'Sin categoría' }}</span>
                            <div class="product-footer">
                                <span class="product-price">{{ $empresa->moneda }} {{ number_format($producto->precio, 2) }}</span>
                                <button class="add-btn" data-id="{{ $producto->id }}" aria-label="Agregar al carrito">+</button>
                            </div>
                        </div>
                    </article>
                @endforeach
            </div>
        @endif
    </main>

    <footer>
        {{ $empresa->nombre }} — Tienda en línea
    </footer>

    <div class="cart-overlay" id="cartOverlay"></div>
    <aside class="cart-panel" id="cartPanel">
        <div class="cart-header">
            <h3>Tu pedido</h3>
            <button class="close-cart" id="closeCart" aria-label="Cerrar">×</button>
        </div>
        <div class="cart-items" id="cartItems">
            <div class="cart-empty">El carrito está vacío</div>
        </div>
        <div class="cart-footer">
            <div class="cart-total">
                <span>Total</span>
                <span id="cartTotal">{{ $empresa->moneda }} 0.00</span>
            </div>
            <button class="checkout-btn" id="checkoutBtn" disabled>Enviar pedido por WhatsApp</button>
        </div>
    </aside>

    <script>
        const MONEDA = '{{ $empresa->moneda }}';
        const TELEFONO = '{{ $empresa->telefono }}';

        const cartBtn = document.getElementById('cartBtn');
        const cartOverlay = document.getElementById('cartOverlay');
        const cartPanel = document.getElementById('cartPanel');
        const closeCart = document.getElementById('closeCart');
        const cartCount = document.getElementById('cartCount');
        const cartItems = document.getElementById('cartItems');
        const cartTotal = document.getElementById('cartTotal');
        const checkoutBtn = document.getElementById('checkoutBtn');

        let carrito = {};

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
            localStorage.setItem('tienda_{{ $empresa->slug_tienda }}_carrito', JSON.stringify(carrito));
        }

        function cargarCarrito() {
            const guardado = localStorage.getItem('tienda_{{ $empresa->slug_tienda }}_carrito');
            if (guardado) {
                try {
                    carrito = JSON.parse(guardado);
                } catch (e) {
                    carrito = {};
                }
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

        function renderCarrito() {
            const items = Object.values(carrito);
            const total = totalCarrito();
            const cantidad = cantidadCarrito();

            cartCount.textContent = cantidad;
            cartCount.style.display = cantidad > 0 ? 'grid' : 'none';
            cartTotal.textContent = formatearPrecio(total);
            checkoutBtn.disabled = cantidad === 0;

            if (items.length === 0) {
                cartItems.innerHTML = '<div class="cart-empty">El carrito está vacío</div>';
                return;
            }

            cartItems.innerHTML = items.map(item => `
                <div class="cart-item">
                    ${item.imagen ? `<img src="${item.imagen}" alt="${item.nombre}">` : '<div style="width:48px;height:48px;border-radius:8px;background:var(--fondo);display:grid;place-items:center;font-size:20px">🛍️</div>'}
                    <div class="cart-item-info">
                        <p class="cart-item-name">${item.nombre}</p>
                        <p class="cart-item-price">${formatearPrecio(item.precio)} c/u</p>
                    </div>
                    <div class="qty-controls">
                        <button data-id="${item.id}" data-action="restar">−</button>
                        <span>${item.cantidad}</span>
                        <button data-id="${item.id}" data-action="sumar">+</button>
                    </div>
                </div>
            `).join('');
        }

        function agregarProducto(id, nombre, precio, imagen) {
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
            if (carrito[id].cantidad <= 0) {
                delete carrito[id];
            }
            guardarCarrito();
            renderCarrito();
        }

        function enviarPedido() {
            if (!TELEFONO) {
                alert('Esta tienda aún no tiene un teléfono configurado.');
                return;
            }
            const items = Object.values(carrito).map(i => `- ${i.cantidad}x ${i.nombre}: ${formatearPrecio(i.precio * i.cantidad)}`).join('\n');
            const mensaje = `Hola {{ $empresa->nombre }}, quiero hacer un pedido:\n\n${items}\n\n*Total:* ${formatearPrecio(totalCarrito())}`;
            const url = 'https://wa.me/' + TELEFONO.replace(/\D/g, '') + '?text=' + encodeURIComponent(mensaje);
            window.open(url, '_blank');
        }

        document.getElementById('products').addEventListener('click', function (e) {
            const btn = e.target.closest('.add-btn');
            if (!btn) return;
            const card = btn.closest('.product');
            agregarProducto(
                card.dataset.id,
                card.dataset.nombre,
                parseFloat(card.dataset.precio),
                card.dataset.imagen
            );
            abrirCarrito();
        });

        cartItems.addEventListener('click', function (e) {
            const btn = e.target.closest('[data-action]');
            if (!btn) return;
            cambiarCantidad(btn.dataset.id, btn.dataset.action === 'sumar' ? 1 : -1);
        });

        cartBtn.addEventListener('click', abrirCarrito);
        closeCart.addEventListener('click', cerrarCarrito);
        cartOverlay.addEventListener('click', cerrarCarrito);
        checkoutBtn.addEventListener('click', enviarPedido);

        cargarCarrito();
        renderCarrito();
    </script>
</body>
</html>
