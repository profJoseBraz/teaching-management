import '../../domain/entities/agenda_note.dart';
import '../../domain/repositories/agenda_repository.dart';
import '../datasources/agenda_datasource.dart';

class AgendaRepositoryImpl implements AgendaRepository {
  AgendaRepositoryImpl(this._datasource);

  final AgendaDatasource _datasource;

  @override
  Future<List<AgendaNote>> list({
    DateTime? from,
    DateTime? to,
    String? search,
    bool? completed,
  }) =>
      _datasource.list(from: from, to: to, search: search, completed: completed);

  @override
  Future<AgendaNote> getById(String id) => _datasource.getById(id);

  @override
  Future<AgendaNote> create({
    required DateTime date,
    required String content,
    bool completed = false,
  }) =>
      _datasource.create(date: date, content: content, completed: completed);

  @override
  Future<AgendaNote> update(String id, {DateTime? date, String? content, bool? completed}) =>
      _datasource.update(id, date: date, content: content, completed: completed);

  @override
  Future<void> delete(String id) => _datasource.delete(id);
}
