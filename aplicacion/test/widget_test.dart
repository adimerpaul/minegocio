import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minegocio/views/login_view.dart';

void main() {
  testWidgets('muestra las acciones del login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginView()));

    // En pruebas IdiomaService no carga el JSON empaquetado, por lo que
    // el widget muestra las claves de traducción en lugar del texto final.
    expect(find.text('login.con_gmail'), findsOneWidget);
    expect(find.text('app.nombre'), findsOneWidget);
    // La tienda en línea se quitó del login por ahora.
    expect(find.text('Ver la tienda en línea'), findsNothing);
  });
}
