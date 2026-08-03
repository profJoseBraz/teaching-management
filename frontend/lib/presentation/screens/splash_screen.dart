import 'package:flutter/material.dart';

import '../../core/widgets/loading_state.dart';

/// Tela exibida enquanto o app verifica se há uma sessão válida.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingState(message: 'Carregando…'));
  }
}
