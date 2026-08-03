import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/activity_detail.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/activities_providers.dart';
import '../../providers/classes_providers.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

/// Detalhe de uma atividade — resumo + lista de entregas com avaliação.
class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.classId, required this.activityId});

  final String classId;
  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(activityDetailProvider(activityId));
    final enrollmentsAsync = ref.watch(enrollmentsProvider(classId));

    return Scaffold(
      appBar: AppBar(title: const Text('Atividade')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activityDetailProvider(activityId)),
        child: AsyncValueWidget<ActivityDetail>(
          value: detailAsync,
          onRetry: () => ref.invalidate(activityDetailProvider(activityId)),
          data: (detail) {
            final names = {
              for (final e in enrollmentsAsync.valueOrNull ?? const <Enrollment>[])
                e.studentId: e.student?.name ?? 'Aluno',
            };
            final activity = detail.activity;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        if (activity.description?.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(activity.description!),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
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
                      onPressed: () => _openGroupsDialog(context, ref, detail, names),
                      icon: const Icon(Icons.groups_outlined),
                      label: const Text('Configurar grupos'),
                    ),
                  ),
                Text('Entregas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...detail.submissions.map(
                  (submission) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(names[submission.studentId] ?? submission.studentId),
                      subtitle: submission.score != null
                          ? Text('Nota: ${submission.score!.toStringAsFixed(1)} / ${activity.maxScore.toStringAsFixed(0)}')
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
                                    activityId: activityId,
                                  ),
                            ),
                          if (submission.status != 'PENDING')
                            IconButton(
                              icon: const Icon(Icons.grade_outlined),
                              tooltip: 'Avaliar',
                              onPressed: () => _openGradeDialog(context, ref, activity.maxScore, submission, activity.isSharedGrade),
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

  Future<void> _openGradeDialog(
    BuildContext context,
    WidgetRef ref,
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
        await actions.gradeShared(activityId, submission.groupId!, score: score, observations: observations);
      } else {
        await actions.gradeSubmission(submission.id, activityId: activityId, score: score, observations: observations);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao avaliar: $e')));
      }
    }
  }

  Future<void> _openGroupsDialog(
    BuildContext context,
    WidgetRef ref,
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
                          final created = await _openCreateGroupDialog(context, remaining, names);
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar grupos: $e')));
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
    BuildContext context,
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
