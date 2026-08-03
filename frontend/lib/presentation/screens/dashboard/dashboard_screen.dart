import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/attention_card.dart';
import '../../../domain/entities/attention_item.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/session_providers.dart';

/// Mapeia o tipo do AttentionItem para a aba da turma mais relevante.
int _tabIndexFor(String type) {
  switch (type) {
    case 'LESSONS_WITHOUT_ATTENDANCE':
      return 1; // Frequência
    case 'CONTENTS_IN_PROGRESS':
      return 2; // Conteúdos
    case 'OVERDUE_UNGRADED_ACTIVITIES':
    case 'ACTIVITIES_AWAITING_GRADE':
    case 'ACTIVITIES_WITHOUT_SCORE':
    case 'STUDENTS_PENDING_SUBMISSION':
    case 'ABSENT_ON_ACTIVITY_LESSON':
      return 3; // Atividades
    case 'EXCESS_ABSENCES':
      return 4; // Alunos
    default:
      return 0; // Aulas
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(authNotifierProvider).user;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardProvider),
      child: AsyncValueWidget<DashboardResponse>(
        value: dashboardAsync,
        onRetry: () => ref.invalidate(dashboardProvider),
        isEmpty: (data) => data.attentionItems.isEmpty,
        emptyIcon: Icons.check_circle_outline_rounded,
        emptyMessage: 'Nenhuma pendência no momento. Tudo em dia! 🎉',
        data: (dashboard) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Olá, ${user.name.split(' ').first}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            _SummaryRow(summary: dashboard.summary),
            const SizedBox(height: 20),
            Text('Pendências', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...dashboard.attentionItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AttentionCard(
                  title: item.title,
                  message: item.message,
                  count: item.count,
                  severity: item.severity,
                  onTap: () => _onTapItem(context, item),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTapItem(BuildContext context, AttentionItem item) {
    final classId = item.filters['classId'] as String?;
    if (classId != null) {
      context.go(AppRoutes.classDetail(classId), extra: _tabIndexFor(item.type));
    } else {
      context.go(AppRoutes.reports);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total', summary.totalAttentionItems, Theme.of(context).colorScheme.primary),
      ('Alta', summary.bySeverity['high'] ?? 0, const Color(0xFFB91C1C)),
      ('Média', summary.bySeverity['medium'] ?? 0, const Color(0xFFB45309)),
      ('Baixa', summary.bySeverity['low'] ?? 0, const Color(0xFF15803D)),
    ];
    return Row(
      children: items
          .map(
            (e) => Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Column(
                    children: [
                      Text('${e.$2}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: e.$3)),
                      const SizedBox(height: 4),
                      Text(e.$1, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          )
          .expand((w) => [w, const SizedBox(width: 8)])
          .take(items.length * 2 - 1)
          .toList(),
    );
  }
}
