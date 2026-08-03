class Student {
  const Student({
    required this.id,
    required this.name,
    this.registryCode,
    this.email,
    this.phone,
    this.notes,
  });

  final String id;
  final String name;
  final String? registryCode;
  final String? email;
  final String? phone;
  final String? notes;
}
