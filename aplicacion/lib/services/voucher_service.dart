import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../config/formato.dart';
import '../models/compra.dart';
import '../models/empresa.dart';
import '../models/venta.dart';

/// Genera e imprime el voucher de una venta o de una compra (ticket de
/// 80 mm) con los datos de la empresa. Usa el diálogo de impresión del
/// sistema, que también permite guardarlo como PDF o compartirlo.
class VoucherService {
  VoucherService._();

  static final VoucherService instance = VoucherService._();

  /// Logos ya convertidos a PNG, por URL (la URL cambia si el logo cambia).
  final Map<String, Uint8List> _logoCache = {};

  /// Descarga el logo y lo convierte a PNG: el backend lo guarda como WebP
  /// y el paquete pdf solo acepta PNG/JPEG. Devuelve null si algo falla
  /// (el voucher simplemente sale sin logo).
  Future<Uint8List?> _logoPng(String url) async {
    final cacheado = _logoCache[url];
    if (cacheado != null) return cacheado;

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final codec = await ui.instantiateImageCodec(
        response.bodyBytes,
        targetWidth: 300,
      );
      final frame = await codec.getNextFrame();
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) return null;

      final bytes = png.buffer.asUint8List();
      _logoCache[url] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Voucher de una venta.
  Future<void> imprimir({
    required Empresa empresa,
    required Venta venta,
  }) {
    return _imprimirTicket(
      empresa: empresa,
      etiquetaCodigo: 'Recibo',
      codigo: venta.codigo,
      fecha: venta.fecha,
      etiquetaTercero: 'Cliente',
      tercero: venta.cliente ?? 'Venta en mostrador',
      anulada: venta.anulada,
      items: venta.items
          .map((i) => (i.nombre, i.precio, i.cantidad, i.subtotal))
          .toList(),
      total: venta.total,
      despedida: '¡Gracias por su compra!',
    );
  }

  /// Voucher de una compra (mismo ticket, con proveedor y costos).
  Future<void> imprimirCompra({
    required Empresa empresa,
    required Compra compra,
  }) {
    return _imprimirTicket(
      empresa: empresa,
      etiquetaCodigo: 'Compra',
      codigo: compra.codigo,
      fecha: compra.fecha,
      etiquetaTercero: 'Proveedor',
      tercero: compra.proveedor,
      anulada: compra.anulada,
      items: compra.items
          .map((i) => (i.nombre, i.costo, i.cantidad, i.subtotal))
          .toList(),
      total: compra.total,
      despedida: 'Comprobante interno de compra',
    );
  }

  /// Comparte el voucher de una venta por WhatsApp (u otra app del sistema).
  Future<void> compartir({
    required Empresa empresa,
    required Venta venta,
  }) {
    return _compartirTicket(
      empresa: empresa,
      etiquetaCodigo: 'Recibo',
      codigo: venta.codigo,
      fecha: venta.fecha,
      etiquetaTercero: 'Cliente',
      tercero: venta.cliente ?? 'Venta en mostrador',
      anulada: venta.anulada,
      items: venta.items
          .map((i) => (i.nombre, i.precio, i.cantidad, i.subtotal))
          .toList(),
      total: venta.total,
      despedida: '¡Gracias por su compra!',
    );
  }

  /// Comparte el voucher de una compra por WhatsApp (u otra app del sistema).
  Future<void> compartirCompra({
    required Empresa empresa,
    required Compra compra,
  }) {
    return _compartirTicket(
      empresa: empresa,
      etiquetaCodigo: 'Compra',
      codigo: compra.codigo,
      fecha: compra.fecha,
      etiquetaTercero: 'Proveedor',
      tercero: compra.proveedor,
      anulada: compra.anulada,
      items: compra.items
          .map((i) => (i.nombre, i.costo, i.cantidad, i.subtotal))
          .toList(),
      total: compra.total,
      despedida: 'Comprobante interno de compra',
    );
  }

  /// Arma e imprime el ticket. Cada ítem es
  /// (nombre, precio/costo unitario, cantidad, subtotal).
  Future<void> _imprimirTicket({
    required Empresa empresa,
    required String etiquetaCodigo,
    required String codigo,
    required DateTime fecha,
    required String etiquetaTercero,
    required String tercero,
    required bool anulada,
    required List<(String, double, int, double)> items,
    required double total,
    required String despedida,
  }) async {
    final bytes = await _generarTicket(
      empresa: empresa,
      etiquetaCodigo: etiquetaCodigo,
      codigo: codigo,
      fecha: fecha,
      etiquetaTercero: etiquetaTercero,
      tercero: tercero,
      anulada: anulada,
      items: items,
      total: total,
      despedida: despedida,
    );

    await Printing.layoutPdf(
      name: 'voucher-$codigo',
      onLayout: (_) => bytes,
    );
  }

  /// Genera el PDF, lo guarda temporalmente y abre el diálogo de compartir.
  Future<void> _compartirTicket({
    required Empresa empresa,
    required String etiquetaCodigo,
    required String codigo,
    required DateTime fecha,
    required String etiquetaTercero,
    required String tercero,
    required bool anulada,
    required List<(String, double, int, double)> items,
    required double total,
    required String despedida,
  }) async {
    final bytes = await _generarTicket(
      empresa: empresa,
      etiquetaCodigo: etiquetaCodigo,
      codigo: codigo,
      fecha: fecha,
      etiquetaTercero: etiquetaTercero,
      tercero: tercero,
      anulada: anulada,
      items: items,
      total: total,
      despedida: despedida,
    );

    final dir = await getTemporaryDirectory();
    final nombreArchivo = 'voucher-$codigo.pdf';
    final archivo = File(p.join(dir.path, nombreArchivo));
    await archivo.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(archivo.path, mimeType: 'application/pdf')],
      text: '$etiquetaCodigo $codigo - ${formatoMoneda(total, simbolo: simboloMoneda(empresa.moneda))}',
      subject: '$etiquetaCodigo $codigo',
    );
  }

  /// Arma el PDF del ticket y devuelve sus bytes.
  Future<Uint8List> _generarTicket({
    required Empresa empresa,
    required String etiquetaCodigo,
    required String codigo,
    required DateTime fecha,
    required String etiquetaTercero,
    required String tercero,
    required bool anulada,
    required List<(String, double, int, double)> items,
    required double total,
    required String despedida,
  }) async {
    final simbolo = simboloMoneda(empresa.moneda);
    final logo = empresa.logoUrl == null
        ? null
        : await _logoPng(empresa.logoUrl!);
    final doc = pw.Document();

    pw.Widget dato(String texto) => pw.Text(
      texto,
      style: const pw.TextStyle(fontSize: 8),
      textAlign: pw.TextAlign.center,
    );

    pw.Widget separador() => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        '-' * 42,
        style: const pw.TextStyle(fontSize: 8),
        maxLines: 1,
      ),
    );

    pw.Widget fila(String izquierda, String derecha, {bool negrita = false}) {
      final estilo = pw.TextStyle(
        fontSize: negrita ? 10 : 8,
        fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
      );

      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: pw.Text(izquierda, style: estilo)),
          pw.Text(derecha, style: estilo),
        ],
      );
    }

    final fechaHora =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            if (logo != null) ...[
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(logo),
                  width: 70,
                  height: 70,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 6),
            ],
            pw.Center(
              child: pw.Text(
                empresa.nombre,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 4),
            if (empresa.nit != null)
              pw.Center(child: dato('NIT: ${empresa.nit}')),
            if (empresa.direccion != null)
              pw.Center(child: dato(empresa.direccion!)),
            if (empresa.telefono != null)
              pw.Center(child: dato('Tel: ${empresa.telefono}')),
            if (empresa.correo != null) pw.Center(child: dato(empresa.correo!)),
            separador(),
            fila(etiquetaCodigo, codigo),
            fila('Fecha', fechaHora),
            fila(etiquetaTercero, tercero),
            if (anulada)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Center(
                  child: pw.Text(
                    '*** ANULADA ***',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            separador(),
            for (final (nombre, unitario, cantidad, subtotal) in items) ...[
              pw.Text(nombre, style: const pw.TextStyle(fontSize: 8)),
              fila(
                '  $cantidad x ${formatoMoneda(unitario, simbolo: simbolo)}',
                formatoMoneda(subtotal, simbolo: simbolo),
              ),
            ],
            separador(),
            fila(
              'TOTAL',
              formatoMoneda(total, simbolo: simbolo),
              negrita: true,
            ),
            pw.SizedBox(height: 10),
            pw.Center(child: dato(despedida)),
          ],
        ),
      ),
    );

    return doc.save();
  }
}
