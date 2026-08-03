import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/entities/report_result.dart';
import '../../providers/academic_providers.dart';
import '../../providers/classes_providers.dart';
import '../../providers/reports_providers.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

/// Tela de relatórios: escolha do tipo + filtros, execução sob demanda e
/// visualização tabular do resultado.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _reportType = kReportTypes.first.$1;
  String? _classId;
  DateTime? _from;
  DateTime? _to;
  final _thresholdController = TextEditingController(text: '5');

  bool get _usesThreshold => _reportType == 'excess-absences';

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesListProvider);
    final resultState = ref.watch(reportsControllerProvider);
    final effectiveYearId = ref.watch(effectiveAcademicYearIdProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filtros', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _reportType,
                      decoration: const InputDecoration(labelText: 'Tipo de relatório'),
                      isExpanded: true,
                      items: kReportTypes
                          .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                          .toList(),
                      onChanged: (value) => setState(() => _reportType = value!),
                    ),
                    const SizedBox(height: 12),
                    classesAsync.when(
                      data: (classes) => DropdownButtonFormField<String?>(
                        initialValue: _classId,
                        decoration: const InputDecoration(labelText: 'Turma (opcional)'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todas as turmas')),
                          ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (value) => setState(() => _classId = value),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _from ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setState(() => _from = picked);
                            },
                            child: Text(_from == null ? 'De (opcional)' : _dateFormat.format(_from!)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _to ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setState(() => _to = picked);
                            },
                            child: Text(_to == null ? 'Até (opcional)' : _dateFormat.format(_to!)),
                          ),
                        ),
                      ],
                    ),
                    if (_usesThreshold) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _thresholdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Limite mínimo de faltas'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.read(reportsControllerProvider.notifier).run(
                            _reportType,
                            academicYearId: effectiveYearId,
                            classId: _classId,
                            from: _from,
                            to: _to,
                            threshold: _usesThreshold ? int.tryParse(_thresholdController.text) : null,
                          ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Executar relatório'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _ResultView(state: resultState)),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state});

  final AsyncValue<ReportResult>? state;

  @override
  Widget build(BuildContext context) {
    if (state == null) {
      return const EmptyState(
        icon: Icons.bar_chart_outlined,
        message: 'Escolha um relatório e toque em "Executar relatório".',
      );
    }
    return state!.when(
      loading: () => const LoadingState(message: 'Gerando relatório…'),
      error: (error, _) => ErrorState(
        message: error is AppException ? error.message : 'Erro ao gerar relatório.',
      ),
      data: (result) {
        if (result.rows.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            message: 'Nenhum registro encontrado para os filtros selecionados.',
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: result.columns.map((c) => DataColumn(label: Text(c))).toList(),
                  rows: result.rows
                      .map(
                        (row) => DataRow(
                          cells: result.columns.map((c) => DataCell(Text('${row[c] ?? '—'}'))).toList(),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
