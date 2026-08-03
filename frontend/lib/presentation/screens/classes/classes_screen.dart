import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/course.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/school_class.dart';
import '../../providers/academic_providers.dart';
import '../../providers/classes_providers.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesListProvider);
    final coursesAsync = ref.watch(coursesProvider);
    // Mantém a lista de disciplinas pré-carregada para o diálogo de criação.
    ref.watch(disciplinesProvider);
    final effectiveYear = ref.watch(effectiveAcademicYearProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: effectiveYear == null
            ? null
            : () => _openCreateDialog(context, ref, effectiveYear.id),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova turma'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(classesListProvider),
        child: AsyncValueWidget<List<SchoolClass>>(
          value: classesAsync,
          onRetry: () => ref.invalidate(classesListProvider),
          isEmpty: (list) => list.isEmpty,
          emptyIcon: Icons.school_outlined,
          emptyMessage: effectiveYear == null
              ? 'Cadastre um ano letivo em Configurações para começar.'
              : 'Nenhuma turma cadastrada para ${effectiveYear.displayName}.',
          data: (classes) {
            final courses = coursesAsync.valueOrNull ?? const <Course>[];
            final courseNames = {for (final c in courses) c.id: c.name};

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: classes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final schoolClass = classes[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(schoolClass.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${courseNames[schoolClass.courseId] ?? '—'} · ${schoolClass.disciplinesLabel} · ${schoolClass.shiftLabel}',
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusChip.classStatus(schoolClass.status),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () => context.go(AppRoutes.classDetail(schoolClass.id)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref, String academicYearId) async {
    final courses = ref.read(coursesProvider).valueOrNull ?? const <Course>[];
    final disciplines = ref.read(disciplinesProvider).valueOrNull ?? const <Discipline>[];

    if (courses.isEmpty || disciplines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre ao menos um curso e uma disciplina em Configurações primeiro.')),
      );
      return;
    }

    final nameController = TextEditingController();
    String? courseId = courses.first.id;
    final selectedDisciplineIds = <String>{disciplines.first.id};
    String? shift;
    final formKey = GlobalKey<FormState>();
    var showDisciplineError = false;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nova turma'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome (ex.: 3º DS - Manhã)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: courseId,
                    decoration: const InputDecoration(labelText: 'Curso'),
                    items: courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (value) => setState(() => courseId = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Disciplinas ministradas nesta turma',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: disciplines
                        .map(
                          (d) => FilterChip(
                            label: Text(d.name),
                            selected: selectedDisciplineIds.contains(d.id),
                            onSelected: (checked) => setState(() {
                              if (checked) {
                                selectedDisciplineIds.add(d.id);
                              } else {
                                selectedDisciplineIds.remove(d.id);
                              }
                              showDisciplineError = false;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  if (showDisciplineError) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Selecione ao menos uma disciplina.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: shift,
                    decoration: const InputDecoration(labelText: 'Turno (opcional)'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Não informado')),
                      DropdownMenuItem(value: 'MORNING', child: Text('Manhã')),
                      DropdownMenuItem(value: 'AFTERNOON', child: Text('Tarde')),
                      DropdownMenuItem(value: 'EVENING', child: Text('Vespertino')),
                      DropdownMenuItem(value: 'NIGHT', child: Text('Noite')),
                    ],
                    onChanged: (value) => setState(() => shift = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (selectedDisciplineIds.isEmpty) {
                  setState(() => showDisciplineError = true);
                  return;
                }
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );

    if (created != true || !context.mounted) return;

    try {
      await ref.read(classesActionsProvider).create(
            academicYearId: academicYearId,
            courseId: courseId!,
            disciplineIds: selectedDisciplineIds.toList(),
            name: nameController.text.trim(),
            shift: shift,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Turma criada com sucesso.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar turma: $e')));
      }
    }
  }
}
