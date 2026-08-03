import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_exception.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'loading_state.dart';

/// Constrói consistentemente os quatro estados obrigatórios de tela
/// (Loading / Erro / Vazio / Sucesso) a partir de um [AsyncValue].
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.isEmpty,
    this.emptyMessage = 'Nenhum registro encontrado.',
    this.emptyIcon = Icons.inbox_outlined,
    this.loadingMessage,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;
  final IconData emptyIcon;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (value) {
        if (isEmpty != null && isEmpty!(value)) {
          return EmptyState(message: emptyMessage, icon: emptyIcon);
        }
        return data(value);
      },
      error: (error, stackTrace) => ErrorState(
        message: error is AppException ? error.message : 'Ocorreu um erro inesperado.',
        onRetry: onRetry,
      ),
      loading: () => LoadingState(message: loadingMessage),
    );
  }
}
