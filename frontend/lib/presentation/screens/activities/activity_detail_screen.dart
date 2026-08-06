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
import '../../../domain/entities/assessment_period.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/school_class.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/academic_providers.dart';
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
  var _selectionMode = false;
  final Set<String> _selectedSubmissionIds = {};

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedSubmissionIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(activityDetailProvider(widget.activityId));
    final enrollmentsAsync = ref.watch(enrollmentsProvider(widget.classId));
    final classAsync = ref.watch(classDetailProvider(widget.classId));
    final disciplineNames = {
      for (final d in classAsync.valueOrNull?.disciplines ?? const <ClassDisciplineRef>[]) d.id: d.name,
    };
    final detail = detailAsync.valueOrNull;
    final names = {
      for (final e in enrollmentsAsync.valueOrNull ?? const <Enrollment>[])
        e.studentId: e.student?.name ?? 'Aluno',
    };
    final filtered = detail == null
        ? const <Submission>[]
        : (detail.submissions.where((s) => _filter.matches(s.status)).toList()
          ..sort((a, b) {
            final byName = (names[a.studentId] ?? '').toLowerCase().compareTo(
                  (names[b.studentId] ?? '').toLowerCase(),
                );
            return byName != 0 ? byName : a.studentId.compareTo(b.studentId);
          }));

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '${_selectedSubmissionIds.length} selecionado(s)' : 'Atividade'),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar seleção',
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: [
          if (_selectionMode) ...[
            TextButton(
              onPressed: filtered.isEmpty
                  ? null
                  : () => setState(() {
                        final visibleIds = filtered.map((s) => s.id).toSet();
                        final allSelected = visibleIds.every(_selectedSubmissionIds.contains);
                        if (allSelected) {
                          _selectedSubmissionIds.removeAll(visibleIds);
                        } else {
                          _selectedSubmissionIds.addAll(visibleIds);
                        }
                      }),
              child: Text(
                filtered.isNotEmpty && filtered.every((s) => _selectedSubmissionIds.contains(s.id))
                    ? 'Limpar'
                    : 'Todos',
              ),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist_rounded),
              tooltip: 'Selecionar para nota em lote',
              onPressed: detail == null
                  ? null
                  : () => setState(() {
                        _selectionMode = true;
                        _selectedSubmissionIds.clear();
                      }),
            ),
            IconButton(
              icon: Icon(
                detail?.activity.evaluated == true
                    ? Icons.replay_rounded
                    : Icons.verified_outlined,
              ),
              tooltip: detail?.activity.evaluated == true
                  ? 'Reabrir correção'
                  : 'Marcar como Avaliada',
              onPressed: detail == null ? null : () => _toggleEvaluated(detail.activity),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar atividade',
              onPressed: () {
                final schoolClass = classAsync.valueOrNull;
                if (detail == null || schoolClass == null) return;
                _openEditActivityDialog(detail.activity, schoolClass.disciplines);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir atividade',
              onPressed: () {
                if (detail == null) return;
                _confirmDeleteActivity(detail.activity);
              },
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _selectionMode
          ? SafeArea(
              child: Material(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: FilledButton.icon(
                    onPressed: _selectedSubmissionIds.isEmpty || detail == null
                        ? null
                        : () => _openBulkGradeDialog(detail.activity.maxScore),
                    icon: const Icon(Icons.grade_outlined),
                    label: Text(
                      _selectedSubmissionIds.isEmpty
                          ? 'Selecione alunos'
                          : 'Atribuir nota a ${_selectedSubmissionIds.length}',
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activityDetailProvider(widget.activityId)),
        child: AsyncValueWidget<ActivityDetail>(
          value: detailAsync,
          onRetry: () => ref.invalidate(activityDetailProvider(widget.activityId)),
          data: (detail) {
            final activity = detail.activity;

            return ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, _selectionMode ? 24 : 16),
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
                            ...activity.disciplineIds.map(
                              (id) => Chip(
                                avatar: const Icon(Icons.menu_book_outlined, size: 16),
                                label: Text(disciplineNames[id] ?? 'Disciplina'),
                              ),
                            ),
                            StatusChip.activityEvaluation(activity.evaluated),
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
                if (_selectionMode) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Toque nos alunos para selecionar e atribuir a mesma nota a todos.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
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
                    (submission) {
                      final selected = _selectedSubmissionIds.contains(submission.id);
                      return Card(
                        key: ValueKey(submission.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        color: selected
                            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35)
                            : null,
                        child: ListTile(
                          leading: _selectionMode
                              ? Checkbox(
                                  value: selected,
                                  onChanged: (value) => setState(() {
                                    if (value == true) {
                                      _selectedSubmissionIds.add(submission.id);
                                    } else {
                                      _selectedSubmissionIds.remove(submission.id);
                                    }
                                  }),
                                )
                              : null,
                          onTap: _selectionMode
                              ? () => setState(() {
                                    if (selected) {
                                      _selectedSubmissionIds.remove(submission.id);
                                    } else {
                                      _selectedSubmissionIds.add(submission.id);
                                    }
                                  })
                              : null,
                          title: Text(names[submission.studentId] ?? submission.studentId),
                          subtitle: submission.score != null
                              ? Text(
                                  'Nota: ${submission.score!.toStringAsFixed(1)} / ${activity.maxScore.toStringAsFixed(0)}',
                                )
                              : null,
                          trailing: _selectionMode
                              ? StatusChip.submissionStatus(submission.status)
                              : Wrap(
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
                                    if (submission.status == 'SUBMITTED' || submission.status == 'GRADED')
                                      IconButton(
                                        icon: const Icon(Icons.undo_rounded),
                                        tooltip: 'Voltar para pendente',
                                        onPressed: () => _revertToPending(submission),
                                      ),
                                    if (submission.status != 'PENDING')
                                      IconButton(
                                        icon: const Icon(Icons.grade_outlined),
                                        tooltip: submission.status == 'GRADED' ? 'Reavaliar' : 'Avaliar',
                                        onPressed: () => _openGradeDialog(
                                          activity.maxScore,
                                          submission,
                                          activity.isSharedGrade,
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _revertToPending(Submission submission) async {
    final isGraded = submission.status == 'GRADED';
    if (isGraded) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Voltar para pendente'),
          content: const Text(
            'Esta entrega está Avaliada. Ao voltar para Pendente, a nota e as observações serão removidas.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }

    try {
      await ref.read(activitiesActionsProvider).markPending(
            submission.id,
            activityId: widget.activityId,
          );
    } catch (e) {
      if (!mounted) return;
      final detail = e is AppException ? e.displayMessage : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao voltar para pendente: $detail')),
      );
    }
  }

  Future<void> _openBulkGradeDialog(double maxScore) async {
    final count = _selectedSubmissionIds.length;
    if (count == 0) return;

    final draft = await showDialog<_BulkGradeDraft>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _BulkGradeDialog(maxScore: maxScore, selectedCount: count),
    );
    if (draft == null || !mounted) return;

    try {
      await ref.read(activitiesActionsProvider).gradeSubmissionsBulk(
            widget.activityId,
            submissionIds: _selectedSubmissionIds.toList(),
            score: draft.score,
            observations: draft.observations,
          );
      if (!mounted) return;
      _exitSelectionMode();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nota atribuída a $count aluno(s).')),
      );
    } catch (e) {
      if (!mounted) return;
      final detail = e is AppException ? e.displayMessage : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao avaliar em lote: $detail')),
      );
    }
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

  Future<void> _toggleEvaluated(Activity activity) async {
    try {
      final actions = ref.read(activitiesActionsProvider);
      if (activity.evaluated) {
        await actions.reopenEvaluation(activity.id, classId: widget.classId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atividade reaberta para correção.')),
        );
      } else {
        await actions.markEvaluated(activity.id, classId: widget.classId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atividade marcada como Avaliada.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final detail = e is AppException ? e.displayMessage : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status: $detail')),
      );
    }
  }

  Future<void> _openEditActivityDialog(
    Activity activity,
    List<ClassDisciplineRef> disciplines,
  ) async {
    final periods = [
      ...(ref.read(effectiveYearPeriodsProvider).valueOrNull ?? const <AssessmentPeriod>[]),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (periods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um período avaliativo em Config antes de editar a atividade.'),
        ),
      );
      return;
    }

    final contextPeriodId = ref.read(effectiveAssessmentPeriodIdProvider);
    var initialPeriodId = activity.assessmentPeriodId ?? contextPeriodId ?? periods.first.id;
    if (!periods.any((p) => p.id == initialPeriodId)) {
      initialPeriodId = contextPeriodId ?? periods.first.id;
    }

    final draft = await showDialog<_EditActivityDraft>(
      context: context,
      builder: (context) => _EditActivityDialog(
        activity: activity,
        disciplines: disciplines,
        periods: periods,
        initialAssessmentPeriodId: initialPeriodId,
      ),
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
            disciplineIds: draft.disciplineIds,
            assessmentPeriodId: draft.assessmentPeriodId,
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
    final draft = await showDialog<_BulkGradeDraft>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _SingleGradeDialog(
        maxScore: maxScore,
        isSharedGrade: isSharedGrade,
        initialScore: submission.score,
        initialObservations: submission.observations,
      ),
    );
    if (draft == null || !mounted) return;

    final actions = ref.read(activitiesActionsProvider);
    try {
      if (isSharedGrade && submission.groupId != null) {
        await actions.gradeShared(
          widget.activityId,
          submission.groupId!,
          score: draft.score,
          observations: draft.observations,
        );
      } else {
        await actions.gradeSubmission(
          submission.id,
          activityId: widget.activityId,
          score: draft.score,
          observations: draft.observations,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final detail = e is AppException ? e.displayMessage : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao avaliar: $detail')));
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
          final remaining = ungrouped.difference(assigned).toList()
            ..sort((a, b) => (names[a] ?? '').toLowerCase().compareTo((names[b] ?? '').toLowerCase()));

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

typedef _BulkGradeDraft = ({
  double score,
  String? observations,
});

/// Diálogo Stateful — controllers só são descartados no `dispose` do State
/// (evita tela vermelha ao fechar o diálogo de nota).
class _BulkGradeDialog extends StatefulWidget {
  const _BulkGradeDialog({
    required this.maxScore,
    required this.selectedCount,
  });

  final double maxScore;
  final int selectedCount;

  @override
  State<_BulkGradeDialog> createState() => _BulkGradeDialogState();
}

class _BulkGradeDialogState extends State<_BulkGradeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _scoreController;
  late final TextEditingController _observationsController;

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController();
    _observationsController = TextEditingController();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final observations = _observationsController.text.trim();
    Navigator.of(context).pop<_BulkGradeDraft>((
      score: double.parse(_scoreController.text),
      observations: observations.isEmpty ? null : observations,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final maxLabel = widget.maxScore.toStringAsFixed(0);
    return AlertDialog(
      title: Text('Nota para ${widget.selectedCount} aluno(s)'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A mesma nota será aplicada a todos os selecionados.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _scoreController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(labelText: 'Nota (0 a $maxLabel)'),
              validator: (v) {
                final value = double.tryParse(v ?? '');
                if (value == null) return 'Informe um número';
                if (value < 0 || value > widget.maxScore) {
                  return 'Deve estar entre 0 e $maxLabel';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observationsController,
              decoration: const InputDecoration(labelText: 'Observações (opcional)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Salvar nota')),
      ],
    );
  }
}

class _SingleGradeDialog extends StatefulWidget {
  const _SingleGradeDialog({
    required this.maxScore,
    required this.isSharedGrade,
    this.initialScore,
    this.initialObservations,
  });

  final double maxScore;
  final bool isSharedGrade;
  final double? initialScore;
  final String? initialObservations;

  @override
  State<_SingleGradeDialog> createState() => _SingleGradeDialogState();
}

class _SingleGradeDialogState extends State<_SingleGradeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _scoreController;
  late final TextEditingController _observationsController;

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController(
      text: widget.initialScore?.toString() ?? '',
    );
    _observationsController = TextEditingController(
      text: widget.initialObservations ?? '',
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final observations = _observationsController.text.trim();
    Navigator.of(context).pop<_BulkGradeDraft>((
      score: double.parse(_scoreController.text),
      observations: observations.isEmpty ? null : observations,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final maxLabel = widget.maxScore.toStringAsFixed(0);
    return AlertDialog(
      title: Text(widget.isSharedGrade ? 'Avaliar grupo' : 'Avaliar entrega'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _scoreController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(labelText: 'Nota (0 a $maxLabel)'),
              validator: (v) {
                final value = double.tryParse(v ?? '');
                if (value == null) return 'Informe um número';
                if (value < 0 || value > widget.maxScore) {
                  return 'Deve estar entre 0 e $maxLabel';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observationsController,
              decoration: const InputDecoration(labelText: 'Observações (opcional)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Salvar nota')),
      ],
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
  List<String> disciplineIds,
  String assessmentPeriodId,
});

/// Diálogo Stateful para descartar controllers só no `dispose` do State
/// (evita assertion `_dependents.isEmpty` ao salvar).
class _EditActivityDialog extends StatefulWidget {
  const _EditActivityDialog({
    required this.activity,
    required this.disciplines,
    required this.periods,
    required this.initialAssessmentPeriodId,
  });

  final Activity activity;
  final List<ClassDisciplineRef> disciplines;
  final List<AssessmentPeriod> periods;
  final String initialAssessmentPeriodId;

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
  late final Set<String> _selectedDisciplineIds;
  late String _assessmentPeriodId;
  var _showDisciplineError = false;

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
    _selectedDisciplineIds = {...activity.disciplineIds};
    _assessmentPeriodId = widget.initialAssessmentPeriodId;
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
    if (_selectedDisciplineIds.isEmpty) {
      setState(() => _showDisciplineError = true);
      return;
    }
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
      disciplineIds: _selectedDisciplineIds.toList(),
      assessmentPeriodId: _assessmentPeriodId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Editar atividade'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _assessmentPeriodId,
                decoration: const InputDecoration(labelText: 'Período'),
                items: widget.periods
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _assessmentPeriodId = value);
                },
                validator: (v) => (v == null || v.isEmpty) ? 'Selecione o período' : null,
              ),
              const SizedBox(height: 12),
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
              Text('Disciplinas', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
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
                  'Selecione ao menos uma disciplina.',
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
