class ReportResult {
  const ReportResult({
    required this.reportType,
    required this.filters,
    required this.generatedAt,
    required this.rows,
    required this.totalRows,
  });

  final String reportType;
  final Map<String, dynamic> filters;
  final DateTime generatedAt;
  final List<Map<String, dynamic>> rows;
  final int totalRows;

  /// Colunas inferidas a partir das chaves da primeira linha, preservando a
  /// ordem de inserção retornada pela API.
  List<String> get columns => rows.isEmpty ? const [] : rows.first.keys.toList();
}
