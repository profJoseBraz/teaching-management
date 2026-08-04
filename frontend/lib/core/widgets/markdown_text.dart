import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Renderiza Markdown de forma compacta (sem scroll próprio).
///
/// Usado para visualizar descrições já salvas. Texto sem marcação
/// continua legível como texto simples.
class MarkdownText extends StatelessWidget {
  const MarkdownText(
    this.data, {
    super.key,
    this.selectable = true,
  });

  final String data;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium;

    return MarkdownBody(
      data: data,
      selectable: selectable,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: baseStyle,
        pPadding: EdgeInsets.zero,
        listBullet: baseStyle,
        strong: baseStyle?.copyWith(fontWeight: FontWeight.bold),
        em: baseStyle?.copyWith(fontStyle: FontStyle.italic),
        h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        blockSpacing: 8,
      ),
    );
  }
}
