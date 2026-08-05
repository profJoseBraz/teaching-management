import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/markdown_description_field.dart';
import '../../../domain/entities/activity.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/school_class.dart';
import '../../providers/activities_providers.dart';
import '../../providers/lessons_providers.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

/// Aba "Atividades" do hub da turma.
///
/// [disciplines] são as disciplinas vinculadas à turma (para o seletor
/// opcional do formulário de criação) e [disciplineFilter] restringe a
/// listagem à disciplina selecionada no topo do detalhe da turma (`null` =
/// todas).
class ActivitiesTab extends ConsumerStatefulWidget {
  const ActivitiesTab({
    super.key,
    required this.classId,
    required this.disciplines,
    this.disciplineFilter,
  });

  final String classId;
  final List<ClassDisciplineRef> disciplines;
  final String? disciplineFilter;

  @override
  ConsumerState<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends ConsumerState<ActivitiesTab> {
  String? _tagFilter;

  ActivitiesQuery get _query => (
        classId: widget.classId,
        disciplineId: widget.disciplineFilter,
        tag: null,
      );

  List<String> _tagsFrom(List<Activity> activities) {
    final tags = activities.map((a) => a.tag).whereType<String>().toSet().toList();
    tags.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final query = _query;
    final activitiesAsync = ref.watch(activitiesListProvider(query));
    final disciplineNames = {for (final d in widget.disciplines) d.id: d.name};

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'class_activities_new',
        onPressed: () => _openCreateDialog(
          activitiesAsync.valueOrNull ?? const <Activity>[],
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova atividade'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activitiesListProvider(query)),
        child: AsyncValueWidget<List<Activity>>(
          value: activitiesAsync,
          onRetry: () => ref.invalidate(activitiesListProvider(query)),
          isEmpty: (list) => list.isEmpty,
          emptyIcon: Icons.assignment_outlined,
          emptyMessage: 'Nenhuma atividade cadastrada ainda.',
          data: (activities) {
            final availableTags = _tagsFrom(activities);
            final filtered = _tagFilter == null
                ? activities
                : activities
                    .where(
                      (a) =>
                          a.tag != null &&
                          a.tag!.toLowerCase() == _tagFilter!.toLowerCase(),
                    )
                    .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (availableTags.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('Todas as tags'),
                            selected: _tagFilter == null,
                            onSelected: (_) => setState(() => _tagFilter = null),
                          ),
                        ),
                        ...availableTags.map(
                          (tag) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: const Icon(Icons.label_outline, size: 16),
                              label: Text(tag),
                              selected: _tagFilter?.toLowerCase() == tag.toLowerCase(),
                              onSelected: (selected) => setState(
                                () => _tagFilter = selected ? tag : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('Nenhuma atividade com esta tag.')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final activity = filtered[index];
                            final tagPart =
                                activity.tag != null && activity.tag!.isNotEmpty
                                    ? '${activity.tag} · '
                                    : '';
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  activity.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '$tagPart'
                                  '${activity.disciplineNamesLabel(disciplineNames)} · ${activity.categoryLabel} · '
                                  'Entrega em ${_dateFormat.format(activity.dueDate)} · '
                                  'Vale ${activity.maxScore.toStringAsFixed(0)} pts',
                                ),
                                trailing: activity.isOverdue
                                    ? const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309))
                                    : const Icon(Icons.chevron_right_rounded),
                                onTap: () => context.go(
                                  AppRoutes.activityDetail(widget.classId, activity.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCreateDialog(List<Activity> existing) async {
    if (widget.disciplines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vincule ao menos uma disciplina a esta turma antes de criar atividades.'),
        ),
      );
      return;
    }

    final lessons =
        ref.read(lessonsListProvider((classId: widget.classId, disciplineId: null))).valueOrNull ??
            const <Lesson>[];

    final draft = await showDialog<_CreateActivityDraft>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _CreateActivityDialog(
        disciplines: widget.disciplines,
        lessons: lessons,
        tagSuggestions: _tagsFrom(existing),
      ),
    );
    if (draft == null || !mounted) return;

    try {
      await ref.read(activitiesActionsProvider).create(
            widget.classId,
            originLessonId: draft.originLessonId,
            disciplineIds: draft.disciplineIds,
            title: draft.title,
            description: draft.description,
            tag: draft.tag,
            category: draft.category,
            mode: draft.mode,
            gradeMode: draft.gradeMode,
            maxScore: draft.maxScore,
            dueDate: draft.dueDate,
          );
    } catch (e) {
      if (!mounted) return;
      final detail = e is AppException ? e.displayMessage : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar atividade: $detail')));
    }
  }
}

typedef _CreateActivityDraft = ({
  String? originLessonId,
  List<String> disciplineIds,
  String title,
  String? description,
  String? tag,
  String category,
  String mode,
  String gradeMode,
  double maxScore,
  DateTime dueDate,
});

/// Diálogo Stateful — controllers só são descartados no `dispose` do State.
class _CreateActivityDialog extends StatefulWidget {
  const _CreateActivityDialog({
    required this.disciplines,
    required this.lessons,
    required this.tagSuggestions,
  });

  final List<ClassDisciplineRef> disciplines;
  final List<Lesson> lessons;
  final List<String> tagSuggestions;

  @override
  State<_CreateActivityDialog> createState() => _CreateActivityDialogState();
}

class _CreateActivityDialogState extends State<_CreateActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagController;
  late final TextEditingController _maxScoreController;

  String? _originLessonId;
  late final Set<String> _selectedDisciplineIds;
  String _category = 'ASSIGNMENT';
  String _mode = 'INDIVIDUAL';
  String _gradeMode = 'INDIVIDUAL';
  late DateTime _dueDate;
  var _showDisciplineError = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _tagController = TextEditingController();
    _maxScoreController = TextEditingController(text: '100');
    _selectedDisciplineIds = {
      if (widget.disciplines.length == 1) widget.disciplines.first.id,
    };
    _dueDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  void _submit() {
    final needsExplicitDiscipline = _originLessonId == null;
    if (needsExplicitDiscipline && _selectedDisciplineIds.isEmpty) {
      setState(() => _showDisciplineError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    final tag = _tagController.text.trim();
    Navigator.of(context).pop<_CreateActivityDraft>((
      originLessonId: _originLessonId,
      disciplineIds: _selectedDisciplineIds.toList(),
      title: _titleController.text.trim(),
      description: description.isEmpty ? null : description,
      tag: tag.isEmpty ? null : tag,
      category: _category,
      mode: _mode,
      gradeMode: _gradeMode,
      maxScore: double.parse(_maxScoreController.text),
      dueDate: _dueDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final needsExplicitDiscipline = _originLessonId == null;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Nova atividade'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um título' : null,
              ),
              const SizedBox(height: 12),
              MarkdownDescriptionField(controller: _descriptionController),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(
                  labelText: 'Tag (opcional)',
                  hintText: 'Ex.: Prova 1, Recuperação',
                  helperText: 'Use a mesma tag em várias atividades para agrupá-las',
                ),
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
              ),
              if (widget.tagSuggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.tagSuggestions
                      .map(
                        (tag) => ActionChip(
                          avatar: const Icon(Icons.label_outline, size: 16),
                          label: Text(tag),
                          onPressed: () => setState(() => _tagController.text = tag),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
              DropdownButtonFormField<String?>(
                key: ValueKey('origin-lesson-$_originLessonId'),
                initialValue: _originLessonId,
                decoration: const InputDecoration(labelText: 'Aula de origem (opcional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sem aula de origem')),
                  ...widget.lessons.map(
                    (l) => DropdownMenuItem(
                      value: l.id,
                      child: Text('${_dateFormat.format(l.date)} · ${l.startTime}'),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _originLessonId = v;
                  _showDisciplineError = false;
                  if (v == null && widget.disciplines.length == 1) {
                    _selectedDisciplineIds
                      ..clear()
                      ..add(widget.disciplines.first.id);
                  }
                }),
              ),
              const SizedBox(height: 12),
              Text(
                needsExplicitDiscipline
                    ? 'Disciplinas'
                    : 'Disciplinas (opcional — a da aula é incluída automaticamente)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Selecione uma ou mais — a mesma atividade pode servir a várias disciplinas.',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (widget.disciplines.isEmpty)
                Text(
                  'Esta turma ainda não tem disciplinas vinculadas.',
                  style: TextStyle(color: colorScheme.error, fontSize: 13),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.disciplines.map((d) {
                    final selected = _selectedDisciplineIds.contains(d.id);
                    return FilterChip(
                      label: Text(d.name),
                      selected: selected,
                      onSelected: (checked) => setState(() {
                        if (checked) {
                          _selectedDisciplineIds.add(d.id);
                        } else {
                          _selectedDisciplineIds.remove(d.id);
                        }
                        _showDisciplineError = false;
                      }),
                    );
                  }).toList(),
                ),
              if (_showDisciplineError) ...[
                const SizedBox(height: 6),
                Text(
                  'Selecione ao menos uma disciplina (obrigatória sem aula de origem).',
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: Activity.categoryLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _mode,
                      decoration: const InputDecoration(labelText: 'Modo'),
                      items: const [
                        DropdownMenuItem(value: 'INDIVIDUAL', child: Text('Individual')),
                        DropdownMenuItem(value: 'GROUP', child: Text('Grupo')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _mode = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gradeMode,
                      decoration: const InputDecoration(labelText: 'Correção'),
                      items: const [
                        DropdownMenuItem(value: 'INDIVIDUAL', child: Text('Individual')),
                        DropdownMenuItem(value: 'SHARED', child: Text('Compartilhada')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _gradeMode = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxScoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nota máxima'),
                validator: (v) => (double.tryParse(v ?? '') == null) ? 'Informe um número' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Entrega: ${_dateFormat.format(_dueDate)}'),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
