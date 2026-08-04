import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/markdown_description_field.dart';
import '../../../core/widgets/markdown_text.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/activity.dart';
import '../../../domain/entities/activity_detail.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/activities_providers.dart';
import '../../providers/classes_providers.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

enum _SubmissionFilter {
  all,
  pending,
  submitted,
  graded;

  String get label => switch (this) {
        all => 'Todas',
        pending => 'Pendente',
        submitted => 'Entregue',
        graded => 'Avaliada',
      };

  bool matches(String status) => switch (this) {
        all => true,
        pending => status == 'PENDING',
        submitted => status == 'SUBMITTED',
        graded => status == 'GRADED',
      };
}

/// Detalhe de uma atividade — resumo + lista de entregas com avaliação.
class ActivityDetailScreen extends ConsumerStatefulWidget {
  const ActivityDetailScreen({super.key, required this.classId, required this.activityId});

  final String classId;
  final String activityId;

  @override
  ConsumerState<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  _SubmissionFilter _filter = _SubmissionFilter.all;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(activityDetailProvider(widget.activityId));
    final enrollmentsAsync = ref.watch(enrollmentsProvider(widget.classId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividade'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar atividade',
            onPressed: () {
              final detail = detailAsync.valueOrNull;
              if (detail == null) return;
              _openEditActivityDialog(detail.activity);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir atividade',
            onPressed: () {
              final detail = detailAsync.valueOrNull;
              if (detail == null) return;
              _confirmDeleteActivity(detail.activity);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activityDetailProvider(widget.activityId)),
        child: AsyncValueWidget<ActivityDetail>(
          value: detailAsync,
          onRetry: () => ref.invalidate(activityDetailProvider(widget.activityId)),
          data: (detail) {
            final names = {
              for (final e in enrollmentsAsync.valueOrNull ?? const <Enrollment>[])
                e.studentId: e.student?.name ?? 'Aluno',
            };
            final activity = detail.activity;
            final filtered = detail.submissions.where((s) => _filter.matches(s.status)).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (activity.description?.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          MarkdownText(activity.description!),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (activity.tag != null && activity.tag!.isNotEmpty)
                              Chip(
                                avatar: const Icon(Icons.label_outline, size: 16),
                                label: Text(activity.tag!),
                              ),
                            Chip(label: Text(activity.categoryLabel)),
                            Chip(label: Text(activity.isGroup ? 'Em grupo' : 'Individual')),
                            Chip(label: Text(activity.isSharedGrade ? 'Nota compartilhada' : 'Nota individual')),
                            Chip(label: Text('Vale ${activity.maxScore.toStringAsFixed(0)} pts')),
                            Chip(
                              label: Text('Entrega ${_dateFormat.format(activity.dueDate)}'),
                              backgroundColor: activity.isOverdue ? const Color(0xFFB91C1C).withValues(alpha: 0.12) : null,
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _SummaryStrip(summary: detail.summary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (activity.isGroup)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: () => _openGroupsDialog(detail, names),
                      icon: const Icon(Icons.groups_outlined),
                      label: const Text('Configurar grupos'),
                    ),
                  ),
                Text('Entregas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _SubmissionFilter.values.map((filter) {
                    return FilterChip(
                      label: Text(filter.label),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      _filter == _SubmissionFilter.all
                          ? 'Nenhuma entrega cadastrada.'
                          : 'Nenhuma entrega com status "${_filter.label}".',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                else
                  ...filtered.map(
                    (submission) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(names[submission.studentId] ?? submission.studentId),
                        subtitle: submission.score != null
                            ? Text(
                                'Nota: ${submission.score!.toStringAsFixed(1)} / ${activity.maxScore.toStringAsFixed(0)}',
                              )
                            : null,
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusChip.submissionStatus(submission.status),
                            if (submission.status == 'PENDING')
                              IconButton(
                                icon: const Icon(Icons.upload_outlined),
                                tooltip: 'Marcar como entregue',
                                onPressed: () => ref.read(activitiesActionsProvider).markSubmitted(
                                      submission.id,
                                      activityId: widget.activityId,
                                    ),
                              ),
                            if (submission.status == 'SUBMITTED')
                              IconButton(
                                icon: const Icon(Icons.undo_rounded),
                                tooltip: 'Voltar para pendente',
                                onPressed: () => ref.read(activitiesActionsProvider).markPending(
                                      submission.id,
                                      activityId: widget.activityId,
                                    ),
                              ),
                            if (submission.status != 'PENDING')
                              IconButton(
                                icon: const Icon(Icons.grade_outlined),
                                tooltip: 'Avaliar',
                                onPressed: () => _openGradeDialog(
                                  activity.maxScore,
                                  submission,
                                  activity.isSharedGrade,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteActivity(Activity activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir atividade'),
        content: Text(
          'Excluir "${activity.title}"?\n\n'
          'A atividade deixará de aparecer na turma. Entregas e grupos vinculados também serão arquivados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref.read(activitiesActionsProvider).delete(
            activity.id,
            classId: widget.classId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Atividade excluída.')),
      );
      // Volta para a aba Atividades da turma (índice 3).
      context.go(AppRoutes.classDetail(widget.classId), extra: 3);
    } catch (e) {
      if (!mounted) return;
      final detail = e is AppException ? e.displayMessage : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir atividade: $detail')),
      );
    }
  }

  Future<void> _openEditActivityDialog(Activity activity) async {
    final draft = await showDialog<_EditActivityDraft>(
      context: context,
      builder: (context) => _EditActivityDialog(activity: activity),
    );
    if (draft == null || !mounted) return;

    try {
      await ref.read(activitiesActionsProvider).update(
            activity.id,
            classId: widget.classId,
            title: draft.title,
            description: draft.description,
            tag: draft.tag,
            category: draft.category,
            maxScore: draft.maxScore,
            dueDate: draft.dueDate,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atividade atualizada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar atividade: $e')),
        );
      }
    }
  }

  Future<void> _openGradeDialog(
    double maxScore,
    Submission submission,
    bool isSharedGrade,
  ) async {
    final formKey = GlobalKey<FormState>();
    final scoreController = TextEditingController(text: submission.score?.toString() ?? '');
    final observationsController = TextEditingController(text: submission.observations ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSharedGrade ? 'Avaliar grupo' : 'Avaliar entrega'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Nota (0 a ${maxScore.toStringAsFixed(0)})'),
                validator: (v) {
                  final value = double.tryParse(v ?? '');
                  if (value == null) return 'Informe um número';
                  if (value < 0 || value > maxScore) return 'Deve estar entre 0 e ${maxScore.toStringAsFixed(0)}';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: observationsController,
                decoration: const InputDecoration(labelText: 'Observações (opcional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Salvar nota'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final score = double.parse(scoreController.text);
    final observations = observationsController.text.trim().isEmpty ? null : observationsController.text.trim();
    final actions = ref.read(activitiesActionsProvider);
    try {
      if (isSharedGrade && submission.groupId != null) {
        await actions.gradeShared(
          widget.activityId,
          submission.groupId!,
          score: score,
          observations: observations,
        );
      } else {
        await actions.gradeSubmission(
          submission.id,
          activityId: widget.activityId,
          score: score,
          observations: observations,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao avaliar: $e')));
      }
    }
  }

  Future<void> _openGroupsDialog(
    ActivityDetail detail,
    Map<String, String> names,
  ) async {
    final ungrouped = detail.submissions.map((s) => s.studentId).toSet();
    final groups = <({String name, List<String> studentIds})>[];

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final assigned = groups.expand((g) => g.studentIds).toSet();
          final remaining = ungrouped.difference(assigned).toList();

          return AlertDialog(
            title: const Text('Configurar grupos'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in groups)
                      ListTile(
                        dense: true,
                        title: Text(group.name),
                        subtitle: Text(group.studentIds.map((id) => names[id] ?? id).join(', ')),
                      ),
                    if (remaining.isNotEmpty)
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          final created = await _openCreateGroupDialog(remaining, names);
                          if (created != null) setState(() => groups.add(created));
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Adicionar grupo'),
                      )
                    else
                      const Text('Todos os alunos já foram alocados em um grupo.'),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              FilledButton(
                onPressed: groups.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(context);
                        try {
                          await ref.read(activitiesActionsProvider).createGroups(detail.activity.id, groups);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao salvar grupos: $e')),
                            );
                          }
                        }
                      },
                child: const Text('Salvar grupos'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<({String name, List<String> studentIds})?> _openCreateGroupDialog(
    List<String> availableIds,
    Map<String, String> names,
  ) async {
    final nameController = TextEditingController(text: 'Grupo ${DateTime.now().millisecondsSinceEpoch % 1000}');
    final selected = <String>{};

    return showDialog<({String name, List<String> studentIds})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Novo grupo'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome do grupo')),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView(
                    shrinkWrap: true,
                    children: availableIds
                        .map(
                          (id) => CheckboxListTile(
                            value: selected.contains(id),
                            title: Text(names[id] ?? id),
                            onChanged: (checked) => setState(() {
                              if (checked == true) {
                                selected.add(id);
                              } else {
                                selected.remove(id);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, (name: nameController.text.trim(), studentIds: selected.toList())),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _EditActivityDraft = ({
  String title,
  String? description,
  String? tag,
  String category,
  double maxScore,
  DateTime dueDate,
});

/// Diálogo Stateful para descartar controllers só no `dispose` do State
/// (evita assertion `_dependents.isEmpty` ao salvar).
class _EditActivityDialog extends StatefulWidget {
  const _EditActivityDialog({required this.activity});

  final Activity activity;

  @override
  State<_EditActivityDialog> createState() => _EditActivityDialogState();
}

class _EditActivityDialogState extends State<_EditActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagController;
  late final TextEditingController _maxScoreController;
  late String _category;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    _titleController = TextEditingController(text: activity.title);
    _descriptionController = TextEditingController(text: activity.description ?? '');
    _tagController = TextEditingController(text: activity.tag ?? '');
    _maxScoreController = TextEditingController(text: activity.maxScore.toStringAsFixed(0));
    _category = activity.category;
    _dueDate = activity.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final maxScore = double.parse(_maxScoreController.text);
    final description = _descriptionController.text.trim();
    final tag = _tagController.text.trim();
    Navigator.pop(context, (
      title: _titleController.text.trim(),
      description: description.isEmpty ? null : description,
      tag: tag.isEmpty ? null : tag,
      category: _category,
      maxScore: maxScore,
      dueDate: _dueDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar atividade'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                autofocus: true,
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: Activity.categoryLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxScoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nota máxima'),
                validator: (v) {
                  final value = double.tryParse(v ?? '');
                  if (value == null || value <= 0) return 'Informe um número válido';
                  return null;
                },
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});

  final ActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        stat('Total', '${summary.total}'),
        stat('Pendentes', '${summary.pending}'),
        stat('Entregues', '${summary.submitted}'),
        stat('Avaliadas', '${summary.graded}'),
        stat('Média', summary.averageScore?.toStringAsFixed(1) ?? '—'),
      ],
    );
  }
}
