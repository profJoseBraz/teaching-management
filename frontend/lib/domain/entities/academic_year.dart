class AcademicYear {
  const AcademicYear({
    required this.id,
    required this.year,
    this.label,
    required this.isCurrent,
    this.startsOn,
    this.endsOn,
  });

  final String id;
  final int year;
  final String? label;
  final bool isCurrent;
  final DateTime? startsOn;
  final DateTime? endsOn;

  String get displayName => label?.isNotEmpty == true ? label! : '$year';

  AcademicYear copyWith({bool? isCurrent}) => AcademicYear(
        id: id,
        year: year,
        label: label,
        isCurrent: isCurrent ?? this.isCurrent,
        startsOn: startsOn,
        endsOn: endsOn,
      );
}
