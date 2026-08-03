import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/school_class.dart';
import '../../providers/lessons_providers.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

/// Aba "Aulas" do hub da turma — CRUD de aulas e atalho para a chamada.
///
/// [disciplines] são as disciplinas vinculadas à turma (para o seletor do
/// formulário de criação) e [disciplineFilter] restringe a listagem à
/// disciplina selecionada no topo do detalhe da turma (`null` = todas).
class LessonsTab extends ConsumerWidget {
  const LessonsTab({
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
    final lessonsAsync = ref.watch(lessonsListProvider(query));
    final disciplineNames = {for (final d in disciplines) d.id: d.name};

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLessonDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova aula'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(lessonsListProvider(query)),
        child: AsyncValueWidget<List<Lesson>>(
          value: lessonsAsync,
          onRetry: () => ref.invalidate(lessonsListProvider(query)),
          isEmpty: (list) => list.isEmpty,
          emptyIcon: Icons.event_note_outlined,
          emptyMessage: 'Nenhuma aula cadastrada ainda.',
          data: (lessons) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: lessons.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text('${_dateFormat.format(lesson.date)} · ${lesson.startTime}–${lesson.endTime}'),
                  subtitle: Text(
                    [
                      disciplineNames[lesson.disciplineId] ?? 'Disciplina',
                      if (lesson.observations != null && lesson.observations!.isNotEmpty) lesson.observations!,
                    ].join(' · '),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusChip(
                        label: lesson.attendanceCompleted ? 'Chamada OK' : 'Sem chamada',
                        color: lesson.attendanceCompleted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fact_check_outlined),
                        tooltip: 'Fazer chamada',
                        onPressed: () => context.go(AppRoutes.attendance(classId, lesson.id)),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _openLessonDialog(context, ref, lesson: lesson);
                          if (value == 'delete') _confirmDelete(context, ref, lesson);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'delete', child: Text('Excluir')),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => context.go(AppRoutes.attendance(classId, lesson.id)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Lesson lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir aula'),
        content: const Text('Tem certeza que deseja excluir esta aula? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(lessonsActionsProvider).delete(lesson.id, classId: classId);
    }
  }

  Future<void> _openLessonDialog(BuildContext context, WidgetRef ref, {Lesson? lesson}) async {
    if (lesson == null && disciplines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vincule ao menos uma disciplina a esta turma antes de cadastrar aulas.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    DateTime date = lesson?.date ?? DateTime.now();
    String disciplineId = lesson?.disciplineId ?? disciplines.first.id;
    final startController = TextEditingController(text: lesson?.startTime ?? '08:00');
    final endController = TextEditingController(text: lesson?.endTime ?? '09:40');
    final observationsController = TextEditingController(text: lesson?.observations ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(lesson == null ? 'Nova aula' : 'Editar aula'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lesson == null)
                    DropdownButtonFormField<String>(
                      initialValue: disciplineId,
                      decoration: const InputDecoration(labelText: 'Disciplina'),
                      items: disciplines.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                      onChanged: (value) => setState(() => disciplineId = value!),
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.menu_book_outlined),
                      title: const Text('Disciplina'),
                      subtitle: Text(
                        disciplines.firstWhere((d) => d.id == disciplineId, orElse: () => ClassDisciplineRef(id: disciplineId, name: '—')).name,
                      ),
                    ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_dateFormat.format(date)),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: startController,
                          decoration: const InputDecoration(labelText: 'Início (HH:mm)'),
                          validator: (v) => (v == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) ? 'HH:mm' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: endController,
                          decoration: const InputDecoration(labelText: 'Fim (HH:mm)'),
                          validator: (v) => (v == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) ? 'HH:mm' : null,
                        ),
                      ),
                    ],
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
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;

    try {
      final actions = ref.read(lessonsActionsProvider);
      if (lesson == null) {
        await actions.create(
          classId,
          disciplineId: disciplineId,
          date: date,
          startTime: startController.text,
          endTime: endController.text,
          observations: observationsController.text.trim().isEmpty ? null : observationsController.text.trim(),
        );
      } else {
        await actions.update(
          lesson.id,
          classId: classId,
          date: date,
          startTime: startController.text,
          endTime: endController.text,
          observations: observationsController.text.trim().isEmpty ? null : observationsController.text.trim(),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar aula: $e')));
      }
    }
  }
}
