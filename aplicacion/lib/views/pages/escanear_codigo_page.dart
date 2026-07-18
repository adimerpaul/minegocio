import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../config/paleta.dart';

/// Escáner de códigos QR y de barras con la cámara. Al detectar el primer
/// código hace pop devolviendo su valor (String).
class EscanearCodigoPage extends StatefulWidget {
  const EscanearCodigoPage({super.key});

  @override
  State<EscanearCodigoPage> createState() => _EscanearCodigoPageState();
}

class _EscanearCodigoPageState extends State<EscanearCodigoPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _detectado = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture captura) {
    if (_detectado) return;

    for (final barcode in captura.barcodes) {
      final valor = barcode.rawValue;
      if (valor != null && valor.isNotEmpty) {
        _detectado = true;
        Navigator.of(context).pop(valor);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Escanear código',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Paleta.primario,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on, color: Colors.white),
            tooltip: 'Linterna',
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Sin permiso de cámara. Actívalo en los ajustes '
                            'del teléfono para escanear códigos.'
                      : 'No se pudo abrir la cámara.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ),
          // Marco guía para apuntar al código.
          IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Paleta.primario, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Text(
              'Apunta la cámara al código QR o de barras',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
