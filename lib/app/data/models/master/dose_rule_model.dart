import 'dose_component.dart';

class DoseRuleModel {
  final String? id;
  final String bastiType; // 'Niruha', 'Anuvasana', 'Matra'
  final String bala; // 'Pravara', 'Madhyama', 'Avara'
  final double totalVolume;
  final String unit; // 'ml'
  final List<DoseComponent> components;
  final String sourceReference;
  final String? sourceDocument;
  final String? sourceSection;

  const DoseRuleModel({
    this.id,
    required this.bastiType,
    required this.bala,
    required this.totalVolume,
    required this.unit,
    required this.components,
    required this.sourceReference,
    this.sourceDocument,
    this.sourceSection,
  });

  DoseRuleModel copyWith({
    String? id,
    String? bastiType,
    String? bala,
    double? totalVolume,
    String? unit,
    List<DoseComponent>? components,
    String? sourceReference,
    String? sourceDocument,
    String? sourceSection,
  }) {
    return DoseRuleModel(
      id: id ?? this.id,
      bastiType: bastiType ?? this.bastiType,
      bala: bala ?? this.bala,
      totalVolume: totalVolume ?? this.totalVolume,
      unit: unit ?? this.unit,
      components: components ?? this.components,
      sourceReference: sourceReference ?? this.sourceReference,
      sourceDocument: sourceDocument ?? this.sourceDocument,
      sourceSection: sourceSection ?? this.sourceSection,
    );
  }

  factory DoseRuleModel.fromJson(Map<String, dynamic> json) {
    return DoseRuleModel(
      id: json['id'] as String?,
      bastiType: json['bastiType'] as String,
      bala: json['bala'] as String,
      totalVolume: ((json['totalVolume'] as num?) ?? 0.0).toDouble(),
      unit: (json['unit'] as String?) ?? 'ml',
      components: (json['components'] as List<dynamic>?)
              ?.map((e) => DoseComponent.fromJson(
                    e is Map<String, dynamic>
                        ? e
                        : (e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}),
                  ))
              .toList() ??
          const [],
      sourceReference: (json['sourceReference'] as String?) ??
          (json['sourceDocument'] as String?) ??
          'DOSE OF BASTI',
      sourceDocument: json['sourceDocument'] as String?,
      sourceSection: json['sourceSection'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'bastiType': bastiType,
      'bala': bala,
      'totalVolume': totalVolume,
      'unit': unit,
      'components': components.map((e) => e.toJson()).toList(),
      'sourceReference': sourceReference,
      if (sourceDocument != null) 'sourceDocument': sourceDocument,
      if (sourceSection != null) 'sourceSection': sourceSection,
    };
  }

  @override
  String toString() => '$bastiType ($bala Bala): $totalVolume $unit';
}
