import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/reports_datasource.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/entities/report_result.dart';
import '../../domain/repositories/reports_repository.dart';
import 'session_providers.dart';

final reportsDatasourceProvider = Provider<ReportsDatasource>(
  (ref) => ReportsDatasource(ref.watch(apiClientProvider)),
);

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(ref.watch(reportsDatasourceProvider)),
);

/// Catálogo de relatórios disponíveis (rótulo em PT-BR + tipo da API).
const kReportTypes = <(String type, String label)>[
  ('excess-absences', 'Excesso de faltas'),
  ('pending-activities', 'Entregas pendentes'),
  ('ungraded-activities', 'Atividades vencidas sem correção'),
  ('contents-in-progress', 'Conteúdos em andamento'),
  ('lessons-without-attendance', 'Aulas sem chamada'),
  ('absence-vs-non-submission', 'Falta x não entrega'),
  ('attendance-percentage', '% de presença por aluno'),
  ('class-average', 'Média da turma'),
  ('grades-by-student', 'Notas por aluno'),
  ('attendance-by-student', 'Presença por aluno'),
  ('submission-status', 'Status das entregas'),
  ('lessons-taught', 'Aulas ministradas'),
  ('students-without-grade', 'Alunos sem nota'),
  ('average-by-activity', 'Média por atividade'),
];

/// Controla a execução de relatórios sob demanda (o usuário escolhe o tipo
/// e os filtros, depois aciona "Executar").
class ReportsController extends StateNotifier<AsyncValue<ReportResult>?> {
  ReportsController(this._ref) : super(null);

  final Ref _ref;

  Future<void> run(
    String reportType, {
    String? academicYearId,
    String? courseId,
    String? disciplineId,
    String? classId,
    String? assessmentPeriodId,
    DateTime? from,
    DateTime? to,
    int? threshold,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(reportsRepositoryProvider).runReport(
            reportType,
            academicYearId: academicYearId,
            courseId: courseId,
            disciplineId: disciplineId,
            classId: classId,
            assessmentPeriodId: assessmentPeriodId,
            from: from,
            to: to,
            threshold: threshold,
          ),
    );
  }

  void clear() => state = null;
}

final reportsControllerProvider = StateNotifierProvider<ReportsController, AsyncValue<ReportResult>?>(
  (ref) => ReportsController(ref),
);
