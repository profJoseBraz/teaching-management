import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../data/datasources/grade_compositions_datasource.dart';
import '../../../domain/entities/evaluation_model.dart';
import '../../../domain/entities/grade_composition.dart';
import '../../providers/academic_providers.dart';
import '../../providers/evaluation_models_providers.dart';
import '../../providers/grade_compositions_providers.dart';

final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

class _GroupDraft {
  _GroupDraft({
    required this.evaluationModelItemId,
    required this.itemName,
    required this.itemMaxScore,
    required this.itemSortOrder,
    this.isRecovery = false,
    this.calculationMethod = GradeCompositionCalculationMethod.simpleAverage,
    Set<String>? selectedActivityIds,
    Map<String, double>? weights,
  })  : selectedActivityIds = selectedActivityIds ?? <String>{},
        weights = weights ?? <String, double>{};

  final String evaluationModelItemId;
  final String itemName;
  final double itemMaxScore;
  final int itemSortOrder;
  final bool isRecovery;
  GradeCompositionCalculationMethod calculationMethod;
  final Set<String> selectedActivityIds;
  final Map<String, double> weights;
}

/// Tela de composição da nota para Turma + Disciplina + Período atual.
class GradeCompositionScreen extends ConsumerStatefulWidget {
  const GradeCompositionScreen({
    super.key,
    required this.classId,
    required this.disciplineId,
    required this.disciplineName,
  });

  final String classId;
  final String disciplineId;
  final String disciplineName;

  @override
  ConsumerState<GradeCompositionScreen> createState() => _GradeCompositionScreenState();
}

class _GradeCompositionScreenState extends ConsumerState<GradeCompositionScreen> {
  String? _selectedModelId;
  List<_GroupDraft>? _drafts;
  bool _saving = false;
  bool _calculating = false;
  GradeCompositionCalculation? _calculation;
  String? _initializedForKey;
  bool _syncToastShown = false;
  /// Quando true, a tabela mostra só quem já tem nota máxima nos itens em que foi avaliado.
  bool _onlyMaximumGrades = false;

  /// Nota máxima nos itens **regulares** (não recuperação), usando a nota considerada
  /// (`max` entre avaliação e recuperação vinculada).
  bool _studentHasMaximumGrades(GradeCompositionStudentRow student) {
    final emptyNames = _calculation?.emptyGroupNames.toSet() ?? const <String>{};
    final regularGroups = student.groups.where(
      (g) => !g.isRecovery && !emptyNames.contains(g.itemName),
    );
    if (regularGroups.isEmpty) return false;
    for (final group in regularGroups) {
      final score = group.consideredScore ?? group.convertedScore;
      if (score == null) return false;
      if ((score - group.itemMaxScore).abs() > 0.009) return false;
    }
    return true;
  }

  GradeCompositionQuery? _query(WidgetRef ref) {
    final periodId = ref.watch(effectiveAssessmentPeriodIdProvider);
    if (periodId == null) return null;
    return (
      classId: widget.classId,
      disciplineId: widget.disciplineId,
      assessmentPeriodId: periodId,
    );
  }

  void _ensureDrafts(
    GradeCompositionContext contextData,
    List<EvaluationModel> models,
  ) {
    final key =
        '${contextData.composition?.id ?? 'new'}-${contextData.composition?.updatedAt.toIso8601String() ?? 'x'}-$_selectedModelId';
    if (_initializedForKey == key && _drafts != null) return;

    final composition = contextData.composition;
    final modelId = _selectedModelId ??
        composition?.evaluationModelId ??
        (models.isNotEmpty ? models.first.id : null);
    _selectedModelId = modelId;

    if (modelId == null) {
      _drafts = [];
      _initializedForKey = key;
      return;
    }

    final model = models.cast<EvaluationModel?>().firstWhere(
          (m) => m?.id == modelId,
          orElse: () => null,
        );

    if (composition != null && composition.evaluationModelId == modelId) {
      _drafts = [
        for (final group in composition.groups)
          _GroupDraft(
            evaluationModelItemId: group.evaluationModelItemId,
            itemName: group.itemName,
            itemMaxScore: group.itemMaxScore,
            itemSortOrder: group.itemSortOrder,
            isRecovery: group.isRecovery,
            calculationMethod: group.calculationMethod,
            selectedActivityIds: group.activities.map((a) => a.activityId).toSet(),
            weights: {
              for (final a in group.activities)
                if (a.weight != null) a.activityId: a.weight!,
            },
          ),
      ];
    } else if (model != null) {
      _drafts = [
        for (final item in model.items)
          _GroupDraft(
            evaluationModelItemId: item.id,
            itemName: item.name,
            itemMaxScore: item.maxScore,
            itemSortOrder: item.sortOrder,
            isRecovery: item.isRecovery,
          ),
      ];
    } else {
      _drafts = [];
    }

    _initializedForKey = key;
  }

  Set<String> _selectedAcrossGroups() {
    final drafts = _drafts ?? const <_GroupDraft>[];
    return {for (final d in drafts) ...d.selectedActivityIds};
  }

  Future<void> _save(GradeCompositionQuery query) async {
    final modelId = _selectedModelId;
    final drafts = _drafts;
    if (modelId == null || drafts == null) return;

    for (final draft in drafts) {
      if (draft.calculationMethod == GradeCompositionCalculationMethod.weightedAverage) {
        for (final activityId in draft.selectedActivityIds) {
          final weight = draft.weights[activityId];
          if (weight == null || weight <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Informe peso > 0 para todas as atividades de "${draft.itemName}".',
                ),
              ),
            );
            return;
          }
        }
      }
    }

    setState(() => _saving = true);
    try {
      final groups = [
        for (final draft in drafts)
          {
            'evaluationModelItemId': draft.evaluationModelItemId,
            'calculationMethod': methodToApi(draft.calculationMethod),
            'activities': [
              for (final activityId in draft.selectedActivityIds)
                {
                  'activityId': activityId,
                  if (draft.calculationMethod ==
                      GradeCompositionCalculationMethod.weightedAverage)
                    'weight': draft.weights[activityId],
                },
            ],
          },
      ];

      final saved = await ref.read(gradeCompositionsActionsProvider).upsert(
            query: query,
            evaluationModelId: modelId,
            groups: groups,
          );
      _initializedForKey = null;
      _calculation = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Composição salva · atualizada em ${_dateFormat.format(saved.updatedAt.toLocal())}',
            ),
          ),
        );
        setState(() {});
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _calculate(String compositionId) async {
    setState(() => _calculating = true);
    try {
      final result = await ref.read(gradeCompositionsActionsProvider).calculate(compositionId);
      if (mounted) setState(() => _calculation = result);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage)));
      }
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  /// Recuperação elevou a nota do item regular acima da média das atividades do grupo.
  bool _recoveryBoosted(GradeCompositionStudentGroupScore group) {
    if (group.isRecovery) return false;
    final considered = group.consideredScore;
    final converted = group.convertedScore;
    if (considered == null || converted == null) return false;
    return considered > converted;
  }

  /// Formato da célula: nota real do grupo; se a recuperação ajustar, `30 (59)`.
  String _displayGroupScore(GradeCompositionStudentGroupScore group) {
    if (group.isRecovery) {
      return group.convertedScore == null ? '—' : group.convertedScore!.toStringAsFixed(0);
    }

    final real = group.convertedScore;
    final adjusted = group.consideredScore ?? group.convertedScore;
    if (real == null && adjusted == null) return '—';
    if (real == null) return adjusted!.toStringAsFixed(0);
    if (adjusted == null || adjusted == real) return real.toStringAsFixed(0);
    return '${real.toStringAsFixed(0)} (${adjusted.toStringAsFixed(0)})';
  }

  void _openGroupDetailModal({
    required String studentName,
    required GradeCompositionStudentGroupScore group,
  }) {
    final displayed = _displayGroupScore(group);
    final methodLabel = group.calculationMethod == GradeCompositionCalculationMethod.weightedAverage
        ? 'Média ponderada'
        : 'Média simples';
    final boosted = _recoveryBoosted(group);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${group.itemName} · $studentName'),
        content: SizedBox(
          width: 480,
          child: group.activities.isEmpty
              ? const Text('Nenhuma atividade vinculada a este item.')
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nota na tabela: $displayed'
                        '${group.itemMaxScore > 0 ? ' / ${group.itemMaxScore.toStringAsFixed(0)}' : ''}'
                        ' · $methodLabel',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (boosted)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Fora dos parênteses: média das atividades deste item '
                            '(${group.convertedScore!.toStringAsFixed(0)}). '
                            'Entre parênteses: nota considerada com recuperação '
                            '(${group.consideredScore!.toStringAsFixed(0)}).',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      ...group.activities.map((activity) {
                        final scoreLabel = activity.score == null
                            ? 'Sem nota'
                            : '${activity.score!.toStringAsFixed(activity.score!.truncateToDouble() == activity.score! ? 0 : 1)}'
                                ' / ${activity.maxScore.toStringAsFixed(activity.maxScore.truncateToDouble() == activity.maxScore ? 0 : 1)}';
                        final description = activity.description?.trim();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          activity.title,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        scoreLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: activity.score == null
                                              ? Theme.of(context).colorScheme.outline
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (group.calculationMethod ==
                                          GradeCompositionCalculationMethod.weightedAverage &&
                                      activity.weight != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Peso: ${activity.weight}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                  if (description != null && description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        description,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _query(ref);
    final period = ref.watch(effectiveAssessmentPeriodProvider);
    final modelsAsync = ref.watch(evaluationModelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Composição da Nota'),
            Text(
              '${widget.disciplineName} · ${period?.name ?? 'Sem período'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: query == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Selecione um período avaliativo no AppBar para montar a composição.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : modelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (allModels) {
                final contextAsync = ref.watch(gradeCompositionContextProvider(query));
                return AsyncValueWidget<GradeCompositionContext>(
                  value: contextAsync,
                  onRetry: () => ref.invalidate(gradeCompositionContextProvider(query)),
                  data: (contextData) {
                    final activeModels = allModels.where((m) => m.isActive).toList();
                    final linkedModel = allModels
                        .where((m) => m.id == contextData.composition?.evaluationModelId)
                        .toList();
                    final selectable = [
                      ...activeModels,
                      for (final m in linkedModel)
                        if (!activeModels.any((a) => a.id == m.id)) m,
                    ];

                    _ensureDrafts(contextData, selectable.isEmpty ? allModels : selectable);

                    if (!_syncToastShown &&
                        (contextData.groupsAdded > 0 || contextData.groupsRemoved > 0)) {
                      _syncToastShown = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Modelo sincronizado: '
                              '+${contextData.groupsAdded} grupo(s), '
                              '-${contextData.groupsRemoved} removido(s).',
                            ),
                          ),
                        );
                      });
                    }

                    final drafts = _drafts ?? const <_GroupDraft>[];
                    final selectedIds = _selectedAcrossGroups();
                    final composition = contextData.composition;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        Text(
                          'Associe as atividades deste período aos itens do modelo avaliativo.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _selectedModelId != null &&
                                  selectable.any((m) => m.id == _selectedModelId)
                              ? _selectedModelId
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Modelo avaliativo',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final model in selectable)
                              DropdownMenuItem(
                                value: model.id,
                                child: Text(
                                  model.isActive ? model.name : '${model.name} (inativo)',
                                ),
                              ),
                          ],
                          onChanged: selectable.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedModelId = value;
                                    _initializedForKey = null;
                                    _calculation = null;
                                  });
                                },
                        ),
                        if (selectable.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Cadastre um modelo em Config → Modelos avaliativos.',
                          ),
                        ],
                        if (composition != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Última atualização: ${_dateFormat.format(composition.updatedAt.toLocal())}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 20),
                        ...drafts.map((draft) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    draft.isRecovery
                                        ? '${draft.itemName} · Recuperação (máx. ${draft.itemMaxScore.toStringAsFixed(1)})'
                                        : '${draft.itemName} (máx. ${draft.itemMaxScore.toStringAsFixed(1)})',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  SegmentedButton<GradeCompositionCalculationMethod>(
                                    segments: const [
                                      ButtonSegment(
                                        value: GradeCompositionCalculationMethod.simpleAverage,
                                        label: Text('Média simples'),
                                      ),
                                      ButtonSegment(
                                        value: GradeCompositionCalculationMethod.weightedAverage,
                                        label: Text('Ponderada'),
                                      ),
                                    ],
                                    selected: {draft.calculationMethod},
                                    onSelectionChanged: (value) {
                                      setState(() {
                                        draft.calculationMethod = value.first;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  if (contextData.eligibleActivities.isEmpty)
                                    const Text('Nenhuma atividade elegível neste período.')
                                  else
                                    ...contextData.eligibleActivities.map((activity) {
                                      final takenElsewhere = selectedIds.contains(activity.id) &&
                                          !draft.selectedActivityIds.contains(activity.id);
                                      final checked = draft.selectedActivityIds.contains(activity.id);
                                      return Column(
                                        children: [
                                          CheckboxListTile(
                                            dense: true,
                                            value: checked,
                                            onChanged: takenElsewhere
                                                ? null
                                                : (value) {
                                                    setState(() {
                                                      if (value == true) {
                                                        draft.selectedActivityIds.add(activity.id);
                                                        draft.weights.putIfAbsent(activity.id, () => 1);
                                                      } else {
                                                        draft.selectedActivityIds.remove(activity.id);
                                                        draft.weights.remove(activity.id);
                                                      }
                                                    });
                                                  },
                                            title: Text(activity.title),
                                            subtitle: Text(
                                              [
                                                if (activity.tag != null) activity.tag!,
                                                'Máx. ${activity.maxScore.toStringAsFixed(0)}',
                                                if (takenElsewhere) 'Já em outro grupo',
                                              ].join(' · '),
                                            ),
                                          ),
                                          if (checked &&
                                              draft.calculationMethod ==
                                                  GradeCompositionCalculationMethod
                                                      .weightedAverage)
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                              child: TextFormField(
                                                initialValue:
                                                    (draft.weights[activity.id] ?? 1).toString(),
                                                decoration: const InputDecoration(
                                                  labelText: 'Peso',
                                                  border: OutlineInputBorder(),
                                                  isDense: true,
                                                ),
                                                keyboardType: TextInputType.number,
                                                onChanged: (value) {
                                                  final parsed =
                                                      double.tryParse(value.replaceAll(',', '.'));
                                                  if (parsed != null) {
                                                    draft.weights[activity.id] = parsed;
                                                  }
                                                },
                                              ),
                                            ),
                                        ],
                                      );
                                    }),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _saving || _selectedModelId == null || drafts.isEmpty
                              ? null
                              : () => _save(query),
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_saving ? 'Salvando…' : 'Salvar composição'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: composition == null || _calculating
                              ? null
                              : () => _calculate(composition.id),
                          icon: _calculating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.calculate_outlined),
                          label: Text(_calculating ? 'Calculando…' : 'Calcular notas'),
                        ),
                        if (_calculation != null) ...[
                          const SizedBox(height: 24),
                          Text('Resultado', style: Theme.of(context).textTheme.titleLarge),
                          if (_calculation!.emptyGroupNames.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Grupos sem atividades: ${_calculation!.emptyGroupNames.join(', ')}',
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                          if (_calculation!.ungroupedActivityCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${_calculation!.ungroupedActivityCount} atividade(s) fora da composição.',
                              ),
                            ),
                          Builder(
                            builder: (context) {
                              final maxCount = _calculation!.students
                                  .where(_studentHasMaximumGrades)
                                  .length;
                              final visibleStudents = _onlyMaximumGrades
                                  ? _calculation!.students
                                      .where(_studentHasMaximumGrades)
                                      .toList()
                                  : _calculation!.students;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    value: _onlyMaximumGrades,
                                    onChanged: (value) {
                                      setState(() => _onlyMaximumGrades = value ?? false);
                                    },
                                    title: const Text('Somente alunos com nota máxima'),
                                    subtitle: Text(
                                      '$maxCount de ${_calculation!.students.length} com máxima nos itens regulares '
                                      '(considera a maior nota entre avaliação e recuperação).',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (visibleStudents.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Text(
                                        _onlyMaximumGrades
                                            ? 'Nenhum aluno com nota máxima nos itens já avaliados.'
                                            : 'Nenhum aluno na composição.',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    )
                                  else
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columns: [
                                          const DataColumn(label: Text('Aluno')),
                                          for (final group
                                              in (_calculation!.students.isNotEmpty
                                                  ? _calculation!.students.first.groups
                                                  : drafts.map(
                                                      (d) => GradeCompositionStudentGroupScore(
                                                        evaluationModelItemId:
                                                            d.evaluationModelItemId,
                                                        itemName: d.itemName,
                                                        itemMaxScore: d.itemMaxScore,
                                                        itemSortOrder: d.itemSortOrder,
                                                        calculationMethod: d.calculationMethod,
                                                      ),
                                                    )))
                                            DataColumn(label: Text(group.itemName)),
                                          const DataColumn(label: Text('Média final')),
                                        ],
                                        rows: [
                                          for (final student in visibleStudents)
                                            DataRow(
                                              cells: [
                                                DataCell(Text(student.studentName)),
                                                for (final group in student.groups)
                                                  DataCell(
                                                    onTap: () => _openGroupDetailModal(
                                                      studentName: student.studentName,
                                                      group: group,
                                                    ),
                                                    Text(
                                                      _displayGroupScore(group),
                                                      style: TextStyle(
                                                        color: Theme.of(context).colorScheme.primary,
                                                        decoration: TextDecoration.underline,
                                                        decorationColor: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(alpha: 0.4),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                DataCell(
                                                  Text(
                                                    student.finalAverage == null
                                                        ? '—'
                                                        : student.finalAverage!.toStringAsFixed(0),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}
