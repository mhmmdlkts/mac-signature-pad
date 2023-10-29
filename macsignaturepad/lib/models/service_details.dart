class ServiceDetails {
  int? status;
  String? notes;
  String name;
  String code;

  ServiceDetails({
    required this.code,
    required this.name,
    this.status,
    this.notes,
  });

  factory ServiceDetails.fromJson(Map<String, dynamic> json) {
    return ServiceDetails(
      code: json['code'],
      name: json['name'],
      status: json['status'],
      notes: json['notes'],
    );
  }

  String get getNotes {
    if (notes == null || notes!.isEmpty) {
      switch (status) {
        case 0:
          return 'Neuerlicher Termin gewünscht';
        case 1:
          return 'Nicht gewünscht';
        case 2:
          return 'Zurzeit kein Interesse';
        default:
          return '';
      }
    }

    return notes!;
  }

  toJson() => {
    'code': code,
    'name': name,
    'status': status,
    'notes': notes,
  };
}