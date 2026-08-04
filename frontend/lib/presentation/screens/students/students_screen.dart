import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../domain/entities/student.dart';
import '../../providers/students_providers.dart';

/// Lista + CRUD de alunos do professor.
class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsListProvider);

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'students_bulk_paste',
            onPressed: () => _openBulkPasteDialog(context),
            icon: const Icon(Icons.content_paste_go_rounded),
            label: const Text('Colar lista'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'students_new',
            onPressed: () => _openFormDialog(context),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Novo aluno'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar aluno por nome…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(studentSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) => ref.read(studentSearchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(studentsListProvider),
              child: AsyncValueWidget<List<Student>>(
                value: studentsAsync,
                onRetry: () => ref.invalidate(studentsListProvider),
                isEmpty: (list) => list.isEmpty,
                emptyIcon: Icons.people_outline_rounded,
                emptyMessage: 'Nenhum aluno encontrado.',
                data: (students) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: students.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      child: ListTile(
                        title: Text(student.name),
                        subtitle: Text(
                          [
                            if (student.registryCode?.isNotEmpty == true) 'Matrícula ${student.registryCode}',
                            if (student.email?.isNotEmpty == true) student.email!,
                          ].join(' · '),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _openFormDialog(context, student: student);
                            if (value == 'delete') _confirmDelete(context, student);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(value: 'delete', child: Text('Excluir')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBulkPasteDialog(BuildContext context) async {
    final textController = TextEditingController();
    var submitting = false;

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Colar lista de alunos'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cole um nome por linha, ou registros no formato Matrícula;Nome;E-mail…',
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
                        controller: textController,
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
                  onPressed: submitting ? null : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: submitting
                      ? null
                      : () async {
                          final text = textController.text.trim();
                          if (text.isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Cole ao menos um nome ou registro.')),
                            );
                            return;
                          }

                          setDialogState(() => submitting = true);
                          try {
                            final bulk = await ref.read(studentsActionsProvider).bulkCreate(text: text);
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext, true);
                            if (!mounted) return;

                            final skippedInfo = bulk.skipped.isEmpty
                                ? ''
                                : ' (${bulk.skipped.length} linha(s) ignorada(s))';
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${bulk.totalCreated} aluno(s) cadastrado(s)$skippedInfo',
                                ),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => submitting = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text('Erro ao cadastrar lista: $e')),
                            );
                          }
                        },
                  icon: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.group_add_rounded),
                  label: Text(submitting ? 'Cadastrando…' : 'Cadastrar todos'),
                ),
              ],
            );
          },
        );
      },
    );

    textController.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir aluno'),
        content: Text('Tem certeza que deseja excluir ${student.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(studentsActionsProvider).delete(student.id);
    }
  }

  Future<void> _openFormDialog(BuildContext context, {Student? student}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: student?.name ?? '');
    final registryController = TextEditingController(text: student?.registryCode ?? '');
    final emailController = TextEditingController(text: student?.email ?? '');
    final phoneController = TextEditingController(text: student?.phone ?? '');
    final notesController = TextEditingController(text: student?.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student == null ? 'Novo aluno' : 'Editar aluno'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: registryController,
                  decoration: const InputDecoration(labelText: 'Matrícula (opcional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'E-mail (opcional)'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Telefone (opcional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
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
    );

    if (saved != true) return;
    final actions = ref.read(studentsActionsProvider);
    try {
      if (student == null) {
        await actions.create(
          name: nameController.text.trim(),
          registryCode: registryController.text.trim().isEmpty ? null : registryController.text.trim(),
          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        );
      } else {
        await actions.update(
          student.id,
          name: nameController.text.trim(),
          registryCode: registryController.text.trim().isEmpty ? null : registryController.text.trim(),
          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Erro ao salvar aluno: $e')));
    }
  }
}
