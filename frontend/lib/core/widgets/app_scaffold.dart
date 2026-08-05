import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/academic_providers.dart';
import '../../presentation/providers/activities_providers.dart';
import '../../presentation/providers/classes_providers.dart';
import '../../presentation/providers/contents_providers.dart';
import '../../presentation/providers/dashboard_providers.dart';
import '../../presentation/providers/lessons_providers.dart';
import '../../presentation/providers/reports_providers.dart';
import '../../presentation/providers/session_providers.dart';
import '../../presentation/providers/students_providers.dart';

/// Largura mínima a partir da qual usamos [NavigationRail] em vez de
/// [NavigationBar] (breakpoint padrão Material 3 para telas médias/largas).
const double kWideLayoutBreakpoint = 840;

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination('Dashboard', Icons.space_dashboard_outlined, Icons.space_dashboard),
  _Destination('Turmas', Icons.school_outlined, Icons.school),
  _Destination('Alunos', Icons.people_outline_rounded, Icons.people_rounded),
  _Destination('Relatórios', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
  _Destination('Config', Icons.settings_outlined, Icons.settings_rounded),
];

/// Casca (shell) principal do app autenticado: navegação lateral (telas
/// largas) ou inferior (telas estreitas), AppBar com seletor de ano letivo e
/// menu do usuário.
class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= kWideLayoutBreakpoint;

    final body = navigationShell;

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[navigationShell.currentIndex].label),
        actions: [
          const _AcademicYearSelector(),
          const SizedBox(width: 8),
          _UserMenu(),
          const SizedBox(width: 8),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) => _onTap(ref, index),
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _onTap(ref, index),
              destinations: _destinations
                  .map(
                    (d) => NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  /// Ao escolher um destino do shell, invalida os providers daquela área para
  /// forçar um novo GET (o [StatefulShellRoute] mantém o estado das abas).
  void _onTap(WidgetRef ref, int index) {
    _invalidateBranchProviders(ref, index);
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

void _invalidateBranchProviders(WidgetRef ref, int index) {
  switch (index) {
    case 0:
      ref.invalidate(dashboardProvider);
    case 1:
      ref.invalidate(classesListProvider);
      ref.invalidate(coursesProvider);
      ref.invalidate(disciplinesProvider);
      ref.invalidate(classDetailProvider);
      ref.invalidate(enrollmentsProvider);
      ref.invalidate(classDisciplinesProvider);
      ref.invalidate(lessonsListProvider);
      ref.invalidate(lessonDetailProvider);
      ref.invalidate(contentsListProvider);
      ref.invalidate(activitiesListProvider);
      // Não invalida activityDetailProvider: cada detalhe visitado geraria um GET
      // e, com várias turmas/atividades em cache, estoura o rate limit da API.
    case 2:
      ref.invalidate(studentsListProvider);
      ref.invalidate(studentDetailProvider);
    case 3:
      ref.invalidate(classesListProvider);
      ref.invalidate(coursesProvider);
      ref.invalidate(disciplinesProvider);
      ref.read(reportsControllerProvider.notifier).clear();
    case 4:
      ref.invalidate(academicYearsProvider);
      ref.invalidate(coursesProvider);
      ref.invalidate(disciplinesProvider);
      ref.invalidate(courseDisciplinesProvider);
      ref.invalidate(assessmentPeriodsProvider);
    default:
      break;
  }
}

class _AcademicYearSelector extends ConsumerWidget {
  const _AcademicYearSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(academicYearsProvider);
    final effectiveYear = ref.watch(effectiveAcademicYearProvider);

    return yearsAsync.when(
      data: (years) {
        if (years.isEmpty) return const SizedBox.shrink();
        return PopupMenuButton<String>(
          tooltip: 'Selecionar ano letivo',
          initialValue: effectiveYear?.id,
          onSelected: (id) => ref.read(selectedAcademicYearIdProvider.notifier).select(id),
          itemBuilder: (context) => years
              .map(
                (year) => PopupMenuItem(
                  value: year.id,
                  child: Row(
                    children: [
                      if (year.isCurrent)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                        ),
                      Text(year.displayName),
                    ],
                  ),
                ),
              )
              .toList(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_outlined, size: 20),
                const SizedBox(width: 6),
                Text(effectiveYear?.displayName ?? '—'),
                const Icon(Icons.arrow_drop_down_rounded),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(width: 24, height: 24, child: Padding(
        padding: EdgeInsets.all(4),
        child: CircularProgressIndicator(strokeWidth: 2),
      )),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _UserMenu extends ConsumerWidget {
  const _UserMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    return PopupMenuButton<String>(
      tooltip: 'Conta',
      onSelected: (value) {
        if (value == 'logout') {
          ref.read(authNotifierProvider.notifier).logout();
        }
      },
      itemBuilder: (context) => [
        if (user != null)
          PopupMenuItem(enabled: false, child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold))),
        const PopupMenuItem(value: 'logout', child: Text('Sair')),
      ],
      child: CircleAvatar(
        radius: 16,
        child: Text(
          (user?.name.isNotEmpty == true ? user!.name[0] : '?').toUpperCase(),
        ),
      ),
    );
  }
}
