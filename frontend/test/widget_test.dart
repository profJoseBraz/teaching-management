// Teste de smoke: garante que o app raiz é construído sem erros,
// já autenticado como não logado (mostra a tela de login).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestao_docente/app.dart';
import 'package:gestao_docente/presentation/providers/session_providers.dart';

void main() {
  testWidgets('App builds and shows splash/login without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
        child: const GestaoDocenteApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
