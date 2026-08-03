import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/attendance_datasource.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'lessons_providers.dart';
import 'session_providers.dart';

final attendanceDatasourceProvider = Provider<AttendanceDatasource>(
  (ref) => AttendanceDatasource(ref.watch(apiClientProvider)),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepositoryImpl(ref.watch(attendanceDatasourceProvider)),
);

/// Controla a folha de chamada de uma aula: carrega, permite alternar o
/// status de cada aluno localmente e persiste tudo em lote ao salvar.
class AttendanceController extends StateNotifier<AsyncValue<AttendanceSheet>> {
  AttendanceController(this._ref, this.lessonId) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final String lessonId;

  AttendanceRepository get _repo => _ref.read(attendanceRepositoryProvider);

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getSheet(lessonId));
  }

  /// Atualiza o status de um aluno apenas localmente (sem chamar a API).
  void setStatus(String studentId, String status) {
    final sheet = state.valueOrNull;
    if (sheet == null) return;
    final updated = sheet.students
        .map((e) => e.studentId == studentId ? e.copyWith(status: status) : e)
        .toList();
    state = AsyncValue.data(
      AttendanceSheet(
        lessonId: sheet.lessonId,
        classId: sheet.classId,
        attendanceCompleted: sheet.attendanceCompleted,
        students: updated,
      ),
    );
  }

  Future<bool> save() async {
    final sheet = state.valueOrNull;
    if (sheet == null) return false;
    try {
      final saved = await _repo.saveAttendance(lessonId, sheet.students);
      state = AsyncValue.data(saved);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> complete({required String classId}) async {
    final saved = await save();
    if (!saved) return false;
    try {
      await _repo.completeAttendance(lessonId);
      await load();
      _ref.invalidate(lessonsListProvider);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  bool get allFilled => state.valueOrNull?.students.every((e) => e.status != null) ?? false;
}

final attendanceControllerProvider =
    StateNotifierProvider.family<AttendanceController, AsyncValue<AttendanceSheet>, String>(
  (ref, lessonId) => AttendanceController(ref, lessonId),
);
