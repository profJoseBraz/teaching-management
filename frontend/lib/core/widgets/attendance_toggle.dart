import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Alterna entre Presente / Falta / Atraso para um aluno na folha de chamada.
class AttendanceToggle extends StatelessWidget {
  const AttendanceToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Um de: 'PRESENT', 'ABSENT', 'LATE' ou null (sem registro).
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: 'PRESENT',
          label: Text('Presente'),
          icon: Icon(Icons.check_circle_outline_rounded, size: 18),
        ),
        ButtonSegment(
          value: 'LATE',
          label: Text('Atraso'),
          icon: Icon(Icons.schedule_rounded, size: 18),
        ),
        ButtonSegment(
          value: 'ABSENT',
          label: Text('Falta'),
          icon: Icon(Icons.cancel_outlined, size: 18),
        ),
      ],
      selected: value != null ? {value!} : <String>{},
      emptySelectionAllowed: true,
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) onChanged(selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide(color: _colorFor(value));
          }
          return null;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _colorFor(value);
          return null;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _colorFor(value).withValues(alpha: 0.12);
          }
          return null;
        }),
      ),
    );
  }

  Color _colorFor(String? status) {
    switch (status) {
      case 'PRESENT':
        return AppSeverityColors.low;
      case 'LATE':
        return AppSeverityColors.medium;
      case 'ABSENT':
        return AppSeverityColors.high;
      default:
        return Colors.grey;
    }
  }
}
