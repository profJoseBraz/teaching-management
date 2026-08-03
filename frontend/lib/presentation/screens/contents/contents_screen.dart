import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/content_item.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/school_class.dart';
import '../../providers/contents_providers.dart';
import '../../providers/lessons_providers.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

/// Aba "Conteúdos" do hub da turma.
///
/// [disciplines] são as disciplinas vinculadas à turma (para o seletor do
/// formulário de criação) e [disciplineFilter] restringe a listagem à
/// disciplina selecionada no topo do detalhe da turma (`null` = todas).
class ContentsTab extends ConsumerWidget {
  const ContentsTab({
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
    final contentsAsync = ref.watch(contentsListProvider(query));
    final disciplineNames = {for (final d in disciplines) d.id: d.name};

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo conteúdo'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(contentsListProvider(query)),
        child: AsyncValueWidget<List<ContentItem>>(
          value: contentsAsync,
          onRetry: () => ref.invalidate(contentsListProvider(query)),
          isEmpty: (list) => list.isEmpty,
          emptyIcon: Icons.menu_book_outlined,
          emptyMessage: 'Nenhum conteúdo cadastrado ainda.',
          data: (contents) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: contents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final content = contents[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(content.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${disciplineNames[content.disciplineId] ?? 'Disciplina'}'
                    '${content.description?.isNotEmpty == true ? '\n${content.description}' : ''}'
                    '\nIniciado em ${_dateFormat.format(content.startedAt)}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusChip.contentStatus(content.status),
                      IconButton(
                        icon: const Icon(Icons.link_rounded),
                        tooltip: 'Vincular a uma aula',
                        onPressed: () => _openLinkDialog(context, ref, content),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'toggle') {
                            content.isCompleted
                                ? ref.read(contentsActionsProvider).reopen(content.id, classId: classId)
                                : ref.read(contentsActionsProvider).complete(content.id, classId: classId);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(content.isCompleted ? 'Reabrir' : 'Concluir'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    if (disciplines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vincule ao menos uma disciplina a esta turma antes de cadastrar conteúdos.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String disciplineId = disciplines.first.id;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Novo conteúdo'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: disciplineId,
                  decoration: const InputDecoration(labelText: 'Disciplina'),
                  items: disciplines.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (value) => setState(() => disciplineId = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um título' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                  maxLines: 3,
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
      ),
    );

    if (saved != true) return;
    await ref.read(contentsActionsProvider).create(
          classId,
          disciplineId: disciplineId,
          title: titleController.text.trim(),
          description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        );
  }

  Future<void> _openLinkDialog(BuildContext context, WidgetRef ref, ContentItem content) async {
    final lessons = ref.read(lessonsListProvider((classId: classId, disciplineId: null))).valueOrNull ?? const <Lesson>[];
    if (lessons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre uma aula primeiro para poder vincular conteúdos.')),
      );
      return;
    }
    final selectedId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Vincular a uma aula'),
        children: lessons
            .map(
              (lesson) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, lesson.id),
                child: Text('${_dateFormat.format(lesson.date)} · ${lesson.startTime}–${lesson.endTime}'),
              ),
            )
            .toList(),
      ),
    );
    if (selectedId == null) return;
    try {
      await ref.read(contentsActionsProvider).linkToLesson(selectedId, content.id, classId: classId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conteúdo vinculado à aula.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao vincular: $e')));
      }
    }
  }
}
