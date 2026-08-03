import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/school_class.dart';
import '../../../domain/entities/student.dart';
import '../../providers/academic_providers.dart';
import '../../providers/classes_providers.dart';
import '../../providers/lessons_providers.dart';
import '../../providers/students_providers.dart';
import '../activities/activities_screen.dart';
import '../contents/contents_screen.dart';
import '../lessons/lessons_screen.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

/// Hub da turma — cabeçalho com dados gerais, seletor de disciplina e abas
/// para Aulas, Frequência, Conteúdos, Atividades e Alunos.
///
/// Como uma turma pode ministrar múltiplas disciplinas, o professor escolhe
/// no topo qual disciplina deseja visualizar (ou "Todas") — a seleção filtra
/// as listagens de aulas, conteúdos e atividades nas abas abaixo.
class ClassDetailScreen extends ConsumerStatefulWidget {
  const ClassDetailScreen({super.key, required this.classId, this.initialTabIndex});

  final String classId;
  final int? initialTabIndex;

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Disciplina selecionada no filtro do topo. `null` = todas as
  /// disciplinas vinculadas à turma.
  String? _selectedDisciplineId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex?.clamp(0, 4) ?? 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classAsync = ref.watch(classDetailProvider(widget.classId));
    final schoolClass = classAsync.valueOrNull;
    final disciplines = schoolClass?.disciplines ?? const <ClassDisciplineRef>[];

    // Se a disciplina selecionada foi desvinculada da turma, volta para "Todas".
    if (_selectedDisciplineId != null && disciplines.every((d) => d.id != _selectedDisciplineId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDisciplineId = null);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: classAsync.when(
          data: (klass) => Text(klass.name),
          loading: () => const Text('Carregando…'),
          error: (_, _) => const Text('Turma'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Disciplinas da turma',
            onPressed: schoolClass == null ? null : () => _openManageDisciplinesDialog(context, schoolClass),
          ),
          classAsync.maybeWhen(
            data: (klass) => klass.isActive
                ? IconButton(
                    icon: const Icon(Icons.archive_outlined),
                    tooltip: 'Arquivar turma',
                    onPressed: () => _confirmArchive(context),
                  )
                : StatusChip.classStatus(klass.status),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Aulas'),
            Tab(text: 'Frequência'),
            Tab(text: 'Conteúdos'),
            Tab(text: 'Atividades'),
            Tab(text: 'Alunos'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (disciplines.length > 1)
            _DisciplineFilterBar(
              disciplines: disciplines,
              selectedId: _selectedDisciplineId,
              onSelect: (id) => setState(() => _selectedDisciplineId = id),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LessonsTab(
                  classId: widget.classId,
                  disciplines: disciplines,
                  disciplineFilter: _selectedDisciplineId,
                ),
                _AttendanceOverviewTab(classId: widget.classId, disciplineFilter: _selectedDisciplineId),
                ContentsTab(
                  classId: widget.classId,
                  disciplines: disciplines,
                  disciplineFilter: _selectedDisciplineId,
                ),
                ActivitiesTab(
                  classId: widget.classId,
                  disciplines: disciplines,
                  disciplineFilter: _selectedDisciplineId,
                ),
                _EnrollmentsTab(classId: widget.classId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arquivar turma'),
        content: const Text('A turma será marcada como arquivada, mas o histórico será preservado. Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Arquivar')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(classesActionsProvider).archive(widget.classId);
    }
  }

  Future<void> _openManageDisciplinesDialog(BuildContext context, SchoolClass schoolClass) async {
    final allDisciplines = ref.read(disciplinesProvider).valueOrNull ?? const <Discipline>[];
    if (allDisciplines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre disciplinas em Configurações primeiro.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, dialogRef, _) {
          final currentAsync = dialogRef.watch(classDetailProvider(widget.classId));
          final linkedIds = currentAsync.valueOrNull?.disciplineIds.toSet() ?? schoolClass.disciplineIds.toSet();

          return AlertDialog(
            title: Text('Disciplinas de ${schoolClass.name}'),
            content: SizedBox(
              width: 360,
              height: 320,
              child: ListView(
                shrinkWrap: true,
                children: allDisciplines
                    .map(
                      (d) => CheckboxListTile(
                        value: linkedIds.contains(d.id),
                        title: Text(d.name),
                        onChanged: (checked) => _toggleDiscipline(context, d.id, checked == true, linkedIds.length),
                      ),
                    )
                    .toList(),
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

  Future<void> _toggleDiscipline(BuildContext context, String disciplineId, bool link, int currentCount) async {
    final actions = ref.read(classesActionsProvider);
    try {
      if (link) {
        await actions.linkDiscipline(widget.classId, disciplineId);
      } else {
        if (currentCount <= 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A turma precisa manter ao menos uma disciplina vinculada.')),
          );
          return;
        }
        await actions.unlinkDiscipline(widget.classId, disciplineId);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar disciplina: $e')));
      }
    }
  }
}

/// Barra de chips exibida quando a turma tem mais de uma disciplina
/// vinculada, permitindo restringir Aulas/Conteúdos/Atividades a uma delas.
class _DisciplineFilterBar extends StatelessWidget {
  const _DisciplineFilterBar({
    required this.disciplines,
    required this.selectedId,
    required this.onSelect,
  });

  final List<ClassDisciplineRef> disciplines;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Todas as disciplinas'),
              selected: selectedId == null,
              onSelected: (_) => onSelect(null),
            ),
            const SizedBox(width: 8),
            for (final discipline in disciplines) ...[
              ChoiceChip(
                label: Text(discipline.name),
                selected: selectedId == discipline.id,
                onSelected: (_) => onSelect(discipline.id),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttendanceOverviewTab extends ConsumerWidget {
  const _AttendanceOverviewTab({required this.classId, this.disciplineFilter});

  final String classId;
  final String? disciplineFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (classId: classId, disciplineId: disciplineFilter);
    final lessonsAsync = ref.watch(lessonsListProvider(query));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(lessonsListProvider(query)),
      child: AsyncValueWidget<List<Lesson>>(
        value: lessonsAsync,
        onRetry: () => ref.invalidate(lessonsListProvider(query)),
        isEmpty: (list) => list.isEmpty,
        emptyIcon: Icons.fact_check_outlined,
        emptyMessage: 'Cadastre aulas na aba "Aulas" para começar a fazer chamada.',
        data: (lessons) {
          final pending = lessons.where((l) => !l.attendanceCompleted).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: pending > 0 ? const Color(0xFFB45309).withValues(alpha: 0.1) : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        pending > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                        color: pending > 0 ? const Color(0xFFB45309) : const Color(0xFF15803D),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pending > 0
                              ? '$pending aula(s) aguardando chamada.'
                              : 'Todas as chamadas estão em dia.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...lessons.map(
                (lesson) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text('${_dateFormat.format(lesson.date)} · ${lesson.startTime}–${lesson.endTime}'),
                    trailing: StatusChip(
                      label: lesson.attendanceCompleted ? 'Concluída' : 'Fazer chamada',
                      color: lesson.attendanceCompleted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                    ),
                    onTap: () => context.go(AppRoutes.attendance(classId, lesson.id)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EnrollmentsTab extends ConsumerWidget {
  const _EnrollmentsTab({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(enrollmentsProvider(classId));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEnrollDialog(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Matricular'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(enrollmentsProvider(classId)),
        child: AsyncValueWidget<List<Enrollment>>(
          value: enrollmentsAsync,
          onRetry: () => ref.invalidate(enrollmentsProvider(classId)),
          isEmpty: (list) => list.where((e) => e.isActive).isEmpty,
          emptyIcon: Icons.people_outline_rounded,
          emptyMessage: 'Nenhum aluno matriculado nesta turma ainda.',
          data: (enrollments) {
            final active = enrollments.where((e) => e.isActive).toList();
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: active.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final enrollment = active[index];
                return Card(
                  child: ListTile(
                    title: Text(enrollment.student?.name ?? 'Aluno'),
                    subtitle: enrollment.student?.registryCode != null
                        ? Text('Matrícula: ${enrollment.student!.registryCode}')
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove_outlined),
                      tooltip: 'Encerrar matrícula',
                      onPressed: () => _confirmUnenroll(context, ref, enrollment),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmUnenroll(BuildContext context, WidgetRef ref, Enrollment enrollment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encerrar matrícula'),
        content: Text('Encerrar a matrícula de ${enrollment.student?.name ?? 'este aluno'} nesta turma?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Encerrar')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(classesActionsProvider).unenroll(classId, enrollment.studentId);
    }
  }

  Future<void> _openEnrollDialog(BuildContext context, WidgetRef ref) async {
    final allStudents = await ref.read(studentsRepositoryProvider).getStudents();
    final enrolled = ref.read(enrollmentsProvider(classId)).valueOrNull ?? const <Enrollment>[];
    final enrolledIds = enrolled.where((e) => e.isActive).map((e) => e.studentId).toSet();
    final available = allStudents.where((s) => !enrolledIds.contains(s.id)).toList();

    if (available.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todos os alunos cadastrados já estão matriculados nesta turma.')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final selected = await showDialog<Student>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Matricular aluno'),
        children: available
            .map((s) => SimpleDialogOption(onPressed: () => Navigator.pop(context, s), child: Text(s.name)))
            .toList(),
      ),
    );
    if (selected == null) return;
    try {
      await ref.read(classesActionsProvider).enroll(classId, selected.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao matricular: $e')));
      }
    }
  }
}
