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

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// Fecha corta como en el mockup: `17 jul`; `hoy` si es el día actual.
String formatoFecha(DateTime fecha) {
  final ahora = DateTime.now();
  if (fecha.year == ahora.year &&
      fecha.month == ahora.month &&
      fecha.day == ahora.day) {
    return 'hoy';
  }

  return '${fecha.day} ${_meses[fecha.month - 1]}';
}
