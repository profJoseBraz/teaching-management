import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/agenda_datasource.dart';
import '../../data/repositories/agenda_repository_impl.dart';
import '../../domain/entities/agenda_note.dart';
import '../../domain/repositories/agenda_repository.dart';
import 'session_providers.dart';

final agendaDatasourceProvider = Provider<AgendaDatasource>(
  (ref) => AgendaDatasource(ref.watch(apiClientProvider)),
);

final agendaRepositoryProvider = Provider<AgendaRepository>(
  (ref) => AgendaRepositoryImpl(ref.watch(agendaDatasourceProvider)),
);

final agendaSearchQueryProvider = StateProvider<String>((ref) => '');

/// Dia civil selecionado no filtro (`null` = sem filtro de data).
final agendaDateFilterProvider = StateProvider<DateTime?>((ref) => null);

/// Padrão: não concluídas — facilita o controle do que ainda falta.
final agendaCompletionFilterProvider =
    StateProvider<AgendaCompletionFilter>((ref) => AgendaCompletionFilter.pending);

final agendaNotesProvider = FutureProvider<List<AgendaNote>>((ref) {
  final search = ref.watch(agendaSearchQueryProvider);
  final dateFilter = ref.watch(agendaDateFilterProvider);
  final completion = ref.watch(agendaCompletionFilterProvider);
  final bool? completed = switch (completion) {
    AgendaCompletionFilter.all => null,
    AgendaCompletionFilter.pending => false,
    AgendaCompletionFilter.completed => true,
  };

  return ref.watch(agendaRepositoryProvider).list(
        from: dateFilter,
        to: dateFilter,
        search: search.isEmpty ? null : search,
        completed: completed,
      );
});

final agendaActionsProvider = Provider<AgendaActions>((ref) => AgendaActions(ref));

class AgendaActions {
  AgendaActions(this._ref);

  final Ref _ref;

  AgendaRepository get _repo => _ref.read(agendaRepositoryProvider);

  Future<AgendaNote> create({
    required DateTime date,
    required String content,
    bool completed = false,
  }) async {
    final note = await _repo.create(date: date, content: content, completed: completed);
    _ref.invalidate(agendaNotesProvider);
    return note;
  }

  Future<AgendaNote> update(
    String id, {
    DateTime? date,
    String? content,
    bool? completed,
  }) async {
    final note = await _repo.update(id, date: date, content: content, completed: completed);
    _ref.invalidate(agendaNotesProvider);
    return note;
  }

  Future<void> setCompleted(String id, bool completed) async {
    await _repo.update(id, completed: completed);
    _ref.invalidate(agendaNotesProvider);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _ref.invalidate(agendaNotesProvider);
  }
}
