import 'package:flutter_test/flutter_test.dart';

import 'package:minegocio/main.dart';

void main() {
  testWidgets('muestra el botón de login con Google', (tester) async {
    await tester.pumpWidget(const MiNegocioApp());

    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}
