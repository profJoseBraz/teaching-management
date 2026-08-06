import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../domain/entities/agenda_note.dart';
import '../../providers/agenda_providers.dart';

/// Agenda: cada linha é uma anotação distinta; várias podem compartilhar a mesma data.
class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(agendaNotesProvider);
    final dateFilter = ref.watch(agendaDateFilterProvider);
    final completionFilter = ref.watch(agendaCompletionFilterProvider);
    final dateLabel = dateFilter == null
        ? null
        : DateFormat.yMMMMd('pt_BR').format(dateFilter);
    final hasFilters = dateFilter != null ||
        _searchController.text.isNotEmpty ||
        completionFilter != AgendaCompletionFilter.all;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, initialDate: DateTime.now()),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Nova anotação'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar no texto das anotações…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(agendaSearchQueryProvider.notifier).state = '';
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    ref.read(agendaSearchQueryProvider.notifier).state = value;
                    setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                SegmentedButton<AgendaCompletionFilter>(
                  segments: const [
                    ButtonSegment(
                      value: AgendaCompletionFilter.pending,
                      label: Text('Pendentes'),
                      icon: Icon(Icons.radio_button_unchecked, size: 18),
                    ),
                    ButtonSegment(
                      value: AgendaCompletionFilter.completed,
                      label: Text('Concluídas'),
                      icon: Icon(Icons.check_circle_outline, size: 18),
                    ),
                    ButtonSegment(
                      value: AgendaCompletionFilter.all,
                      label: Text('Todas'),
                      icon: Icon(Icons.list_alt_rounded, size: 18),
                    ),
                  ],
                  selected: {completionFilter},
                  onSelectionChanged: (selected) {
                    ref.read(agendaCompletionFilterProvider.notifier).state = selected.first;
                  },
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickFilterDate(context),
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          dateLabel == null ? 'Filtrar por data' : dateLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (dateFilter != null) ...[
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Limpar data',
                        onPressed: () => ref.read(agendaDateFilterProvider.notifier).state = null,
                        icon: const Icon(Icons.filter_alt_off_outlined),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(agendaNotesProvider),
              child: AsyncValueWidget<List<AgendaNote>>(
                value: notesAsync,
                onRetry: () => ref.invalidate(agendaNotesProvider),
                isEmpty: (list) => list.isEmpty,
                emptyIcon: Icons.menu_book_outlined,
                emptyMessage: hasFilters
                    ? 'Nenhuma anotação com estes filtros.'
                    : 'Nenhuma anotação ainda.\nToque em Nova anotação para começar.',
                data: (notes) => ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final showDayHeader = index == 0 || !_isSameDay(notes[index - 1].date, note.date);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDayHeader) ...[
                          if (index > 0) const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 4),
                            child: Text(
                              _dayHeaderLabel(note.date),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                        ],
                        _AgendaNoteCard(
                          note: note,
                          onTap: () => _openEditor(context, existing: note),
                          onToggleCompleted: () => _toggleCompleted(context, note),
                          onDelete: () => _confirmDelete(context, note),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dayHeaderLabel(DateTime date) {
    final today = DateTime.now();
    if (_isSameDay(date, today)) return 'Hoje — ${DateFormat.yMMMMd('pt_BR').format(date)}';
    if (_isSameDay(date, today.subtract(const Duration(days: 1)))) {
      return 'Ontem — ${DateFormat.yMMMMd('pt_BR').format(date)}';
    }
    return DateFormat.yMMMMEEEEd('pt_BR').format(date);
  }

  Future<void> _toggleCompleted(BuildContext context, AgendaNote note) async {
    try {
      await ref.read(agendaActionsProvider).setCompleted(note.id, !note.completed);
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pickFilterDate(BuildContext context) async {
    final current = ref.read(agendaDateFilterProvider) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      helpText: 'Filtrar anotações por data',
    );
    if (picked == null) return;
    ref.read(agendaDateFilterProvider.notifier).state =
        DateTime(picked.year, picked.month, picked.day);
  }

  Future<void> _openEditor(
    BuildContext context, {
    AgendaNote? existing,
    DateTime? initialDate,
  }) async {
    final startDate = initialDate ?? existing?.date ?? DateTime.now();

    final result = await showDialog<({DateTime date, String content, bool completed})>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _AgendaEditorDialog(
        existing: existing,
        initialDate: startDate,
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      if (existing != null) {
        await ref.read(agendaActionsProvider).update(
              existing.id,
              date: result.date,
              content: result.content,
              completed: result.completed,
            );
      } else {
        await ref.read(agendaActionsProvider).create(
              date: result.date,
              content: result.content,
              completed: result.completed,
            );
      }
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDelete(BuildContext context, AgendaNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir anotação'),
        content: const Text('Remover esta anotação?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(agendaActionsProvider).delete(note.id);
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _AgendaNoteCard extends StatelessWidget {
  const _AgendaNoteCard({
    required this.note,
    required this.onTap,
    required this.onToggleCompleted,
    required this.onDelete,
  });

  final AgendaNote note;
  final VoidCallback onTap;
  final VoidCallback onToggleCompleted;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = note.content.trim();
    final previewLines = preview.split('\n').where((l) => l.trim().isNotEmpty).take(4).join('\n');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: note.completed,
                onChanged: (_) => onToggleCompleted(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text(note.completed ? 'Concluída' : 'Não concluída'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelStyle: theme.textTheme.labelSmall,
                        backgroundColor: note.completed
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      previewLines.isEmpty ? '(sem texto)' : previewLines,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                        decoration: note.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaEditorDialog extends StatefulWidget {
  const _AgendaEditorDialog({
    required this.initialDate,
    this.existing,
  });

  final DateTime initialDate;
  final AgendaNote? existing;

  @override
  State<_AgendaEditorDialog> createState() => _AgendaEditorDialogState();
}

class _AgendaEditorDialogState extends State<_AgendaEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contentController;
  late DateTime _date;
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _date = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);
    _contentController = TextEditingController(text: widget.existing?.content ?? '');
    _completed = widget.existing?.completed ?? false;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _yesterday => _today.subtract(const Duration(days: 1));

  DateTime get _twoDaysAgo => _today.subtract(const Duration(days: 2));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      helpText: 'Data da anotação',
    );
    if (picked == null) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  void _setDate(DateTime date) {
    setState(() => _date = DateTime(date.year, date.month, date.day));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      date: _date,
      content: _contentController.text.trim(),
      completed: _completed,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final media = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final maxHeight = media.height * 0.7;

    return AlertDialog(
      title: Text(isEdit ? 'Editar anotação' : 'Nova anotação'),
      content: SizedBox(
        width: media.width > 560 ? 480 : media.width * 0.9,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Data da anotação',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Por padrão é hoje. Altere se a anotação for de outro dia.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event_rounded),
                    label: Text(DateFormat.yMMMMEEEEd('pt_BR').format(_date)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        label: const Text('Hoje'),
                        selected: _isSameDay(_date, _today),
                        onSelected: (_) => _setDate(_today),
                      ),
                      ChoiceChip(
                        label: const Text('Ontem'),
                        selected: _isSameDay(_date, _yesterday),
                        onSelected: (_) => _setDate(_yesterday),
                      ),
                      ChoiceChip(
                        label: const Text('Anteontem'),
                        selected: _isSameDay(_date, _twoDaysAgo),
                        onSelected: (_) => _setDate(_twoDaysAgo),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Concluída'),
                    subtitle: Text(
                      _completed ? 'Marcada como concluída' : 'Ainda pendente (padrão)',
                    ),
                    value: _completed,
                    onChanged: (value) => setState(() => _completed = value),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _contentController,
                    autofocus: true,
                    minLines: 4,
                    maxLines: 10,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Anotações',
                      alignLabelWithHint: true,
                      hintText: 'Escreva a anotação…',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Escreva ao menos uma anotação' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
