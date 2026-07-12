import 'package:flutter_test/flutter_test.dart';
import 'package:minegocio/screens/login_screen.dart';

import 'package:flutter/material.dart';

void main() {
  testWidgets('la pantalla de login muestra el botón de Gmail', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('GestiónPro'), findsOneWidget);
    expect(find.text('Iniciar sesión con Gmail'), findsOneWidget);
  });
}
