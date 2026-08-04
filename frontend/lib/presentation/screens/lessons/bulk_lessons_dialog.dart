import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/school_class.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');
final _monthFormat = DateFormat('MMMM yyyy', 'pt_BR');

enum _BulkMode { period, days }

/// Resultado confirmado do diálogo de cadastro prévio de aulas.
typedef BulkLessonsDraft = ({
  String disciplineId,
  List<DateTime> dates,
  String startTime,
  String endTime,
  String? observations,
});

/// Cadastro em lote: por intervalo + dias da semana, ou por dias avulsos no calendário.
class BulkLessonsDialog extends StatefulWidget {
  const BulkLessonsDialog({super.key, required this.disciplines});

  final List<ClassDisciplineRef> disciplines;

  @override
  State<BulkLessonsDialog> createState() => _BulkLessonsDialogState();
}

class _BulkLessonsDialogState extends State<BulkLessonsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _startController = TextEditingController(text: '08:00');
  final _endController = TextEditingController(text: '09:40');
  final _observationsController = TextEditingController();

  late String _disciplineId;
  _BulkMode _mode = _BulkMode.period;

  DateTime _periodFrom = DateTime.now();
  DateTime _periodTo = DateTime.now().add(const Duration(days: 30));
  /// DateTime.monday=1 … sunday=7. Padrão: seg–sex.
  final Set<int> _weekdays = {1, 2, 3, 4, 5};

  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final Set<DateTime> _selectedDays = {};

  static const _weekdayLabels = <int, String>{
    1: 'Seg',
    2: 'Ter',
    3: 'Qua',
    4: 'Qui',
    5: 'Sex',
    6: 'Sáb',
    7: 'Dom',
  };

  @override
  void initState() {
    super.initState();
    _disciplineId = widget.disciplines.first.id;
    _periodFrom = DateTime(_periodFrom.year, _periodFrom.month, _periodFrom.day);
    _periodTo = DateTime(_periodTo.year, _periodTo.month, _periodTo.day);
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DateTime> _resolveDates() {
    if (_mode == _BulkMode.days) {
      final list = _selectedDays.map(_dateOnly).toList()..sort();
      return list;
    }

    if (_weekdays.isEmpty) return const [];
    if (_periodTo.isBefore(_periodFrom)) return const [];

    final dates = <DateTime>[];
    var cursor = _periodFrom;
    while (!cursor.isAfter(_periodTo)) {
      if (_weekdays.contains(cursor.weekday)) {
        dates.add(cursor);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return dates;
  }

  Future<void> _pickPeriodDate({required bool isFrom}) async {
    final initial = isFrom ? _periodFrom : _periodTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      final value = _dateOnly(picked);
      if (isFrom) {
        _periodFrom = value;
        if (_periodTo.isBefore(_periodFrom)) _periodTo = _periodFrom;
      } else {
        _periodTo = value;
        if (_periodTo.isBefore(_periodFrom)) _periodFrom = _periodTo;
      }
    });
  }

  void _toggleDay(DateTime day) {
    final key = _dateOnly(day);
    setState(() {
      if (_selectedDays.any((d) => d == key)) {
        _selectedDays.removeWhere((d) => d == key);
      } else {
        _selectedDays.add(key);
      }
    });
  }

  bool _isSelected(DateTime day) {
    final key = _dateOnly(day);
    return _selectedDays.any((d) => d == key);
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    final dates = _resolveDates();
    if (dates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == _BulkMode.period
                ? 'Ajuste o período e os dias da semana para gerar ao menos uma aula.'
                : 'Selecione ao menos um dia no calendário.',
          ),
        ),
      );
      return;
    }
    if (dates.length > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo de 200 aulas por lote (selecionou ${dates.length}).')),
      );
      return;
    }

    Navigator.pop(context, (
      disciplineId: _disciplineId,
      dates: dates,
      startTime: _startController.text.trim(),
      endTime: _endController.text.trim(),
      observations: _observationsController.text.trim().isEmpty
          ? null
          : _observationsController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dates = _resolveDates();
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Cadastrar várias aulas'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _disciplineId,
                  decoration: const InputDecoration(labelText: 'Disciplina'),
                  items: widget.disciplines
                      .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _disciplineId = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startController,
                        decoration: const InputDecoration(labelText: 'Início (HH:mm)'),
                        validator: (v) =>
                            (v == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) ? 'HH:mm' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endController,
                        decoration: const InputDecoration(labelText: 'Fim (HH:mm)'),
                        validator: (v) =>
                            (v == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) ? 'HH:mm' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observationsController,
                  decoration: const InputDecoration(labelText: 'Observações (opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SegmentedButton<_BulkMode>(
                  segments: const [
                    ButtonSegment(
                      value: _BulkMode.period,
                      label: Text('Período'),
                      icon: Icon(Icons.date_range_outlined),
                    ),
                    ButtonSegment(
                      value: _BulkMode.days,
                      label: Text('Dias avulsos'),
                      icon: Icon(Icons.event_available_outlined),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (value) => setState(() => _mode = value.first),
                ),
                const SizedBox(height: 16),
                if (_mode == _BulkMode.period) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('De'),
                    subtitle: Text(_dateFormat.format(_periodFrom)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () => _pickPeriodDate(isFrom: true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Até'),
                    subtitle: Text(_dateFormat.format(_periodTo)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () => _pickPeriodDate(isFrom: false),
                  ),
                  const SizedBox(height: 8),
                  Text('Dias da semana', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _weekdayLabels.entries.map((entry) {
                      final selected = _weekdays.contains(entry.key);
                      return FilterChip(
                        label: Text(entry.value),
                        selected: selected,
                        onSelected: (checked) => setState(() {
                          if (checked) {
                            _weekdays.add(entry.key);
                          } else {
                            _weekdays.remove(entry.key);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  Text(
                    'Toque nos dias do calendário para selecionar (podem ser não sequenciais).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _MonthMultiSelectCalendar(
                    month: _calendarMonth,
                    isSelected: _isSelected,
                    onToggle: _toggleDay,
                    onMonthChanged: (month) => setState(() => _calendarMonth = month),
                  ),
                  if (_selectedDays.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (_selectedDays.toList()..sort())
                          .map(
                            (d) => InputChip(
                              label: Text(_dateFormat.format(d)),
                              onDeleted: () => _toggleDay(d),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Text(
                  dates.isEmpty
                      ? 'Nenhuma aula será gerada com a seleção atual.'
                      : '${dates.length} aula(s) serão cadastradas.',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: dates.isEmpty ? colorScheme.error : colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.playlist_add_check_rounded),
          label: Text(dates.isEmpty ? 'Cadastrar' : 'Cadastrar (${dates.length})'),
        ),
      ],
    );
  }
}

class _MonthMultiSelectCalendar extends StatelessWidget {
  const _MonthMultiSelectCalendar({
    required this.month,
    required this.isSelected,
    required this.onToggle,
    required this.onMonthChanged,
  });

  final DateTime month;
  final bool Function(DateTime day) isSelected;
  final ValueChanged<DateTime> onToggle;
  final ValueChanged<DateTime> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first grid (DateTime.weekday: Mon=1 … Sun=7).
    final leadingEmpty = firstOfMonth.weekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Mês anterior',
              onPressed: () => onMonthChanged(DateTime(month.year, month.month - 1)),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                _monthFormat.format(firstOfMonth),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: 'Próximo mês',
              onPressed: () => onMonthChanged(DateTime(month.year, month.month + 1)),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        Row(
          children: const ['S', 'T', 'Q', 'Q', 'S', 'S', 'D']
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < rows; row++)
          Row(
            children: List.generate(7, (col) {
              final index = row * 7 + col;
              final dayNumber = index - leadingEmpty + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }
              final day = DateTime(month.year, month.month, dayNumber);
              final selected = isSelected(day);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Material(
                    color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onToggle(day),
                      child: SizedBox(
                        height: 40,
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}
