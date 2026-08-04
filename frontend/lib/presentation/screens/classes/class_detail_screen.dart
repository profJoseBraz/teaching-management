import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/school_class.dart';
import '../../../domain/entities/student.dart';
import '../../../domain/entities/student_paste_preview.dart';
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
  void didUpdateWidget(covariant ClassDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialTabIndex;
    if (next != null && next != _tabController.index) {
      _tabController.index = next.clamp(0, 4);
    }
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
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          data: (klass) => Text(klass.name),
          loading: () => const Text('Carregando…'),
          error: (_, _) => const Text('Turma'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar turma',
            onPressed: schoolClass == null ? null : () => _openEditClassDialog(context, schoolClass),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Disciplinas da turma',
            onPressed: schoolClass == null ? null : () => _openManageDisciplinesDialog(context, schoolClass),
          ),
          if (schoolClass != null)
            schoolClass.isActive
                ? IconButton(
                    icon: const Icon(Icons.archive_outlined),
                    tooltip: 'Arquivar turma',
                    onPressed: () => _confirmArchive(context),
                  )
                : StatusChip.classStatus(schoolClass.status),
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

  Future<void> _openEditClassDialog(BuildContext context, SchoolClass schoolClass) async {
    final result = await showDialog<({String name, String? shift})>(
      context: context,
      builder: (dialogContext) => _EditClassDialog(schoolClass: schoolClass),
    );

    if (result == null || !context.mounted) return;

    try {
      await ref.read(classesActionsProvider).update(
            widget.classId,
            name: result.name,
            shift: result.shift,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turma atualizada.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar turma: $e')),
        );
      }
    }
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
    await showDialog<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, dialogRef, _) {
          final currentAsync = dialogRef.watch(classDetailProvider(widget.classId));
          final courseLinksAsync = dialogRef.watch(courseDisciplinesProvider(schoolClass.courseId));
          final linkedIds = currentAsync.valueOrNull?.disciplineIds.toSet() ?? schoolClass.disciplineIds.toSet();
          final colorScheme = Theme.of(context).colorScheme;

          return AlertDialog(
            title: Text('Disciplinas de ${schoolClass.name}'),
            content: SizedBox(
              width: 360,
              height: 320,
              child: courseLinksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    'Não foi possível carregar a grade do curso.',
                    style: TextStyle(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
                data: (courseLinks) {
                  // Grade do curso + disciplinas já na turma (legado fora da grade).
                  final byId = <String, String>{
                    for (final link in courseLinks)
                      link.disciplineId: link.discipline?.name ?? 'Disciplina',
                    for (final d in schoolClass.disciplines) d.id: d.name,
                  };
                  final courseIds = courseLinks.map((l) => l.disciplineId).toSet();
                  final orderedIds = [
                    ...courseLinks.map((l) => l.disciplineId),
                    ...linkedIds.where((id) => !courseIds.contains(id)),
                  ];

                  if (orderedIds.isEmpty) {
                    return Center(
                      child: Text(
                        'Este curso ainda não tem disciplinas na grade.\n'
                        'Vincule-as em Config → Cursos → ícone de link.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView(
                    shrinkWrap: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Somente disciplinas da grade do curso podem ser adicionadas.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      ...orderedIds.map((id) {
                        final inCourse = courseIds.contains(id);
                        final isLinked = linkedIds.contains(id);
                        return CheckboxListTile(
                          value: isLinked,
                          title: Text(byId[id] ?? 'Disciplina'),
                          subtitle: inCourse ? null : const Text('Fora da grade atual do curso'),
                          // Só permite vincular se estiver na grade; desvincular sempre (com regra mín. 1).
                          onChanged: (!inCourse && !isLinked)
                              ? null
                              : (checked) => _toggleDiscipline(
                                    context,
                                    id,
                                    checked == true,
                                    linkedIds.length,
                                  ),
                        );
                      }),
                    ],
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

/// Diálogo de edição de nome/turno. Stateful para descartar o controller
/// apenas no `dispose` do State (evita assertion `_dependents.isEmpty`).
class _EditClassDialog extends StatefulWidget {
  const _EditClassDialog({required this.schoolClass});

  final SchoolClass schoolClass;

  @override
  State<_EditClassDialog> createState() => _EditClassDialogState();
}

class _EditClassDialogState extends State<_EditClassDialog> {
  static const _noShift = '__none__';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _shiftValue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.schoolClass.name);
    _shiftValue = widget.schoolClass.shift ?? _noShift;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      name: _nameController.text.trim(),
      shift: _shiftValue == _noShift ? null : _shiftValue,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar turma'),
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
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'class_enroll_bulk_paste',
            onPressed: () => _openBulkPasteAndEnrollDialog(context, ref),
            icon: const Icon(Icons.content_paste_go_rounded),
            label: const Text('Colar lista'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'class_enroll_select',
            onPressed: () => _openEnrollDialog(context, ref),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Matricular'),
          ),
        ],
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

  /// Cola lista → pré-visualiza → confirma seleção → cadastra novos e matricula.
  Future<void> _openBulkPasteAndEnrollDialog(BuildContext parentContext, WidgetRef ref) async {
    final text = await showDialog<String>(
      context: parentContext,
      useRootNavigator: true,
      builder: (_) => const _ClassPasteListDialog(),
    );
    if (text == null || text.isEmpty || !parentContext.mounted) return;

    // Evita abrir o próximo diálogo enquanto a rota anterior ainda está na árvore.
    await Future<void>.delayed(Duration.zero);
    if (!parentContext.mounted) return;

    var loadingOpen = true;
    showDialog<void>(
      context: parentContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    void closeLoading() {
      if (!loadingOpen || !parentContext.mounted) return;
      Navigator.of(parentContext, rootNavigator: true).pop();
      loadingOpen = false;
    }

    try {
      final preview = await ref.read(studentsActionsProvider).previewPaste(text: text);
      closeLoading();
      if (!parentContext.mounted) return;

      if (preview.candidates.isEmpty) {
        final skippedInfo = preview.skipped.isEmpty
            ? ''
            : ' (${preview.skipped.length} linha(s) ignorada(s))';
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text('Nenhum aluno válido encontrado$skippedInfo')),
        );
        return;
      }

      final enrolled = ref.read(enrollmentsProvider(classId)).valueOrNull ?? const <Enrollment>[];
      final enrolledIds = enrolled.where((e) => e.isActive).map((e) => e.studentId).toSet();

      final selected = await showDialog<List<StudentPasteCandidate>>(
        context: parentContext,
        useRootNavigator: true,
        builder: (_) => _ClassPasteConfirmDialog(
          preview: preview,
          enrolledIds: enrolledIds,
        ),
      );
      if (selected == null || selected.isEmpty || !parentContext.mounted) return;

      await _commitPasteSelection(parentContext, ref, selected, preview.skipped.length);
    } catch (e) {
      closeLoading();
      if (!parentContext.mounted) return;
      final detail = e is AppException ? e.displayMessage : e.toString();
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: Text('Erro ao processar lista: $detail')),
      );
    }
  }

  Future<void> _commitPasteSelection(
    BuildContext parentContext,
    WidgetRef ref,
    List<StudentPasteCandidate> selected,
    int skippedLines,
  ) async {
    try {
      final newOnes = selected.where((c) => c.isNew).toList();
      final existingIds = selected
          .where((c) => c.isExisting && c.student != null)
          .map((c) => c.student!.id)
          .toList();

      final created = newOnes.isEmpty
          ? const <Student>[]
          : await ref.read(studentsActionsProvider).createBatch(
                newOnes
                    .map(
                      (c) => (
                        name: c.name,
                        registryCode: c.registryCode,
                        email: c.email,
                        phone: c.phone,
                        notes: c.notes,
                      ),
                    )
                    .toList(),
              );

      final idsToEnroll = <String>[
        ...existingIds,
        ...created.map((s) => s.id),
      ];

      var enrolled = 0;
      var enrollSkipped = 0;
      if (idsToEnroll.isNotEmpty) {
        final enrollResult = await ref.read(classesActionsProvider).bulkEnroll(classId, idsToEnroll);
        enrolled = enrollResult.totalEnrolled;
        enrollSkipped = enrollResult.skipped;
      }

      if (!parentContext.mounted) return;
      final parts = <String>[
        if (enrolled > 0) '$enrolled aluno(s) adicionado(s) à turma',
        if (created.isNotEmpty) '${created.length} cadastrado(s)',
        if (skippedLines > 0) '$skippedLines linha(s) ignorada(s)',
        if (enrollSkipped > 0) '$enrollSkipped matrícula(s) ignorada(s)',
      ];
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: Text(parts.isEmpty ? 'Nenhuma alteração realizada' : parts.join(' · '))),
      );
    } catch (e) {
      if (!parentContext.mounted) return;
      final detail = e is AppException ? e.displayMessage : e.toString();
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar à turma: $detail')),
      );
    }
  }

  Future<void> _openEnrollDialog(BuildContext context, WidgetRef ref) async {
    final allStudents = await ref.read(studentsRepositoryProvider).getStudents();
    final enrolled = ref.read(enrollmentsProvider(classId)).valueOrNull ?? const <Enrollment>[];
    final enrolledIds = enrolled.where((e) => e.isActive).map((e) => e.studentId).toSet();
    final available = allStudents.where((s) => !enrolledIds.contains(s.id)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (available.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todos os alunos cadastrados já estão matriculados nesta turma.')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final selectedIds = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        final selected = <String>{};

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final allSelected = selected.length == available.length && available.isNotEmpty;

            return AlertDialog(
              title: const Text('Matricular alunos'),
              content: SizedBox(
                width: 480,
                height: 420,
                child: Column(
                  children: [
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setDialogState(() {
                            if (allSelected) {
                              selected.clear();
                            } else {
                              selected
                                ..clear()
                                ..addAll(available.map((s) => s.id));
                            }
                          }),
                          child: Text(allSelected ? 'Limpar seleção' : 'Selecionar todos'),
                        ),
                        const Spacer(),
                        Text(
                          '${selected.length} selecionado(s)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: available.length,
                        itemBuilder: (context, index) {
                          final student = available[index];
                          final checked = selected.contains(student.id);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (value) => setDialogState(() {
                              if (value == true) {
                                selected.add(student.id);
                              } else {
                                selected.remove(student.id);
                              }
                            }),
                            title: Text(student.name),
                            subtitle: student.registryCode == null || student.registryCode!.isEmpty
                                ? null
                                : Text('Matrícula: ${student.registryCode}'),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(dialogContext, selected.toList()),
                  icon: const Icon(Icons.group_add_rounded),
                  label: Text(
                    selected.isEmpty ? 'Matricular' : 'Matricular (${selected.length})',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedIds == null || selectedIds.isEmpty) return;

    try {
      final result = await ref.read(classesActionsProvider).bulkEnroll(classId, selectedIds);
      if (!context.mounted) return;
      final skippedInfo = result.skipped > 0 ? ' (${result.skipped} ignorado(s))' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.totalEnrolled} aluno(s) matriculado(s)$skippedInfo')),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao matricular: $e')));
      }
    }
  }
}

/// Diálogo de colar lista — dono do [TextEditingController] (evita dispose prematuro).
class _ClassPasteListDialog extends StatefulWidget {
  const _ClassPasteListDialog();

  @override
  State<_ClassPasteListDialog> createState() => _ClassPasteListDialogState();
}

class _ClassPasteListDialogState extends State<_ClassPasteListDialog> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final pasted = _textController.text.trim();
    if (pasted.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cole ao menos um nome ou registro.')),
      );
      return;
    }
    Navigator.of(context).pop(pasted);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Colar lista e matricular'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cole um nome por linha, ou registros no formato Matrícula;Nome;E-mail… '
                'Se alguma matrícula já existir, você poderá confirmar quem entra nesta turma.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Exemplos:\n'
                'Ana Souza\n'
                '2026002;Bruno Lima;bruno@escola.com\n'
                'Matrícula;Nome;E-mail\n'
                '2026003;Carla Mendes;carla@escola.com',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                minLines: 10,
                maxLines: 16,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Lista colada',
                  hintText: 'Cole aqui os nomes ou registros…',
                  border: OutlineInputBorder(),
                ),
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
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.preview_outlined),
          label: const Text('Continuar'),
        ),
      ],
    );
  }
}

/// Confirmação com checkboxes dos candidatos resolvidos pela lista colada.
class _ClassPasteConfirmDialog extends StatefulWidget {
  const _ClassPasteConfirmDialog({
    required this.preview,
    required this.enrolledIds,
  });

  final StudentPastePreview preview;
  final Set<String> enrolledIds;

  @override
  State<_ClassPasteConfirmDialog> createState() => _ClassPasteConfirmDialogState();
}

class _ClassPasteConfirmDialogState extends State<_ClassPasteConfirmDialog> {
  late final Set<String> _selectedKeys;

  @override
  void initState() {
    super.initState();
    _selectedKeys = {
      for (final c in widget.preview.candidates)
        if (!_alreadyInClass(c)) c.key,
    };
  }

  bool _alreadyInClass(StudentPasteCandidate candidate) =>
      candidate.isExisting &&
      candidate.student != null &&
      widget.enrolledIds.contains(candidate.student!.id);

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final selectable = preview.candidates.where((c) => !_alreadyInClass(c)).toList();
    final allSelected = selectable.isNotEmpty && _selectedKeys.length == selectable.length;

    return AlertDialog(
      title: const Text('Confirmar alunos na turma'),
      content: SizedBox(
        width: 560,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              preview.totalExisting > 0
                  ? 'Algumas matrículas já estão cadastradas. Confirme quem deve ser adicionado a esta turma.'
                  : 'Confirme os alunos que devem ser adicionados a esta turma.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (preview.skipped.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${preview.skipped.length} linha(s) ignorada(s) na análise.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: selectable.isEmpty
                      ? null
                      : () => setState(() {
                            if (allSelected) {
                              _selectedKeys.clear();
                            } else {
                              _selectedKeys
                                ..clear()
                                ..addAll(selectable.map((c) => c.key));
                            }
                          }),
                  child: Text(allSelected ? 'Limpar seleção' : 'Selecionar todos'),
                ),
                const Spacer(),
                Text(
                  '${_selectedKeys.length} selecionado(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: preview.candidates.length,
                itemBuilder: (context, index) {
                  final candidate = preview.candidates[index];
                  final alreadyInClass = _alreadyInClass(candidate);
                  final checked = _selectedKeys.contains(candidate.key);
                  final statusLabel = alreadyInClass
                      ? 'Já matriculado nesta turma'
                      : candidate.isExisting
                          ? 'Já cadastrado — será matriculado'
                          : 'Novo — será cadastrado e matriculado';
                  final subtitleParts = <String>[
                    if (candidate.registryCode != null && candidate.registryCode!.isNotEmpty)
                      'Matrícula ${candidate.registryCode}',
                    statusLabel,
                  ];

                  return CheckboxListTile(
                    key: ValueKey(candidate.key),
                    value: alreadyInClass ? false : checked,
                    onChanged: alreadyInClass
                        ? null
                        : (value) => setState(() {
                              if (value == true) {
                                _selectedKeys.add(candidate.key);
                              } else {
                                _selectedKeys.remove(candidate.key);
                              }
                            }),
                    title: Text(candidate.name),
                    subtitle: Text(subtitleParts.join(' · ')),
                    secondary: Icon(
                      candidate.isExisting ? Icons.badge_outlined : Icons.person_add_alt_1_outlined,
                      color: alreadyInClass
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.primary,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _selectedKeys.isEmpty
              ? null
              : () {
                  final chosen =
                      preview.candidates.where((c) => _selectedKeys.contains(c.key)).toList();
                  Navigator.of(context).pop(chosen);
                },
          icon: const Icon(Icons.group_add_rounded),
          label: Text(
            _selectedKeys.isEmpty
                ? 'Adicionar à turma'
                : 'Adicionar à turma (${_selectedKeys.length})',
          ),
        ),
      ],
    );
  }
}
