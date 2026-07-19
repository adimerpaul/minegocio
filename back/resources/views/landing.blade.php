<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Mi Negocio — Tu negocio y tu tienda en línea, desde el celular</title>
<meta name="description" content="Registra ventas, controla tu inventario y recibe pedidos por WhatsApp con tu propio catálogo público. Todo en una sola app.">
<link rel="icon" href="{{ asset('landing/logo.png') }}" type="image/png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
  body { margin:0; }
  a { color:#F4632C; } a:hover { color:#9A3D12; }
  html { scroll-behavior:smooth; }
  @keyframes fadeUp { from { opacity:0; transform:translateY(10px); } to { opacity:1; transform:translateY(0); } }
</style>
</head>
<body>

<div style="font-family:'Instrument Sans',Helvetica,Arial,sans-serif;background:#FAF8F6;color:#221A15;min-height:100%">

  <!-- Nav -->
  <header style="position:sticky;top:0;z-index:30;background:rgba(250,248,246,0.92);backdrop-filter:blur(10px);border-bottom:1px solid #EEE7E1">
    <div style="max-width:1120px;margin:0 auto;padding:12px 20px;display:flex;align-items:center;justify-content:space-between;gap:14px">
      <div style="display:flex;align-items:center;gap:10px">
        <img src="{{ asset('landing/logo.png') }}" alt="Mi Negocio" style="height:42px;width:auto">
        <span style="font-weight:700;font-size:17px;letter-spacing:-0.01em">Mi Negocio</span>
      </div>
      <nav style="display:flex;align-items:center;gap:18px;flex-wrap:wrap">
        <a href="#funciones" style="text-decoration:none;color:#5D5148;font-size:14px;font-weight:600">Funciones</a>
        <a href="#tienda" style="text-decoration:none;color:#5D5148;font-size:14px;font-weight:600">Tienda en línea</a>
        <a href="#descargar" style="background:#F4632C;color:#fff;text-decoration:none;font-size:14px;font-weight:700;padding:9px 18px;border-radius:12px">Descargar app</a>
      </nav>
    </div>
  </header>

  <!-- Hero -->
  <section style="background:#221A15;color:#FAF8F6;overflow:hidden">
    <div style="max-width:1120px;margin:0 auto;padding:clamp(48px,7vw,90px) 20px;display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:40px;align-items:center">
      <div style="animation:fadeUp .5s ease both">
        <div style="display:inline-block;font-size:12px;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;color:#F4632C;background:rgba(244,99,44,0.14);padding:6px 14px;border-radius:999px;margin-bottom:18px">Gestión + tienda en línea</div>
        <h1 style="font-size:clamp(32px,4.5vw,52px);font-weight:700;line-height:1.08;letter-spacing:-0.02em;margin:0 0 16px">Tu negocio y tu tienda en línea, desde el celular.</h1>
        <p style="font-size:17px;line-height:1.6;color:#A5988D;margin:0 0 28px;max-width:460px">Registra ventas, controla tu inventario y recibe pedidos por WhatsApp con tu propio catálogo público. Todo en una sola app.</p>
        <div style="display:flex;gap:12px;flex-wrap:wrap">
          <a href="#descargar" style="background:#F4632C;color:#fff;text-decoration:none;font-weight:700;font-size:15px;padding:14px 26px;border-radius:14px">Descargar gratis</a>
          <a href="#tienda" style="background:transparent;color:#FAF8F6;border:1px solid rgba(250,248,246,0.3);text-decoration:none;font-weight:600;font-size:15px;padding:14px 26px;border-radius:14px">Ver la tienda en línea</a>
        </div>
      </div>
      <div style="display:flex;justify-content:center;animation:fadeUp .6s .1s ease both">
        <div style="width:min(300px,80vw);border-radius:32px;border:6px solid #3a2f27;overflow:hidden;box-shadow:0 30px 60px -20px rgba(0,0,0,0.6);transform:rotate(2deg)">
          <img src="{{ asset('landing/dashboard.jpeg') }}" alt="Dashboard de Mi Negocio" style="display:block;width:100%;height:auto">
        </div>
      </div>
    </div>
  </section>

  <!-- KPIs strip -->
  <section style="border-bottom:1px solid #EEE7E1;background:#fff">
    <div style="max-width:1120px;margin:0 auto;padding:22px 20px;display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:14px;text-align:center">
      <div><div style="font-weight:700;font-size:22px;color:#F4632C">POS</div><div style="font-size:13px;color:#8A7D73">Venta rápida con escáner</div></div>
      <div><div style="font-weight:700;font-size:22px;color:#F4632C">Stock</div><div style="font-size:13px;color:#8A7D73">Alertas de stock crítico</div></div>
      <div><div style="font-weight:700;font-size:22px;color:#F4632C">Pedidos</div><div style="font-size:13px;color:#8A7D73">Catálogo público en línea</div></div>
      <div><div style="font-weight:700;font-size:22px;color:#F4632C">Reportes</div><div style="font-size:13px;color:#8A7D73">Ventas del día y la semana</div></div>
    </div>
  </section>

  <!-- Features with screenshots -->
  <section id="funciones" style="max-width:1120px;margin:0 auto;padding:clamp(50px,7vw,80px) 20px">
    <div style="text-align:center;margin-bottom:44px">
      <h2 style="font-size:clamp(26px,3.5vw,38px);font-weight:700;letter-spacing:-0.02em;margin:0 0 10px">Todo lo que tu negocio necesita</h2>
      <p style="color:#8A7D73;font-size:15px;margin:0">Diseñado para tiendas, restaurantes y emprendedores.</p>
    </div>
    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:20px">
      <div style="background:#fff;border:1px solid #EEE7E1;border-radius:20px;padding:18px;display:flex;flex-direction:column;gap:14px">
        <div style="border-radius:14px;overflow:hidden;border:1px solid #EEE7E1;background:#FAF8F6">
          <img src="{{ asset('landing/dashboard.jpeg') }}" alt="Dashboard en tiempo real" loading="lazy" style="display:block;width:100%;height:auto">
        </div>
        <div>
          <div style="font-weight:700;font-size:16px;margin-bottom:5px">Dashboard en tiempo real</div>
          <div style="font-size:13.5px;color:#5D5148;line-height:1.55">Ventas de hoy, pedidos en línea, stock crítico y gráfico semanal de un vistazo.</div>
        </div>
      </div>
      <div style="background:#fff;border:1px solid #EEE7E1;border-radius:20px;padding:18px;display:flex;flex-direction:column;gap:14px">
        <div style="border-radius:14px;overflow:hidden;border:1px solid #EEE7E1;background:#FAF8F6">
          <img src="{{ asset('landing/venta-rapida.jpeg') }}" alt="Venta rápida (POS)" loading="lazy" style="display:block;width:100%;height:auto">
        </div>
        <div>
          <div style="font-weight:700;font-size:16px;margin-bottom:5px">Venta rápida (POS)</div>
          <div style="font-size:13.5px;color:#5D5148;line-height:1.55">Busca por nombre o escanea el código de barras y cobra en segundos.</div>
        </div>
      </div>
      <div style="background:#fff;border:1px solid #EEE7E1;border-radius:20px;padding:18px;display:flex;flex-direction:column;gap:14px">
        <div style="border-radius:14px;overflow:hidden;border:1px solid #EEE7E1;background:#FAF8F6">
          <img src="{{ asset('landing/productos.jpeg') }}" alt="Gestión de productos" loading="lazy" style="display:block;width:100%;height:auto">
        </div>
        <div>
          <div style="font-weight:700;font-size:16px;margin-bottom:5px">Gestión de productos</div>
          <div style="font-size:13.5px;color:#5D5148;line-height:1.55">Precios, stock, stock mínimo, categorías y códigos de barras.</div>
        </div>
      </div>
      <div style="background:#fff;border:1px solid #EEE7E1;border-radius:20px;padding:18px;display:flex;flex-direction:column;gap:14px">
        <div style="border-radius:14px;overflow:hidden;border:1px solid #EEE7E1;background:#FAF8F6">
          <img src="{{ asset('landing/menu.jpeg') }}" alt="Todo tu negocio en un menú" loading="lazy" style="display:block;width:100%;height:auto">
        </div>
        <div>
          <div style="font-weight:700;font-size:16px;margin-bottom:5px">Todo tu negocio en un menú</div>
          <div style="font-size:13.5px;color:#5D5148;line-height:1.55">Clientes, proveedores, compras, categorías y configuración de empresa.</div>
        </div>
      </div>
    </div>
  </section>

  <!-- Tienda en línea highlight -->
  <section id="tienda" style="background:#FFF3EC;border-top:1px solid #EEE7E1;border-bottom:1px solid #EEE7E1">
    <div style="max-width:1120px;margin:0 auto;padding:clamp(50px,7vw,80px) 20px;display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:40px;align-items:center">
      <div>
        <div style="display:inline-block;font-size:12px;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;color:#0E7490;background:rgba(14,116,144,0.1);padding:6px 14px;border-radius:999px;margin-bottom:16px">Tienda en línea incluida</div>
        <h2 style="font-size:clamp(26px,3.5vw,38px);font-weight:700;letter-spacing:-0.02em;margin:0 0 14px;line-height:1.15">Tus clientes piden por WhatsApp, tú solo cobras</h2>
        <p style="color:#5D5148;font-size:15.5px;line-height:1.65;margin:0 0 24px">Activa tu catálogo público con un clic: tus productos, precios y stock se publican automáticamente. Los pedidos llegan directo a la app y a tu WhatsApp.</p>
        <ul style="list-style:none;padding:0;margin:0 0 26px;display:flex;flex-direction:column;gap:10px">
          <li style="display:flex;gap:10px;align-items:center;font-size:14.5px;font-weight:600"><span style="color:#F4632C">✓</span> Catálogo con tu logo y tus categorías</li>
          <li style="display:flex;gap:10px;align-items:center;font-size:14.5px;font-weight:600"><span style="color:#F4632C">✓</span> Carrito y pedido por WhatsApp</li>
          <li style="display:flex;gap:10px;align-items:center;font-size:14.5px;font-weight:600"><span style="color:#F4632C">✓</span> Compartir tienda y productos en redes</li>
        </ul>
        @if ($tiendaEjemplo)
          <a href="{{ route('tienda.show', $tiendaEjemplo->slug_tienda) }}" target="_blank" style="background:#0E7490;color:#fff;text-decoration:none;font-weight:700;font-size:15px;padding:13px 24px;border-radius:14px;display:inline-block">Ver tienda de ejemplo</a>
        @endif
      </div>
      <div style="display:flex;justify-content:center;gap:16px;flex-wrap:wrap">
        <div style="width:min(240px,70vw);border-radius:26px;border:5px solid #221A15;overflow:hidden;box-shadow:0 24px 50px -18px rgba(34,26,21,0.4);transform:rotate(-3deg)">
          <img src="{{ asset('landing/venta-rapida.jpeg') }}" alt="Venta rápida" loading="lazy" style="display:block;width:100%;height:auto">
        </div>
        <div style="width:min(240px,70vw);border-radius:26px;border:5px solid #221A15;overflow:hidden;box-shadow:0 24px 50px -18px rgba(34,26,21,0.4);transform:rotate(3deg);margin-top:30px">
          <img src="{{ asset('landing/pedidos.jpeg') }}" alt="Pedidos en línea" loading="lazy" style="display:block;width:100%;height:auto">
        </div>
      </div>
    </div>
  </section>

  <!-- CTA -->
  <section id="descargar" style="max-width:1120px;margin:0 auto;padding:clamp(50px,7vw,80px) 20px">
    <div style="background:#221A15;border-radius:28px;padding:clamp(36px,5vw,60px);text-align:center;color:#FAF8F6">
      <img src="{{ asset('landing/logo.png') }}" alt="Mi Negocio" style="height:70px;width:auto;margin-bottom:18px;border-radius:14px;background:#fff;padding:6px">
      <h2 style="font-size:clamp(24px,3.5vw,36px);font-weight:700;letter-spacing:-0.02em;margin:0 0 10px">Empieza a vender hoy</h2>
      <p style="color:#A5988D;font-size:15px;margin:0 0 26px">Gratis, en español y pensado para Bolivia y Latinoamérica.</p>
      <div style="display:flex;gap:12px;justify-content:center;flex-wrap:wrap">
        <a href="#" style="background:#F4632C;color:#fff;text-decoration:none;font-weight:700;font-size:15px;padding:14px 28px;border-radius:14px">Descargar para Android</a>
        <button onclick="sharePage()" style="background:transparent;color:#FAF8F6;border:1px solid rgba(250,248,246,0.3);font-family:inherit;font-weight:600;font-size:15px;padding:14px 24px;border-radius:14px;cursor:pointer;display:flex;align-items:center;gap:8px">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.6" y1="10.5" x2="15.4" y2="6.5"/><line x1="8.6" y1="13.5" x2="15.4" y2="17.5"/></svg>
          Compartir
        </button>
      </div>
    </div>
  </section>

  <footer style="border-top:1px solid #EEE7E1;padding:26px 20px;text-align:center;color:#8A7D73;font-size:13px">
    Mi Negocio · Tu negocio y tu tienda en línea, desde el celular.
  </footer>
</div>

<script>
  function sharePage() {
    const url = window.location.href;
    const text = 'Mi Negocio: tu negocio y tu tienda en línea, desde el celular';
    if (navigator.share) navigator.share({ title: 'Mi Negocio', text, url }).catch(() => {});
    else window.open('https://wa.me/?text=' + encodeURIComponent(text + ' ' + url), '_blank');
  }
</script>
</body>
</html>
