import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../domain/entities/academic_year.dart';
import '../../../domain/entities/assessment_period.dart';
import '../../../domain/entities/course.dart';
import '../../../domain/entities/course_discipline.dart';
import '../../../domain/entities/discipline.dart';
import '../../providers/academic_providers.dart';
import '../../providers/session_providers.dart';
import '../../providers/theme_providers.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

/// Configurações — estrutura acadêmica (anos, cursos, disciplinas, períodos)
/// e preferências do app (tema).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Configurações'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Anos letivos'),
            Tab(text: 'Cursos'),
            Tab(text: 'Disciplinas'),
            Tab(text: 'Períodos'),
            Tab(text: 'Preferências'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AcademicYearsTab(),
          _CoursesTab(),
          _DisciplinesTab(),
          _AssessmentPeriodsTab(),
          _PreferencesTab(),
        ],
      ),
    );
  }
}

class _AcademicYearsTab extends ConsumerWidget {
  const _AcademicYearsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(academicYearsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo ano'),
      ),
      body: AsyncValueWidget<List<AcademicYear>>(
        value: yearsAsync,
        onRetry: () => ref.invalidate(academicYearsProvider),
        isEmpty: (list) => list.isEmpty,
        emptyIcon: Icons.calendar_month_outlined,
        emptyMessage: 'Nenhum ano letivo cadastrado.',
        data: (years) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: years.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final year = years[index];
            return Card(
              child: ListTile(
                title: Text(year.displayName),
                subtitle: (year.startsOn != null || year.endsOn != null)
                    ? Text(
                        '${year.startsOn != null ? _dateFormat.format(year.startsOn!) : '—'} a ${year.endsOn != null ? _dateFormat.format(year.endsOn!) : '—'}',
                      )
                    : null,
                leading: year.isCurrent
                    ? const Icon(Icons.star_rounded, color: Colors.amber)
                    : const Icon(Icons.star_border_rounded),
                trailing: year.isCurrent
                    ? null
                    : TextButton(
                        onPressed: () => ref.read(academicActionsProvider).setCurrentAcademicYear(year.id),
                        child: const Text('Tornar atual'),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final yearController = TextEditingController(text: '${DateTime.now().year}');
    final labelController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo ano letivo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ano'),
                validator: (v) => (int.tryParse(v ?? '') == null) ? 'Informe um ano válido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Rótulo (opcional)'),
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
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    try {
      await ref.read(academicActionsProvider).createAcademicYear(
            year: int.parse(yearController.text),
            label: labelController.text.trim().isEmpty ? null : labelController.text.trim(),
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar ano letivo: $e')));
      }
    }
  }
}

class _CoursesTab extends ConsumerWidget {
  const _CoursesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo curso'),
      ),
      body: AsyncValueWidget<List<Course>>(
        value: coursesAsync,
        onRetry: () => ref.invalidate(coursesProvider),
        isEmpty: (list) => list.isEmpty,
        emptyIcon: Icons.workspace_premium_outlined,
        emptyMessage: 'Nenhum curso cadastrado.',
        data: (courses) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: courses.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final course = courses[index];
            return Card(
              child: ListTile(
                title: Text(course.name),
                subtitle: course.description != null ? Text(course.description!) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Editar curso',
                      onPressed: () => _openEditDialog(context, ref, course),
                    ),
                    IconButton(
                      icon: const Icon(Icons.link_rounded),
                      tooltip: 'Vincular disciplinas',
                      onPressed: () => _openLinkDialog(context, ref, course),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Arquivar',
                      onPressed: () => ref.read(academicActionsProvider).deleteCourse(course.id),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo curso'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
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
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    await ref.read(academicActionsProvider).createCourse(
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        );
  }

  Future<void> _openEditDialog(BuildContext context, WidgetRef ref, Course course) async {
    final draft = await showDialog<({String name, String? description})>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _EditCourseDialog(course: course),
    );
    if (draft == null) return;

    await ref.read(academicActionsProvider).updateCourse(
          course.id,
          name: draft.name,
          description: draft.description,
        );
  }

  Future<void> _openLinkDialog(BuildContext context, WidgetRef ref, Course course) async {
    final disciplines = ref.read(disciplinesProvider).valueOrNull ?? const <Discipline>[];
    if (disciplines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre disciplinas primeiro.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final linksAsync = ref.watch(courseDisciplinesProvider(course.id));
          return AlertDialog(
            title: Text('Disciplinas de ${course.name}'),
            content: SizedBox(
              width: 360,
              child: AsyncValueWidget<List<CourseDiscipline>>(
                value: linksAsync,
                data: (links) {
                  final linkedIds = links.map((l) => l.disciplineId).toSet();
                  return SizedBox(
                    height: 320,
                    child: ListView(
                      shrinkWrap: true,
                      children: disciplines
                          .map(
                            (d) => CheckboxListTile(
                              value: linkedIds.contains(d.id),
                              title: Text(d.name),
                              onChanged: (checked) async {
                                if (checked == true) {
                                  await ref.read(academicActionsProvider).linkDisciplineToCourse(course.id, d.id);
                                } else {
                                  await ref.read(academicActionsProvider).unlinkDisciplineFromCourse(course.id, d.id);
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
            ],
          );
        },
      ),
    );
  }
}

class _DisciplinesTab extends ConsumerWidget {
  const _DisciplinesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplinesAsync = ref.watch(disciplinesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova disciplina'),
      ),
      body: AsyncValueWidget<List<Discipline>>(
        value: disciplinesAsync,
        onRetry: () => ref.invalidate(disciplinesProvider),
        isEmpty: (list) => list.isEmpty,
        emptyIcon: Icons.menu_book_outlined,
        emptyMessage: 'Nenhuma disciplina cadastrada.',
        data: (disciplines) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: disciplines.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final discipline = disciplines[index];
            return Card(
              child: ListTile(
                title: Text(discipline.name),
                subtitle: discipline.description != null ? Text(discipline.description!) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Arquivar',
                  onPressed: () => ref.read(academicActionsProvider).deleteDiscipline(discipline.id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova disciplina'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
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
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    await ref.read(academicActionsProvider).createDiscipline(
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        );
  }
}

class _AssessmentPeriodsTab extends ConsumerWidget {
  const _AssessmentPeriodsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final years = ref.watch(academicYearsProvider).valueOrNull ?? const <AcademicYear>[];
    final effectiveYear = ref.watch(effectiveAcademicYearProvider);

    if (years.isEmpty) {
      return const Center(child: Text('Cadastre um ano letivo primeiro.'));
    }

    final selectedYear = effectiveYear ?? years.first;
    final periodsAsync = ref.watch(assessmentPeriodsProvider(selectedYear.id));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(context, ref, selectedYear.id),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo período'),
      ),
      body: AsyncValueWidget<List<AssessmentPeriod>>(
        value: periodsAsync,
        onRetry: () => ref.invalidate(assessmentPeriodsProvider(selectedYear.id)),
        isEmpty: (list) => list.isEmpty,
        emptyIcon: Icons.event_repeat_outlined,
        emptyMessage: 'Nenhum período avaliativo para ${selectedYear.displayName}.',
        data: (periods) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: periods.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final period = periods[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${period.sortOrder + 1}')),
                title: Text(period.name),
                subtitle: (period.startsOn != null || period.endsOn != null)
                    ? Text(
                        '${period.startsOn != null ? _dateFormat.format(period.startsOn!) : '—'} a ${period.endsOn != null ? _dateFormat.format(period.endsOn!) : '—'}',
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context, WidgetRef ref, String academicYearId) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo período avaliativo'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nome (ex.: 1º Bimestre)'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
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
    );

    if (saved != true) return;
    await ref.read(academicActionsProvider).createAssessmentPeriod(
          academicYearId: academicYearId,
          name: nameController.text.trim(),
        );
  }
}

class _PreferencesTab extends ConsumerWidget {
  const _PreferencesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(authNotifierProvider).user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text(user.name),
              subtitle: Text(user.email),
            ),
          ),
        const SizedBox(height: 16),
        Text('Aparência', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                groupValue: themeMode,
                title: const Text('Padrão do sistema'),
                onChanged: (mode) => ref.read(themeModeProvider.notifier).setMode(mode!),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                groupValue: themeMode,
                title: const Text('Claro'),
                onChanged: (mode) => ref.read(themeModeProvider.notifier).setMode(mode!),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: themeMode,
                title: const Text('Escuro'),
                onChanged: (mode) => ref.read(themeModeProvider.notifier).setMode(mode!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sair da conta'),
        ),
      ],
    );
  }
}

class _EditCourseDialog extends StatefulWidget {
  const _EditCourseDialog({required this.course});

  final Course course;

  @override
  State<_EditCourseDialog> createState() => _EditCourseDialogState();
}

class _EditCourseDialogState extends State<_EditCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course.name);
    _descriptionController = TextEditingController(text: widget.course.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final description = _descriptionController.text.trim();
    Navigator.pop(context, (
      name: _nameController.text.trim(),
      description: description.isEmpty ? null : description,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar curso'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}
