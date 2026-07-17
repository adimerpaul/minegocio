/// Formatea un monto como en el mockup: `Bs 1.234,50`.
String formatoMoneda(double monto, {String simbolo = 'Bs'}) {
  final partes = monto.toStringAsFixed(2).split('.');
  final entero = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );

  return '$simbolo $entero,${partes[1]}';
}

/// Símbolo de la moneda de la empresa.
String simboloMoneda(String? moneda) => switch (moneda) {
      'USD' => '\$us',
      'PEN' => 'S/.',
      _ => 'Bs',
    };
