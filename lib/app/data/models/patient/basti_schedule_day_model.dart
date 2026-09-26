class BastiScheduleDayModel {
  final int dayNumber;
  final String scheduledBastiType; // 'Anuvasana' or 'Niruha'
  final String bastiTypeCodeShort; // 'A' or 'N'
  final double scheduledDose;
  final String doseUnit;
  final String compositionSummary;
  final bool isCompleted;

  const BastiScheduleDayModel({
    required this.dayNumber,
    required this.scheduledBastiType,
    required this.bastiTypeCodeShort,
    required this.scheduledDose,
    required this.doseUnit,
    required this.compositionSummary,
    this.isCompleted = false,
  });

  factory BastiScheduleDayModel.fromJson(Map<String, dynamic> json) {
    return BastiScheduleDayModel(
      dayNumber: json['dayNumber'] as int,
      scheduledBastiType: json['scheduledBastiType'] as String,
      bastiTypeCodeShort: json['bastiTypeCodeShort'] as String,
      scheduledDose: (json['scheduledDose'] as num).toDouble(),
      doseUnit: json['doseUnit'] as String,
      compositionSummary: json['compositionSummary'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'scheduledBastiType': scheduledBastiType,
      'bastiTypeCodeShort': bastiTypeCodeShort,
      'scheduledDose': scheduledDose,
      'doseUnit': doseUnit,
      'compositionSummary': compositionSummary,
      'isCompleted': isCompleted,
    };
  }

  BastiScheduleDayModel copyWith({
    int? dayNumber,
    String? scheduledBastiType,
    String? bastiTypeCodeShort,
    double? scheduledDose,
    String? doseUnit,
    String? compositionSummary,
    bool? isCompleted,
  }) {
    return BastiScheduleDayModel(
      dayNumber: dayNumber ?? this.dayNumber,
      scheduledBastiType: scheduledBastiType ?? this.scheduledBastiType,
      bastiTypeCodeShort: bastiTypeCodeShort ?? this.bastiTypeCodeShort,
      scheduledDose: scheduledDose ?? this.scheduledDose,
      doseUnit: doseUnit ?? this.doseUnit,
      compositionSummary: compositionSummary ?? this.compositionSummary,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

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
}
