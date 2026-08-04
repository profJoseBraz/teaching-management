import 'package:flutter/material.dart';

import 'markdown_text.dart';

/// Campo de descrição com barra de formatação Markdown.
///
/// Os botões envolvem a seleção (ou o ponto de inserção) com a sintaxe
/// correspondente — o usuário não precisa digitar `**` ou `-` manualmente.
/// Aba "Visualizar" mostra o resultado formatado antes de salvar.
class MarkdownDescriptionField extends StatefulWidget {
  const MarkdownDescriptionField({
    super.key,
    required this.controller,
    this.label = 'Descrição (opcional)',
    this.maxLength = 5000,
    this.minLines = 5,
    this.maxLines = 10,
  });

  final TextEditingController controller;
  final String label;
  final int maxLength;
  final int minLines;
  final int maxLines;

  @override
  State<MarkdownDescriptionField> createState() => _MarkdownDescriptionFieldState();
}

class _MarkdownDescriptionFieldState extends State<MarkdownDescriptionField> {
  final _focusNode = FocusNode();
  var _preview = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _wrap(String left, String right, {String placeholder = 'texto'}) {
    final controller = widget.controller;
    final value = controller.value;
    final text = value.text;
    final selection = value.selection;

    final start = selection.isValid ? selection.start.clamp(0, text.length) : text.length;
    final end = selection.isValid ? selection.end.clamp(0, text.length) : text.length;
    final selected = text.substring(start, end);
    final body = selected.isEmpty ? placeholder : selected;
    final replacement = '$left$body$right';

    final newText = text.replaceRange(start, end, replacement);
    final cursorStart = start + left.length;
    final cursorEnd = cursorStart + body.length;

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: cursorStart, extentOffset: cursorEnd),
    );
    _focusNode.requestFocus();
  }

  void _toggleLinePrefix(String prefix) {
    final controller = widget.controller;
    final value = controller.value;
    final text = value.text;
    final selection = value.selection;

    final start = selection.isValid ? selection.start.clamp(0, text.length) : text.length;
    final end = selection.isValid ? selection.end.clamp(0, text.length) : text.length;

    final lineStart = text.lastIndexOf('\n', start > 0 ? start - 1 : 0);
    final rangeStart = lineStart == -1 ? 0 : lineStart + 1;
    final rangeEnd = end;

    final block = text.substring(rangeStart, rangeEnd);
    final lines = block.isEmpty ? <String>[''] : block.split('\n');
    final allPrefixed = lines.every((line) => line.startsWith(prefix) || line.trim().isEmpty);
    final transformed = lines.map((line) {
      if (line.trim().isEmpty && lines.length > 1) return line;
      if (allPrefixed) {
        return line.startsWith(prefix) ? line.substring(prefix.length) : line;
      }
      return line.startsWith(prefix) ? line : '$prefix$line';
    }).join('\n');

    final newText = text.replaceRange(rangeStart, rangeEnd, transformed);
    final delta = transformed.length - block.length;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: rangeStart,
        extentOffset: (rangeEnd + delta).clamp(0, newText.length),
      ),
    );
    _focusNode.requestFocus();
  }

  void _insertNumberedList() {
    final controller = widget.controller;
    final value = controller.value;
    final text = value.text;
    final selection = value.selection;

    final start = selection.isValid ? selection.start.clamp(0, text.length) : text.length;
    final end = selection.isValid ? selection.end.clamp(0, text.length) : text.length;

    final lineStart = text.lastIndexOf('\n', start > 0 ? start - 1 : 0);
    final rangeStart = lineStart == -1 ? 0 : lineStart + 1;
    final rangeEnd = end;

    final block = text.substring(rangeStart, rangeEnd);
    final lines = block.isEmpty ? <String>[''] : block.split('\n');
    final numbered = RegExp(r'^\d+\.\s');
    final allNumbered = lines.every((line) => numbered.hasMatch(line) || line.trim().isEmpty);

    final transformed = allNumbered
        ? lines.map((line) => line.replaceFirst(numbered, '')).join('\n')
        : lines.asMap().entries.map((e) {
            final line = e.value;
            if (line.trim().isEmpty && lines.length > 1) return line;
            final without = line.replaceFirst(numbered, '');
            return '${e.key + 1}. $without';
          }).join('\n');

    final newText = text.replaceRange(rangeStart, rangeEnd, transformed);
    final delta = transformed.length - block.length;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: rangeStart,
        extentOffset: (rangeEnd + delta).clamp(0, newText.length),
      ),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Editar'), icon: Icon(Icons.edit_outlined, size: 16)),
                ButtonSegment(value: true, label: Text('Ver'), icon: Icon(Icons.visibility_outlined, size: 16)),
              ],
              selected: {_preview},
              onSelectionChanged: (value) => setState(() => _preview = value.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelSmall),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_preview) ...[
          Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  _ToolbarButton(
                    tooltip: 'Negrito',
                    icon: Icons.format_bold,
                    onPressed: () => _wrap('**', '**', placeholder: 'negrito'),
                  ),
                  _ToolbarButton(
                    tooltip: 'Itálico',
                    icon: Icons.format_italic,
                    onPressed: () => _wrap('*', '*', placeholder: 'itálico'),
                  ),
                  _ToolbarButton(
                    tooltip: 'Título',
                    icon: Icons.title,
                    onPressed: () => _toggleLinePrefix('## '),
                  ),
                  const VerticalDivider(width: 12, indent: 8, endIndent: 8),
                  _ToolbarButton(
                    tooltip: 'Lista com tópicos',
                    icon: Icons.format_list_bulleted,
                    onPressed: () => _toggleLinePrefix('- '),
                  ),
                  _ToolbarButton(
                    tooltip: 'Lista numerada',
                    icon: Icons.format_list_numbered,
                    onPressed: _insertNumberedList,
                  ),
                ],
              ),
            ),
          ),
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              alignLabelWithHint: true,
              hintText: 'Escreva a descrição e use os botões para formatar',
            ),
          ),
        ] else
          Container(
            constraints: const BoxConstraints(minHeight: 120),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.controller.text.trim().isEmpty
                ? Text(
                    'Nada para visualizar ainda.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  )
                : MarkdownText(widget.controller.text),
          ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
