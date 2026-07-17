import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../config/formato.dart';
import '../models/empresa.dart';
import '../models/venta.dart';

/// Genera e imprime el voucher de una venta (ticket de 80 mm) con los
/// datos de la empresa. Usa el diálogo de impresión del sistema, que
/// también permite guardarlo como PDF o compartirlo.
class VoucherService {
  VoucherService._();

  static final VoucherService instance = VoucherService._();

  Future<void> imprimir({
    required Empresa empresa,
    required Venta venta,
  }) async {
    final simbolo = simboloMoneda(empresa.moneda);
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

    final fecha = venta.fecha;
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
            if (empresa.correo != null)
              pw.Center(child: dato(empresa.correo!)),
            separador(),
            fila('Recibo', venta.codigo),
            fila('Fecha', fechaHora),
            fila('Cliente', venta.cliente ?? 'Venta en mostrador'),
            if (venta.anulada)
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
            for (final item in venta.items) ...[
              pw.Text(item.nombre, style: const pw.TextStyle(fontSize: 8)),
              fila(
                '  ${item.cantidad} x ${formatoMoneda(item.precio, simbolo: simbolo)}',
                formatoMoneda(item.subtotal, simbolo: simbolo),
              ),
            ],
            separador(),
            fila(
              'TOTAL',
              formatoMoneda(venta.total, simbolo: simbolo),
              negrita: true,
            ),
            pw.SizedBox(height: 10),
            pw.Center(child: dato('¡Gracias por su compra!')),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      name: 'voucher-${venta.codigo}',
      onLayout: (_) => doc.save(),
    );
  }
}
