import 'basti_formulation_model.dart';
import 'basti_ingredient.dart';

class BastiOptionModel {
  final String id;
  final String? mongoId;
  final String diseaseId;
  final String name;
  final String bastiTypeCode; // e.g. 'NB+AB', 'NB', 'AB', 'YB', 'Sneha', 'Uttara'
  final String bastiTypeDisplay; // e.g. 'Niruha Basti + Anuvasana Basti'
  final String indicationStage;
  final List<BastiIngredient> ingredients;
  final String formulationDetails;
  final String classicalReference;
  final bool unresolvedReference;
  final String? referencedCondition;
  final String? recipeCompleteness;
  final String? sourceText;

  const BastiOptionModel({
    required this.id,
    this.mongoId,
    required this.diseaseId,
    required this.name,
    required this.bastiTypeCode,
    required this.bastiTypeDisplay,
    required this.indicationStage,
    required this.ingredients,
    required this.formulationDetails,
    required this.classicalReference,
    this.unresolvedReference = false,
    this.referencedCondition,
    this.recipeCompleteness,
    this.sourceText,
  });

  factory BastiOptionModel.fromFormulation(
    BastiFormulationModel formulation, {
    required String diseaseId,
  }) {
    return BastiOptionModel(
      id: formulation.id,
      mongoId: formulation.mongoId ??
          (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(formulation.id)
              ? formulation.id
              : null),
      diseaseId: diseaseId,
      name: formulation.name,
      bastiTypeCode: formulation.bastiType,
      bastiTypeDisplay: resolveBastiTypeDisplay(formulation.bastiType),
      indicationStage: formulation.formulationDetails.isNotEmpty
          ? formulation.formulationDetails
          : (formulation.sourceText.isNotEmpty
              ? formulation.sourceText
              : 'General clinical indication'),
      ingredients: formulation.ingredients,
      formulationDetails: formulation.formulationDetails,
      classicalReference: formulation.classicalReferenceIds.isNotEmpty
          ? formulation.classicalReferenceIds.join(', ')
          : (formulation.sourceText.isNotEmpty ? formulation.sourceText : ''),
      unresolvedReference: formulation.unresolvedReference,
      referencedCondition: formulation.referencedCondition,
      recipeCompleteness: formulation.recipeCompleteness,
      sourceText: formulation.sourceText,
    );
  }

  static String resolveBastiTypeDisplay(String bastiTypeCode) {
    final trimmed = bastiTypeCode.trim();
    if (trimmed.contains('Niruha') && trimmed.contains('Anuvasana')) {
      return 'Niruha Basti + Anuvasana Basti';
    }
    if (trimmed.contains('Yapana') || trimmed == 'YB' || trimmed == 'only YB') {
      return 'Yapana Basti';
    }
    if (trimmed.contains('Sneha') || trimmed.contains('Matra')) {
      return 'Sneha Basti';
    }
    if (trimmed.contains('Uttara')) {
      return 'Uttara Basti';
    }
    if (trimmed.contains('Niruha')) {
      return 'Niruha Basti';
    }
    if (trimmed.contains('Anuvasana')) {
      return 'Anuvasana Basti';
    }
    return bastiTypeCode;
  }

  factory BastiOptionModel.fromJson(Map<String, dynamic> json) {
    return BastiOptionModel(
      id: json['id'] as String,
      diseaseId: json['diseaseId'] as String,
      name: json['name'] as String,
      bastiTypeCode: json['bastiTypeCode'] as String,
      bastiTypeDisplay: json['bastiTypeDisplay'] as String,
      indicationStage: json['indicationStage'] as String,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => BastiIngredient.fromJson(
                    e is Map<String, dynamic>
                        ? e
                        : (e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}),
                  ))
              .toList() ??
          const [],
      formulationDetails: (json['formulationDetails'] as String?) ?? '',
      classicalReference: (json['classicalReference'] as String?) ?? '',
      unresolvedReference: (json['unresolvedReference'] as bool?) ?? false,
      referencedCondition: json['referencedCondition'] as String?,
      recipeCompleteness: json['recipeCompleteness'] as String?,
      sourceText: json['sourceText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diseaseId': diseaseId,
      'name': name,
      'bastiTypeCode': bastiTypeCode,
      'bastiTypeDisplay': bastiTypeDisplay,
      'indicationStage': indicationStage,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'formulationDetails': formulationDetails,
      'classicalReference': classicalReference,
      'unresolvedReference': unresolvedReference,
      if (referencedCondition != null) 'referencedCondition': referencedCondition,
      if (recipeCompleteness != null) 'recipeCompleteness': recipeCompleteness,
      if (sourceText != null) 'sourceText': sourceText,
    };
  }

  @override
  String toString() => name;
}
