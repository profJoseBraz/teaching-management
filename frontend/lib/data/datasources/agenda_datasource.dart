import '../../core/network/api_client.dart';
import '../../domain/entities/agenda_note.dart';

AgendaNote agendaNoteFromJson(Map<String, dynamic> json) => AgendaNote(
      id: json['id'] as String,
      date: _parseDateOnly(json['date'] as String),
      content: json['content'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

/// Interpreta YYYY-MM-DD (ou ISO com meia-noite UTC) como data civil local,
/// evitando deslocar o dia por fuso horário.
DateTime _parseDateOnly(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
  if (match == null) return DateTime.parse(value);
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class AgendaDatasource {
  AgendaDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AgendaNote>> list({
    DateTime? from,
    DateTime? to,
    String? search,
    bool? completed,
  }) async {
    final response = await _apiClient.get(
      '/agenda-notes',
      query: {
        if (from != null) 'from': _formatDate(from),
        if (to != null) 'to': _formatDate(to),
        if (search != null && search.isNotEmpty) 'search': search,
        if (completed != null) 'completed': completed.toString(),
      },
    );
    return (response['data'] as List)
        .map((e) => agendaNoteFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AgendaNote> getById(String id) async {
    final response = await _apiClient.get('/agenda-notes/$id');
    return agendaNoteFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AgendaNote> create({
    required DateTime date,
    required String content,
    bool completed = false,
  }) async {
    final response = await _apiClient.post('/agenda-notes', data: {
      'date': _formatDate(date),
      'content': content,
      'completed': completed,
    });
    return agendaNoteFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AgendaNote> update(String id, {DateTime? date, String? content, bool? completed}) async {
    final response = await _apiClient.patch('/agenda-notes/$id', data: {
      if (date != null) 'date': _formatDate(date),
      'content': ?content,
      if (completed != null) 'completed': completed,
    });
    return agendaNoteFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _apiClient.delete('/agenda-notes/$id');
}
