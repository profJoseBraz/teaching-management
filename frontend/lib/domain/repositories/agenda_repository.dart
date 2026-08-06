import '../entities/agenda_note.dart';

abstract class AgendaRepository {
  Future<List<AgendaNote>> list({
    DateTime? from,
    DateTime? to,
    String? search,
    bool? completed,
  });
  Future<AgendaNote> getById(String id);
  Future<AgendaNote> create({
    required DateTime date,
    required String content,
    bool completed = false,
  });
  Future<AgendaNote> update(String id, {DateTime? date, String? content, bool? completed});
  Future<void> delete(String id);
}
