class DiseaseModel {
  final String id;
  final String? mongoId;
  final String name;
  final String englishName;
  final String? category;
  final String description;
  final String? sourceName;
  final bool isCustom;
  final String? patientId;
  final String? doctorId;

  const DiseaseModel({
    required this.id,
    this.mongoId,
    required this.name,
    this.englishName = '',
    this.category,
    this.description = '',
    this.sourceName,
    this.isCustom = false,
    this.patientId,
    this.doctorId,
  });

  /// Null-safe display label:
  /// Returns "Disease Name (Category)" when category is non-null and non-empty,
  /// otherwise returns "Disease Name".
  String get displayLabel {
    final cat = category?.trim();
    if (cat != null && cat.isNotEmpty) {
      return '$name ($cat)';
    }
    return name;
  }

  DiseaseModel copyWith({
    String? id,
    String? mongoId,
    String? name,
    String? englishName,
    String? category,
    String? description,
    String? sourceName,
    bool? isCustom,
    String? patientId,
    String? doctorId,
  }) {
    return DiseaseModel(
      id: id ?? this.id,
      mongoId: mongoId ?? this.mongoId,
      name: name ?? this.name,
      englishName: englishName ?? this.englishName,
      category: category ?? this.category,
      description: description ?? this.description,
      sourceName: sourceName ?? this.sourceName,
      isCustom: isCustom ?? this.isCustom,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
    );
  }

  static String slugify(String name) {
    final clean = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return clean.isEmpty ? '' : 'dis_$clean';
  }

  factory DiseaseModel.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] as String?) ??
        (json['diseaseId'] as String?) ??
        (json['slug'] as String?) ??
        (json['code'] as String?);
    final mongoId = json['_id'] as String?;
    final name = (json['name'] as String?) ?? '';

    final isCustom = (json['isCustom'] as bool?) ??
        (rawId?.startsWith('custom_') ?? false);

    // If rawId is missing or is just a 24-hex mongoId, generate slug from name
    final isMongoHex =
        rawId != null && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(rawId);
    final id = (rawId != null && rawId.isNotEmpty && !isMongoHex)
        ? rawId
        : (name.isNotEmpty ? slugify(name) : (mongoId ?? ''));

    return DiseaseModel(
      id: id,
      mongoId: mongoId,
      name: name,
      englishName: (json['englishName'] as String?) ?? '',
      category: json['category'] as String?,
      description: (json['description'] as String?) ?? '',
      sourceName: json['sourceName'] as String?,
      isCustom: isCustom,
      patientId: json['patientId'] as String?,
      doctorId: json['doctorId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (mongoId != null) '_id': mongoId,
      'name': name,
      'englishName': englishName,
      'category': category,
      'description': description,
      if (sourceName != null) 'sourceName': sourceName,
      if (isCustom) 'isCustom': isCustom,
      if (patientId != null) 'patientId': patientId,
      if (doctorId != null) 'doctorId': doctorId,
    };
  }

  @override
  String toString() => name;
}
