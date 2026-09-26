import 'treatment_status.dart';

/// Represents a single treatment session (one day) within a [BastiTreatmentPlanModel].
///
/// Each session stores its own clinical observations independently so that
/// Day 1 and Day 2 values are always isolated from each other.
class BastiSessionModel {
  // ── Identity ───────────────────────────────────────────────────────────────
  final String id;
  final String treatmentPlanId;
  final int dayNumber;

  // ── Scheduled clinical data (copied from plan at creation) ────────────────
  final String scheduledBastiType; // 'Anuvasana' | 'Niruha'
  final String bastiTypeCodeShort; // 'A' | 'N'
  final double scheduledDose;
  final String doseUnit;

  // ── Session lifecycle ──────────────────────────────────────────────────────
  final SessionStatus status;

  // ── Observations (Pradhan Karma logging) ──────────────────────────────────
  final String adanaKala;       // e.g. '08:30 AM'
  final String pratyagamana;    // e.g. '09:15 AM'
  final String vega;            // e.g. '0', '2'
  final List<bool> samyakaSelected;
  final List<bool> ayogaSelected;
  final List<bool> atiyogaSelected;

  // ── Paschata Karma (Vyapada) ────────────────────────────────────────────────
  final String niruhaVyapada;
  final String anuvasanaVyapada;

  // ── Timestamps ────────────────────────────────────────────────────────────
  final DateTime createdAt;
  final DateTime updatedAt;

  const BastiSessionModel({
    required this.id,
    required this.treatmentPlanId,
    required this.dayNumber,
    required this.scheduledBastiType,
    required this.bastiTypeCodeShort,
    required this.scheduledDose,
    required this.doseUnit,
    this.status = SessionStatus.pending,
    this.adanaKala = '',
    this.pratyagamana = '',
    this.vega = '',
    required this.samyakaSelected,
    required this.ayogaSelected,
    required this.atiyogaSelected,
    this.niruhaVyapada = '',
    this.anuvasanaVyapada = '',
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Derived ───────────────────────────────────────────────────────────────

  bool get hasObservations =>
      adanaKala.isNotEmpty ||
      pratyagamana.isNotEmpty ||
      vega.isNotEmpty ||
      niruhaVyapada.isNotEmpty ||
      anuvasanaVyapada.isNotEmpty ||
      samyakaSelected.any((v) => v) ||
      ayogaSelected.any((v) => v) ||
      atiyogaSelected.any((v) => v);

  bool get isCompleted => status == SessionStatus.completed;

  bool get isNiruha =>
      bastiTypeCodeShort.toUpperCase() == 'N' ||
      (scheduledBastiType.toLowerCase().contains('niruha') && !isYapana);
  bool get isAnuvasana =>
      bastiTypeCodeShort.toUpperCase() == 'A' ||
      (scheduledBastiType.toLowerCase().contains('anuvasana') && !isMatra);
  bool get isMatra =>
      bastiTypeCodeShort.toUpperCase() == 'MB' ||
      scheduledBastiType.toLowerCase().contains('matra');
  bool get isYapana =>
      bastiTypeCodeShort.toUpperCase() == 'YB' ||
      scheduledBastiType.toLowerCase().contains('yapana');

  bool get isSnehaBased => isAnuvasana || isMatra;
  bool get isKwathaBased => isNiruha || isYapana;

  List<String> get selectedObservationIds => getSelectedObservationIds(
        isNiruha: isKwathaBased,
        samyakaSelected: samyakaSelected,
        ayogaSelected: ayogaSelected,
        atiyogaSelected: atiyogaSelected,
      );

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory BastiSessionModel.fromJson(Map<String, dynamic> json) {
    return BastiSessionModel(
      id: json['id'] as String,
      treatmentPlanId: json['treatmentPlanId'] as String,
      dayNumber: json['dayNumber'] as int,
      scheduledBastiType: json['scheduledBastiType'] as String,
      bastiTypeCodeShort: json['bastiTypeCodeShort'] as String,
      scheduledDose: (json['scheduledDose'] as num).toDouble(),
      doseUnit: json['doseUnit'] as String,
      status: sessionStatusFromJson(json['status'] as String?),
      adanaKala: json['adanaKala'] as String? ?? '',
      pratyagamana: json['pratyagamana'] as String? ?? '',
      vega: json['vega'] as String? ?? '',
      samyakaSelected: (json['samyakaSelected'] as List<dynamic>)
          .map((e) => e as bool)
          .toList(),
      ayogaSelected: (json['ayogaSelected'] as List<dynamic>)
          .map((e) => e as bool)
          .toList(),
      atiyogaSelected: (json['atiyogaSelected'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          [],
      niruhaVyapada: json['paschataKarma']?['vyapadaAndManagement']?['niruhaVyapada'] as String? ?? '',
      anuvasanaVyapada: json['paschataKarma']?['vyapadaAndManagement']?['anuvasanaVyapada'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'treatmentPlanId': treatmentPlanId,
      'dayNumber': dayNumber,
      'scheduledBastiType': scheduledBastiType,
      'bastiTypeCodeShort': bastiTypeCodeShort,
      'scheduledDose': scheduledDose,
      'doseUnit': doseUnit,
      'status': status.toJson(),
      'adanaKala': adanaKala,
      'pratyagamana': pratyagamana,
      'vega': vega,
      'samyakaSelected': samyakaSelected,
      'ayogaSelected': ayogaSelected,
      'atiyogaSelected': atiyogaSelected,
      'paschataKarma': {
        'vyapadaAndManagement': {
          if (niruhaVyapada.isNotEmpty) 'niruhaVyapada': niruhaVyapada,
          if (anuvasanaVyapada.isNotEmpty) 'anuvasanaVyapada': anuvasanaVyapada,
        }
      },
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BastiSessionModel copyWith({
    String? id,
    String? treatmentPlanId,
    int? dayNumber,
    String? scheduledBastiType,
    String? bastiTypeCodeShort,
    double? scheduledDose,
    String? doseUnit,
    SessionStatus? status,
    String? adanaKala,
    String? pratyagamana,
    String? vega,
    List<bool>? samyakaSelected,
    List<bool>? ayogaSelected,
    List<bool>? atiyogaSelected,
    String? niruhaVyapada,
    String? anuvasanaVyapada,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BastiSessionModel(
      id: id ?? this.id,
      treatmentPlanId: treatmentPlanId ?? this.treatmentPlanId,
      dayNumber: dayNumber ?? this.dayNumber,
      scheduledBastiType: scheduledBastiType ?? this.scheduledBastiType,
      bastiTypeCodeShort: bastiTypeCodeShort ?? this.bastiTypeCodeShort,
      scheduledDose: scheduledDose ?? this.scheduledDose,
      doseUnit: doseUnit ?? this.doseUnit,
      status: status ?? this.status,
      adanaKala: adanaKala ?? this.adanaKala,
      pratyagamana: pratyagamana ?? this.pratyagamana,
      vega: vega ?? this.vega,
      samyakaSelected: samyakaSelected ?? List.from(this.samyakaSelected),
      ayogaSelected: ayogaSelected ?? List.from(this.ayogaSelected),
      atiyogaSelected: atiyogaSelected ?? List.from(this.atiyogaSelected),
      niruhaVyapada: niruhaVyapada ?? this.niruhaVyapada,
      anuvasanaVyapada: anuvasanaVyapada ?? this.anuvasanaVyapada,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Helper function to retrieve string observation identifiers for selected symptoms.
List<String> getSelectedObservationIds({
  required bool isNiruha,
  required List<bool> samyakaSelected,
  required List<bool> ayogaSelected,
  required List<bool> atiyogaSelected,
}) {
  final result = <String>[];
  if (isNiruha) {
    const sKeys = [
      'prasristaVinaMutra',
      'sameerantwama',
      'agniVriddhi',
      'ruchi',
      'ashayaLaghava',
      'rogashanti',
      'prakritiBala',
    ];
    for (int i = 0; i < sKeys.length && i < samyakaSelected.length; i++) {
      if (samyakaSelected[i]) result.add(sKeys[i]);
    }
    const aKeys = [
      'siroHridGudaVedana',
      'sopha',
      'pratishyaya',
      'vikartika',
      'hrullasa',
      'marutaSanga',
      'mutraSanga',
      'shvaskashta',
    ];
    for (int i = 0; i < aKeys.length && i < ayogaSelected.length; i++) {
      if (ayogaSelected[i]) result.add(aKeys[i]);
    }
    const atKeys = [
      'kaphaPittaVataRaktaKshayajVikara',
      'supti',
      'angamarda',
      'klama',
      'vepathu',
      'nidraNasha',
      'balaNasha',
      'tamaPravesha',
      'unmada',
      'hikka',
    ];
    for (int i = 0; i < atKeys.length && i < atiyogaSelected.length; i++) {
      if (atiyogaSelected[i]) result.add(atKeys[i]);
    }
  } else {
    const sKeys = [
      'sapurishaSnehaPratyeti',
      'shariraLaghavta',
      'bala',
      'srustachVega',
      'vatanulomana',
      'agnidipta',
    ];
    for (int i = 0; i < sKeys.length && i < samyakaSelected.length; i++) {
      if (samyakaSelected[i]) result.add(sKeys[i]);
    }
    const aKeys = [
      'adhaSariraRuja',
      'udaraRuja',
      'bahuPrushthaRuja',
      'parshvaRuja',
      'rukshaGatra',
      'rukshaSvara',
      'vitSanga',
      'mutraSanga',
    ];
    for (int i = 0; i < aKeys.length && i < ayogaSelected.length; i++) {
      if (ayogaSelected[i]) result.add(aKeys[i]);
    }
    const atKeys = [
      'hrullasa',
      'moha',
      'klama',
      'sada',
      'murchha',
      'vikartika',
    ];
    for (int i = 0; i < atKeys.length && i < atiyogaSelected.length; i++) {
      if (atiyogaSelected[i]) result.add(atKeys[i]);
    }
  }
  return result;
}
