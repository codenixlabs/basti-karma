class BastiPatternModel {
  final String code; // 'karma', 'kala', 'yoga', 'matra_avara', etc.
  final String name; // 'Karma Basti', 'Kala Basti', 'Yoga Basti', etc.
  final int totalDays; // 30, 15, 8, etc.
  final String recommendedBala; // 'Pravara', 'Madhyama', 'Avara'
  final List<String> sequence; // e.g. ['A', 'N', 'A', 'N', ...] or ['MB', 'MB', ...]
  final String clinicalIndications;
  final int? niruhaCount;
  final int? anuvasanaCount;
  final String? bastiType;

  const BastiPatternModel({
    required this.code,
    required this.name,
    required this.totalDays,
    required this.recommendedBala,
    required this.sequence,
    required this.clinicalIndications,
    this.niruhaCount,
    this.anuvasanaCount,
    this.bastiType,
  });

  BastiPatternModel copyWith({
    String? code,
    String? name,
    int? totalDays,
    String? recommendedBala,
    List<String>? sequence,
    String? clinicalIndications,
    int? niruhaCount,
    int? anuvasanaCount,
    String? bastiType,
  }) {
    return BastiPatternModel(
      code: code ?? this.code,
      name: name ?? this.name,
      totalDays: totalDays ?? this.totalDays,
      recommendedBala: recommendedBala ?? this.recommendedBala,
      sequence: sequence ?? this.sequence,
      clinicalIndications: clinicalIndications ?? this.clinicalIndications,
      niruhaCount: niruhaCount ?? this.niruhaCount,
      anuvasanaCount: anuvasanaCount ?? this.anuvasanaCount,
      bastiType: bastiType ?? this.bastiType,
    );
  }

  factory BastiPatternModel.fromJson(Map<String, dynamic> json) {
    return BastiPatternModel(
      code: json['code'] as String,
      name: json['name'] as String,
      totalDays: json['totalDays'] as int,
      recommendedBala: (json['recommendedBala'] as String?) ?? 'Avara',
      sequence: (json['sequence'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      clinicalIndications: (json['clinicalIndications'] as String?) ?? '',
      niruhaCount: json['niruhaCount'] as int?,
      anuvasanaCount: json['anuvasanaCount'] as int?,
      bastiType: json['bastiType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'totalDays': totalDays,
      'recommendedBala': recommendedBala,
      'sequence': sequence,
      'clinicalIndications': clinicalIndications,
      if (niruhaCount != null) 'niruhaCount': niruhaCount,
      if (anuvasanaCount != null) 'anuvasanaCount': anuvasanaCount,
      if (bastiType != null) 'bastiType': bastiType,
    };
  }

  int get matraCount => sequence.where((s) => s.toUpperCase() == 'MB').length;
  int get yapanaCount => sequence.where((s) => s.toUpperCase() == 'YB').length;
  int get niruhaDaysCount => niruhaCount ?? sequence.where((s) => s.toUpperCase() == 'N').length;
  int get anuvasanaDaysCount => anuvasanaCount ?? sequence.where((s) => s.toUpperCase() == 'A').length;

  /// Checks if this pattern matches the given formulation basti type.
  bool matchesBastiType(String? formulationBastiType) {
    if (formulationBastiType == null || formulationBastiType.trim().isEmpty) {
      return true;
    }
    final target = formulationBastiType.toLowerCase().trim();

    // 1. Direct match on pattern's own bastiType if backend provided it
    if (bastiType != null && bastiType!.trim().isNotEmpty) {
      final pb = bastiType!.toLowerCase().trim();
      if (pb == target || pb.contains(target) || target.contains(pb)) {
        return true;
      }
    }

    // 2. Matra / Sneha Basti
    if (target.contains('matra') ||
        (target.contains('sneha') && !target.contains('niruha'))) {
      final hasMB = sequence.any((s) => s.toUpperCase() == 'MB');
      final allSneha = sequence.every((s) => s.toUpperCase() == 'MB' || s.toUpperCase() == 'A');
      final codeNameMatch = code.toLowerCase().contains('matra') ||
          name.toLowerCase().contains('matra') ||
          code.toLowerCase().contains('sneha');
      return hasMB || allSneha || codeNameMatch;
    }

    // 3. Yapana Basti
    if (target.contains('yapana') || target == 'yb') {
      final hasYB = sequence.any((s) => s.toUpperCase() == 'YB');
      final codeNameMatch = code.toLowerCase().contains('yapana') ||
          name.toLowerCase().contains('yapana');
      return hasYB || codeNameMatch;
    }

    // 4. Combined Niruha + Anuvasana
    if (target.contains('niruha') && target.contains('anuvasana')) {
      final hasBoth = sequence.any((s) => s.toUpperCase() == 'N') &&
          sequence.any((s) => s.toUpperCase() == 'A');
      final codeNameMatch = code.toLowerCase().contains('karma') ||
          code.toLowerCase().contains('kala') ||
          code.toLowerCase().contains('yoga');
      return hasBoth || codeNameMatch;
    }

    // 5. Niruha only
    if (target.contains('niruha')) {
      return sequence.any((s) => s.toUpperCase() == 'N') ||
          code.toLowerCase().contains('niruha');
    }

    // 6. Anuvasana only
    if (target.contains('anuvasana')) {
      return sequence.every((s) => s.toUpperCase() == 'A') ||
          code.toLowerCase().contains('anuvasana');
    }

    return true;
  }

  @override
  String toString() => '$name ($totalDays Days)';
}
