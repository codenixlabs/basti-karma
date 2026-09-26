class PaschataKarmaModel {
  final String? id;
  final String? patientId;
  final String niruhaVyapada;
  final String anuvasanaVyapada;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaschataKarmaModel({
    this.id,
    this.patientId,
    required this.niruhaVyapada,
    required this.anuvasanaVyapada,
    this.createdAt,
    this.updatedAt,
  });

  // ── Mappings: UI String <-> Backend camelCase Enum ──────────────────────

  static const Map<String, String> niruhaLabelToEnumMap = {
    'None observed': 'none',
    'Ayoga (under-action)': 'ayoga',
    'Atiyoga (over-action)': 'atiyoga',
    'Klama (mental fatigue)': 'klama',
    'Adhmana (flatulence)': 'adhmana',
    'Hikka (hiccup)': 'hikka',
    'Hadprapti': 'hadprapti',
    'Udavarta': 'udavarta',
    'Pravahika': 'pravahika',
    'Shiro Arti (headache)': 'shiroArti',
    'Anga Arti (body pain)': 'angaArti',
    'Parikartika (rectal pain)': 'parikartika',
    'Parisrava (rectal discharge)': 'parisrava',
  };

  static final Map<String, String> niruhaEnumToLabelMap = {
    for (final entry in niruhaLabelToEnumMap.entries) entry.value: entry.key,
  };

  static const Map<String, String> anuvasanLabelToEnumMap = {
    'None observed': 'none',
    'Vatavruta Sneha': 'vatavrutaSneha',
    'Pittavruta Sneha': 'pittavrutaSneha',
    'Kaphavruta Sneha': 'kaphavrutaSneha',
    'Anna Vruta Sneha': 'annaVrutaSneha',
    'Purisha Vruta Sneha': 'purishaVrutaSneha',
    'Abhukta Pranita': 'abhuktaPranita',
  };

  static final Map<String, String> anuvasanEnumToLabelMap = {
    for (final entry in anuvasanLabelToEnumMap.entries) entry.value: entry.key,
  };

  static String niruhaLabelToEnum(String? uiLabel) {
    if (uiLabel == null || uiLabel.isEmpty) return 'none';
    return niruhaLabelToEnumMap[uiLabel] ?? 'none';
  }

  static String niruhaEnumToLabel(String? backendEnum) {
    if (backendEnum == null || backendEnum.isEmpty) return 'None observed';
    return niruhaEnumToLabelMap[backendEnum] ?? 'None observed';
  }

  static String anuvasanaLabelToEnum(String? uiLabel) {
    if (uiLabel == null || uiLabel.isEmpty) return 'none';
    return anuvasanLabelToEnumMap[uiLabel] ?? 'none';
  }

  static String anuvasanaEnumToLabel(String? backendEnum) {
    if (backendEnum == null || backendEnum.isEmpty) return 'None observed';
    return anuvasanEnumToLabelMap[backendEnum] ?? 'None observed';
  }

  String get niruhaUiLabel => niruhaEnumToLabel(niruhaVyapada);
  String get anuvasanaUiLabel => anuvasanaEnumToLabel(anuvasanaVyapada);

  factory PaschataKarmaModel.fromJson(Map<String, dynamic> json) {
    final vyapada = json['vyapadaAndManagement'] as Map<String, dynamic>? ?? {};
    final rawPatientId = json['patientId'];
    String? patientId;
    if (rawPatientId is Map) {
      patientId = (rawPatientId['_id'] ?? rawPatientId['id'])?.toString();
    } else if (rawPatientId != null) {
      patientId = rawPatientId.toString();
    }
    return PaschataKarmaModel(
      id: json['_id'] as String?,
      patientId: patientId,
      niruhaVyapada: (vyapada['niruhaVyapada'] as String?) ?? 'none',
      anuvasanaVyapada: (vyapada['anuvasanaVyapada'] as String?) ?? 'none',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'vyapadaAndManagement': {
        'niruhaVyapada': niruhaVyapada,
        'anuvasanaVyapada': anuvasanaVyapada,
      },
    };
  }

  PaschataKarmaModel copyWith({
    String? id,
    String? patientId,
    String? niruhaVyapada,
    String? anuvasanaVyapada,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaschataKarmaModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      niruhaVyapada: niruhaVyapada ?? this.niruhaVyapada,
      anuvasanaVyapada: anuvasanaVyapada ?? this.anuvasanaVyapada,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
