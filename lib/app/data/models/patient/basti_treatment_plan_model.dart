import 'basti_schedule_day_model.dart';
import 'treatment_status.dart';

/// Represents a complete Basti treatment plan for a patient.
///
/// Immutable value object — use [copyWith] to produce updated copies.
class BastiTreatmentPlanModel {
  // ── Identity ───────────────────────────────────────────────────────────────
  final String id;
  final String? patientId;

  // ── Clinical fields (Milestone 1 — never modify logic) ────────────────────
  final String diseaseId;
  final String diseaseName;
  final String bastiOptionId;
  final String bastiName;
  final String patientBala; // 'Pravara' | 'Madhyama' | 'Avara'
  final String selectedPatternCode; // 'karma' | 'kala' | 'yoga'
  final String selectedPatternName;
  final double calculatedNiruhaDose;
  final double calculatedAnuvasanaDose;
  final List<BastiScheduleDayModel> scheduleDays;

  // ── Lifecycle (Milestone 2) ────────────────────────────────────────────────
  final TreatmentStatus status;
  final DateTime? startDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BastiTreatmentPlanModel({
    required this.id,
    this.patientId,
    required this.diseaseId,
    required this.diseaseName,
    required this.bastiOptionId,
    required this.bastiName,
    required this.patientBala,
    required this.selectedPatternCode,
    required this.selectedPatternName,
    required this.calculatedNiruhaDose,
    required this.calculatedAnuvasanaDose,
    required this.scheduleDays,
    this.status = TreatmentStatus.draft,
    this.startDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Factory helpers ────────────────────────────────────────────────────────

  factory BastiTreatmentPlanModel.fromJson(Map<String, dynamic> json) {
    return BastiTreatmentPlanModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String?,
      diseaseId: json['diseaseId'] as String,
      diseaseName: json['diseaseName'] as String,
      bastiOptionId: json['bastiOptionId'] as String,
      bastiName: json['bastiName'] as String,
      patientBala: json['patientBala'] as String,
      selectedPatternCode: json['selectedPatternCode'] as String,
      selectedPatternName: json['selectedPatternName'] as String,
      calculatedNiruhaDose:
          (json['calculatedNiruhaDose'] as num).toDouble(),
      calculatedAnuvasanaDose:
          (json['calculatedAnuvasanaDose'] as num).toDouble(),
      scheduleDays: (json['scheduleDays'] as List<dynamic>)
          .map((e) =>
              BastiScheduleDayModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: treatmentStatusFromJson(json['status'] as String?),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'diseaseId': diseaseId,
      'diseaseName': diseaseName,
      'bastiOptionId': bastiOptionId,
      'bastiName': bastiName,
      'patientBala': patientBala,
      'selectedPatternCode': selectedPatternCode,
      'selectedPatternName': selectedPatternName,
      'calculatedNiruhaDose': calculatedNiruhaDose,
      'calculatedAnuvasanaDose': calculatedAnuvasanaDose,
      'scheduleDays': scheduleDays.map((e) => e.toJson()).toList(),
      'status': status.toJson(),
      'startDate': startDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BastiTreatmentPlanModel copyWith({
    String? id,
    String? patientId,
    String? diseaseId,
    String? diseaseName,
    String? bastiOptionId,
    String? bastiName,
    String? patientBala,
    String? selectedPatternCode,
    String? selectedPatternName,
    double? calculatedNiruhaDose,
    double? calculatedAnuvasanaDose,
    List<BastiScheduleDayModel>? scheduleDays,
    TreatmentStatus? status,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BastiTreatmentPlanModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      diseaseId: diseaseId ?? this.diseaseId,
      diseaseName: diseaseName ?? this.diseaseName,
      bastiOptionId: bastiOptionId ?? this.bastiOptionId,
      bastiName: bastiName ?? this.bastiName,
      patientBala: patientBala ?? this.patientBala,
      selectedPatternCode: selectedPatternCode ?? this.selectedPatternCode,
      selectedPatternName: selectedPatternName ?? this.selectedPatternName,
      calculatedNiruhaDose: calculatedNiruhaDose ?? this.calculatedNiruhaDose,
      calculatedAnuvasanaDose:
          calculatedAnuvasanaDose ?? this.calculatedAnuvasanaDose,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
