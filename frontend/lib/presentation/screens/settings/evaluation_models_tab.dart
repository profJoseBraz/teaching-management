import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../domain/entities/evaluation_model.dart';
import '../../providers/evaluation_models_providers.dart';

/// Aba Config → Modelos avaliativos.
class EvaluationModelsTab extends ConsumerWidget {
  const EvaluationModelsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(evaluationModelsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo modelo'),
      ),
      body: AsyncValueWidget<List<EvaluationModel>>(
        value: modelsAsync,
        onRetry: () => ref.invalidate(evaluationModelsProvider),
        isEmpty: (list) => list.isEmpty,
        emptyIcon: Icons.fact_check_outlined,
        emptyMessage: 'Nenhum modelo avaliativo cadastrado.',
        data: (models) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: models.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final model = models[index];
            return Card(
              child: ListTile(
                title: Text(model.name),
                subtitle: Text(
                  [
                    if (!model.isActive) 'Inativo',
                    '${model.items.length} item(ns)',
                    if (model.description != null && model.description!.isNotEmpty)
                      model.description!,
                  ].join(' · '),
                ),
                leading: Icon(
                  model.isActive ? Icons.fact_check_outlined : Icons.pause_circle_outline,
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    try {
                      switch (value) {
                        case 'items':
                          await _openItemsDialog(context, ref, model);
                        case 'edit':
                          await _openEditDialog(context, ref, model);
                        case 'deactivate':
                          await ref.read(evaluationModelsActionsProvider).deactivate(model.id);
                        case 'activate':
                          await ref
                              .read(evaluationModelsActionsProvider)
                              .update(model.id, isActive: true);
                        case 'delete':
                          await ref.read(evaluationModelsActionsProvider).delete(model.id);
                      }
                    } on AppException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.displayMessage)),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'items', child: Text('Itens')),
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    if (model.isActive)
                      const PopupMenuItem(value: 'deactivate', child: Text('Desativar'))
                    else
                      const PopupMenuItem(value: 'activate', child: Text('Reativar')),
                    const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                  ],
                ),
                onTap: () => _openItemsDialog(context, ref, model),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final items = <({TextEditingController name, TextEditingController maxScore})>[
      (
        name: TextEditingController(text: 'Avaliação 1'),
        maxScore: TextEditingController(text: '10'),
      ),
    ];

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Novo modelo avaliativo'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nome do modelo'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Itens',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(items.length, (index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: item.name,
                                decoration: const InputDecoration(labelText: 'Nome'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: item.maxScore,
                                decoration: const InputDecoration(labelText: 'Máx.'),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                                  if (n == null || n <= 0) return 'Inválido';
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: items.length == 1
                                  ? null
                                  : () => setState(() => items.removeAt(index)),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () => setState(
                        () => items.add((
                          name: TextEditingController(),
                          maxScore: TextEditingController(text: '10'),
                        )),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar item'),
                    ),
                  ],
                ),
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
      await ref.read(evaluationModelsActionsProvider).create(
            name: nameController.text.trim(),
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
            items: [
              for (final item in items)
                (
                  name: item.name.text.trim(),
                  maxScore: double.parse(item.maxScore.text.replaceAll(',', '.')),
                ),
            ],
          );
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage)));
      }
    }
  }

  Future<void> _openEditDialog(
    BuildContext context,
    WidgetRef ref,
    EvaluationModel model,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: model.name);
    final descriptionController = TextEditingController(text: model.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar modelo'),
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
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    await ref.read(evaluationModelsActionsProvider).update(
          model.id,
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        );
  }

  Future<void> _openItemsDialog(
    BuildContext context,
    WidgetRef ref,
    EvaluationModel initial,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final models = ref.watch(evaluationModelsProvider).valueOrNull ?? const <EvaluationModel>[];
          final model = models.cast<EvaluationModel?>().firstWhere(
                (m) => m?.id == initial.id,
                orElse: () => initial,
              )!;

          return AlertDialog(
            title: Text('Itens — ${model.name}'),
            content: SizedBox(
              width: 420,
              height: 360,
              child: Column(
                children: [
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: model.items.length,
                      onReorder: (oldIndex, newIndex) async {
                        final ids = model.items.map((i) => i.id).toList();
                        if (newIndex > oldIndex) newIndex -= 1;
                        final moved = ids.removeAt(oldIndex);
                        ids.insert(newIndex, moved);
                        try {
                          await ref
                              .read(evaluationModelsActionsProvider)
                              .reorderItems(model.id, ids);
                        } on AppException catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.displayMessage)),
                            );
                          }
                        }
                      },
                      itemBuilder: (context, index) {
                        final item = model.items[index];
                        final recoveredName = item.isRecovery
                            ? model.items
                                .where((i) => i.id == item.recoversItemId)
                                .map((i) => i.name)
                                .firstOrNull
                            : null;
                        return ListTile(
                          key: ValueKey(item.id),
                          title: Text(item.name),
                          subtitle: Text(
                            [
                              'Nota máxima: ${item.maxScore.toStringAsFixed(1)}',
                              if (item.isRecovery)
                                'Recuperação de ${recoveredName ?? 'item'}',
                            ].join(' · '),
                          ),
                          leading: Icon(
                            item.isRecovery ? Icons.replay_rounded : Icons.drag_handle,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editItem(context, ref, model, item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(evaluationModelsActionsProvider)
                                        .deleteItem(model.id, item.id);
                                  } on AppException catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.displayMessage)),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _addItem(context, ref, model),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo item'),
                  ),
                ],
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

  Future<void> _addItem(BuildContext context, WidgetRef ref, EvaluationModel model) async {
    final draft = await _itemDialog(context, model: model);
    if (draft == null) return;
    try {
      await ref.read(evaluationModelsActionsProvider).createItem(
            model.id,
            name: draft.name,
            maxScore: draft.maxScore,
            isRecovery: draft.isRecovery,
            recoversItemId: draft.recoversItemId,
          );
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage)));
      }
    }
  }

  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    EvaluationModel model,
    EvaluationModelItem item,
  ) async {
    final draft = await _itemDialog(context, model: model, item: item);
    if (draft == null) return;
    try {
      await ref.read(evaluationModelsActionsProvider).updateItem(
            model.id,
            item.id,
            name: draft.name,
            maxScore: draft.maxScore,
            isRecovery: draft.isRecovery,
            recoversItemId: draft.recoversItemId,
          );
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage)));
      }
    }
  }

  Future<({String name, double maxScore, bool isRecovery, String? recoversItemId})?> _itemDialog(
    BuildContext context, {
    required EvaluationModel model,
    EvaluationModelItem? item,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name ?? '');
    final maxController = TextEditingController(
      text: item == null
          ? '10'
          : item.maxScore.toStringAsFixed(
              item.maxScore.truncateToDouble() == item.maxScore ? 0 : 1,
            ),
    );
    var isRecovery = item?.isRecovery ?? false;
    String? recoversItemId = item?.recoversItemId;

    final regularOptions = model.items
        .where((i) => !i.isRecovery && i.id != item?.id)
        .where(
          (i) =>
              item?.recoversItemId == i.id ||
              !model.items.any((r) => r.isRecovery && r.recoversItemId == i.id && r.id != item?.id),
        )
        .toList();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Novo item' : 'Editar item'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    helperText: 'Ex.: Avaliação 1, Projeto, Recuperação 1',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: maxController,
                  decoration: const InputDecoration(labelText: 'Nota máxima'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Informe um valor > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: isRecovery,
                  onChanged: (value) {
                    setDialogState(() {
                      isRecovery = value ?? false;
                      if (!isRecovery) recoversItemId = null;
                    });
                  },
                  title: const Text('Este item é uma recuperação'),
                  subtitle: const Text(
                    'A nota considerada será a maior entre a avaliação e esta recuperação.',
                  ),
                ),
                if (isRecovery) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: recoversItemId != null &&
                            regularOptions.any((i) => i.id == recoversItemId)
                        ? recoversItemId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Recupera qual item?',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final regular in regularOptions)
                        DropdownMenuItem(value: regular.id, child: Text(regular.name)),
                    ],
                    onChanged: (value) => setDialogState(() => recoversItemId = value),
                    validator: (value) {
                      if (isRecovery && (value == null || value.isEmpty)) {
                        return 'Selecione o item recuperado';
                      }
                      return null;
                    },
                  ),
                ],
              ],
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

    if (saved != true) return null;
    return (
      name: nameController.text.trim(),
      maxScore: double.parse(maxController.text.replaceAll(',', '.')),
      isRecovery: isRecovery,
      recoversItemId: isRecovery ? recoversItemId : null,
    );
  }
}
