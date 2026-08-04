import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/course.dart';
import '../../../domain/entities/school_class.dart';
import '../../providers/academic_providers.dart';
import '../../providers/classes_providers.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesListProvider);
    final coursesAsync = ref.watch(coursesProvider);
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

    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre ao menos um curso em Configurações primeiro.')),
      );
      return;
    }

    final result = await showDialog<({String name, String courseId, List<String> disciplineIds, String? shift})>(
      context: context,
      builder: (context) => _CreateClassDialog(courses: courses),
    );

    if (result == null || !context.mounted) return;

    try {
      await ref.read(classesActionsProvider).create(
            academicYearId: academicYearId,
            courseId: result.courseId,
            disciplineIds: result.disciplineIds,
            name: result.name,
            shift: result.shift,
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

/// Diálogo de criação: disciplinas disponíveis = grade do curso selecionado
/// (`CourseDiscipline`), não o catálogo global.
class _CreateClassDialog extends ConsumerStatefulWidget {
  const _CreateClassDialog({required this.courses});

  final List<Course> courses;

  @override
  ConsumerState<_CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends ConsumerState<_CreateClassDialog> {
  static const _noShift = '__none__';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String _courseId;
  final _selectedDisciplineIds = <String>{};
  String _shiftValue = _noShift;
  var _showDisciplineError = false;

  @override
  void initState() {
    super.initState();
    _courseId = widget.courses.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onCourseChanged(String? courseId) {
    if (courseId == null || courseId == _courseId) return;
    setState(() {
      _courseId = courseId;
      _selectedDisciplineIds.clear();
      _showDisciplineError = false;
    });
  }

  void _save() {
    if (_selectedDisciplineIds.isEmpty) {
      setState(() => _showDisciplineError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, (
      name: _nameController.text.trim(),
      courseId: _courseId,
      disciplineIds: _selectedDisciplineIds.toList(),
      shift: _shiftValue == _noShift ? null : _shiftValue,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(courseDisciplinesProvider(_courseId));
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Nova turma'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome (ex.: 3º DS - Manhã)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _courseId,
                decoration: const InputDecoration(labelText: 'Curso'),
                items: widget.courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: _onCourseChanged,
              ),
              const SizedBox(height: 16),
              Text(
                'Disciplinas da grade do curso',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              linksAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text(
                  'Não foi possível carregar as disciplinas do curso.',
                  style: TextStyle(color: colorScheme.error, fontSize: 13),
                ),
                data: (links) {
                  if (links.isEmpty) {
                    return Text(
                      'Este curso ainda não tem disciplinas na grade. '
                      'Vincule-as em Config → Cursos → ícone de link.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    );
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: links.map((link) {
                      final name = link.discipline?.name ?? 'Disciplina';
                      final selected = _selectedDisciplineIds.contains(link.disciplineId);
                      return FilterChip(
                        label: Text(name),
                        selected: selected,
                        onSelected: (checked) => setState(() {
                          if (checked) {
                            _selectedDisciplineIds.add(link.disciplineId);
                          } else {
                            _selectedDisciplineIds.remove(link.disciplineId);
                          }
                          _showDisciplineError = false;
                        }),
                      );
                    }).toList(),
                  );
                },
              ),
              if (_showDisciplineError) ...[
                const SizedBox(height: 6),
                Text(
                  'Selecione ao menos uma disciplina da grade do curso.',
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _shiftValue,
                decoration: const InputDecoration(labelText: 'Turno (opcional)'),
                items: const [
                  DropdownMenuItem(value: _noShift, child: Text('Não informado')),
                  DropdownMenuItem(value: 'MORNING', child: Text('Manhã')),
                  DropdownMenuItem(value: 'AFTERNOON', child: Text('Tarde')),
                  DropdownMenuItem(value: 'EVENING', child: Text('Vespertino')),
                  DropdownMenuItem(value: 'NIGHT', child: Text('Noite')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _shiftValue = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Criar')),
      ],
    );
  }
}
