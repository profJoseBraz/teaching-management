import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/async_value_widget.dart';
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
class ActivitiesTab extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (classId: classId, disciplineId: disciplineFilter);
    final activitiesAsync = ref.watch(activitiesListProvider(query));
    final disciplineNames = {for (final d in disciplines) d.id: d.name};

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context, ref),
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
          data: (activities) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: activities.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${disciplineNames[activity.disciplineId] ?? 'Disciplina'} · ${activity.categoryLabel} · '
                    'Entrega em ${_dateFormat.format(activity.dueDate)} · Vale ${activity.maxScore.toStringAsFixed(0)} pts',
                  ),
                  trailing: activity.isOverdue
                      ? const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309))
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRoutes.activityDetail(classId, activity.id)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final lessons = ref.read(lessonsListProvider((classId: classId, disciplineId: null))).valueOrNull ?? const <Lesson>[];
    if (lessons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre uma aula primeiro — toda atividade nasce de uma aula de origem.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final maxScoreController = TextEditingController(text: '100');
    String originLessonId = lessons.first.id;
    String? disciplineId;
    String category = 'ASSIGNMENT';
    String mode = 'INDIVIDUAL';
    String gradeMode = 'INDIVIDUAL';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nova atividade'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um título' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: originLessonId,
                    decoration: const InputDecoration(labelText: 'Aula de origem'),
                    items: lessons
                        .map((l) => DropdownMenuItem(
                              value: l.id,
                              child: Text('${_dateFormat.format(l.date)} · ${l.startTime}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => originLessonId = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: disciplineId,
                    decoration: const InputDecoration(labelText: 'Disciplina (opcional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Herdar da aula de origem')),
                      ...disciplines.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                    ],
                    onChanged: (v) => setState(() => disciplineId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: Activity.categoryLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => category = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: mode,
                          decoration: const InputDecoration(labelText: 'Modo'),
                          items: const [
                            DropdownMenuItem(value: 'INDIVIDUAL', child: Text('Individual')),
                            DropdownMenuItem(value: 'GROUP', child: Text('Grupo')),
                          ],
                          onChanged: (v) => setState(() => mode = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: gradeMode,
                          decoration: const InputDecoration(labelText: 'Correção'),
                          items: const [
                            DropdownMenuItem(value: 'INDIVIDUAL', child: Text('Individual')),
                            DropdownMenuItem(value: 'SHARED', child: Text('Compartilhada')),
                          ],
                          onChanged: (v) => setState(() => gradeMode = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: maxScoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nota máxima'),
                    validator: (v) => (double.tryParse(v ?? '') == null) ? 'Informe um número' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Entrega: ${_dateFormat.format(dueDate)}'),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => dueDate = picked);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    try {
      await ref.read(activitiesActionsProvider).create(
            classId,
            originLessonId: originLessonId,
            disciplineId: disciplineId,
            title: titleController.text.trim(),
            description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
            category: category,
            mode: mode,
            gradeMode: gradeMode,
            maxScore: double.parse(maxScoreController.text),
            dueDate: dueDate,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar atividade: $e')));
      }
    }
  }
}
