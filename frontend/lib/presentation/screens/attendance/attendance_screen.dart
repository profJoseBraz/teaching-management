import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/attendance_toggle.dart';
import '../../../domain/entities/attendance.dart';
import '../../providers/attendance_providers.dart';

/// Folha de chamada de uma aula: alterna Presente/Falta/Atraso por aluno,
/// salva em lote e permite concluir a chamada.
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key, required this.classId, required this.lessonId});

  final String classId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetAsync = ref.watch(attendanceControllerProvider(lessonId));
    final controller = ref.read(attendanceControllerProvider(lessonId).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Chamada')),
      body: AsyncValueWidget<AttendanceSheet>(
        value: sheetAsync,
        onRetry: controller.load,
        isEmpty: (sheet) => sheet.students.isEmpty,
        emptyIcon: Icons.people_outline_rounded,
        emptyMessage: 'Nenhum aluno matriculado ativo nesta turma.',
        data: (sheet) {
          final filled = sheet.students.where((e) => e.status != null).length;
          return Column(
            children: [
              if (sheet.attendanceCompleted)
                Container(
                  width: double.infinity,
                  color: const Color(0xFF15803D).withValues(alpha: 0.12),
                  padding: const EdgeInsets.all(12),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: Color(0xFF15803D)),
                      SizedBox(width: 8),
                      Text('Chamada já concluída para esta aula.'),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '$filled de ${sheet.students.length} registrados',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _markAll(controller, sheet, 'PRESENT'),
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Marcar todos presentes'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: sheet.students.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = sheet.students[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(entry.studentName, style: const TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            AttendanceToggle(
                              value: entry.status,
                              onChanged: (status) => controller.setStatus(entry.studentId, status),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: sheetAsync.maybeWhen(
        data: (sheet) => Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _save(context, ref, controller),
                  child: const Text('Salvar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: sheet.attendanceCompleted ? null : () => _complete(context, ref, controller),
                  child: Text(sheet.attendanceCompleted ? 'Chamada concluída' : 'Concluir chamada'),
                ),
              ),
            ],
          ),
        ),
        orElse: () => null,
      ),
    );
  }

  void _markAll(AttendanceController controller, AttendanceSheet sheet, String status) {
    for (final entry in sheet.students) {
      controller.setStatus(entry.studentId, status);
    }
  }

  Future<void> _save(BuildContext context, WidgetRef ref, AttendanceController controller) async {
    final ok = await controller.save();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Chamada salva.' : 'Erro ao salvar chamada.')),
      );
    }
  }

  Future<void> _complete(BuildContext context, WidgetRef ref, AttendanceController controller) async {
    if (!controller.allFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registre o status de todos os alunos antes de concluir.')),
      );
      return;
    }
    final ok = await controller.complete(classId: classId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Chamada concluída.' : 'Erro ao concluir chamada.')),
      );
    }
  }
}
