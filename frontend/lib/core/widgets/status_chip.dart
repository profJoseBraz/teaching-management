import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Chip colorido e compacto para representar status de domínio
/// (turma, aula, conteúdo, submissão, chamada, severidade).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  factory StatusChip.classStatus(String status) {
    switch (status) {
      case 'ACTIVE':
        return StatusChip(label: 'Ativa', color: AppSeverityColors.low);
      case 'ARCHIVED':
        return const StatusChip(label: 'Arquivada', color: Colors.grey);
      default:
        return StatusChip(label: status, color: Colors.grey);
    }
  }

  factory StatusChip.attendance(String? status) {
    switch (status) {
      case 'PRESENT':
        return StatusChip(label: 'Presente', color: AppSeverityColors.low);
      case 'ABSENT':
        return StatusChip(label: 'Falta', color: AppSeverityColors.high);
      case 'LATE':
        return StatusChip(label: 'Atraso', color: AppSeverityColors.medium);
      default:
        return const StatusChip(label: 'Sem registro', color: Colors.grey);
    }
  }

  factory StatusChip.contentStatus(String status) {
    switch (status) {
      case 'COMPLETED':
        return StatusChip(label: 'Concluído', color: AppSeverityColors.low);
      case 'IN_PROGRESS':
        return StatusChip(label: 'Em andamento', color: AppSeverityColors.medium);
      default:
        return StatusChip(label: status, color: Colors.grey);
    }
  }

  factory StatusChip.submissionStatus(String status) {
    switch (status) {
      case 'GRADED':
        return StatusChip(label: 'Avaliada', color: AppSeverityColors.low);
      case 'SUBMITTED':
        return StatusChip(label: 'Entregue', color: AppSeverityColors.medium);
      case 'PENDING':
        return StatusChip(label: 'Pendente', color: AppSeverityColors.high);
      default:
        return StatusChip(label: status, color: Colors.grey);
    }
  }

  factory StatusChip.severity(String severity) {
    final color = AppSeverityColors.forSeverity(severity);
    final label = switch (severity) {
      'high' => 'Alta',
      'medium' => 'Média',
      _ => 'Baixa',
    };
    return StatusChip(label: label, color: color);
  }

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
