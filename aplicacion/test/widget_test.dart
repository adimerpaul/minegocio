import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minegocio/views/login_view.dart';

void main() {
  testWidgets('muestra las acciones del login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginView()));

    expect(find.text('Iniciar sesión con Gmail'), findsOneWidget);
    expect(find.text('Mi Negocio'), findsOneWidget);
    // La tienda en línea se quitó del login por ahora.
    expect(find.text('Ver la tienda en línea'), findsNothing);
  });
}
