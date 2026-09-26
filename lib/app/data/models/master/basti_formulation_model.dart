import 'basti_ingredient.dart';

class BastiFormulationModel {
  final String id;
  final String? mongoId;
  final String name;
  final String rawName;
  final String bastiType;
  final String formulationDetails;
  final String ingredientsRaw;
  final String formulationRecipeRaw;
  final bool isCrossReference;
  final String? referencedCondition;
  final bool unresolvedReference;
  final List<String> classicalReferenceIds;
  final String sourceText;
  final String? recipeCompleteness;
  final List<BastiIngredient> ingredients;
  final List<String> diseaseIds;

  const BastiFormulationModel({
    required this.id,
    this.mongoId,
    required this.name,
    required this.rawName,
    required this.bastiType,
    required this.formulationDetails,
    required this.ingredientsRaw,
    this.formulationRecipeRaw = '',
    this.isCrossReference = false,
    this.referencedCondition,
    this.unresolvedReference = false,
    this.classicalReferenceIds = const [],
    this.sourceText = '',
    this.recipeCompleteness,
    this.ingredients = const [],
    this.diseaseIds = const [],
  });

  BastiFormulationModel copyWith({
    String? id,
    String? mongoId,
    String? name,
    String? rawName,
    String? bastiType,
    String? formulationDetails,
    String? ingredientsRaw,
    String? formulationRecipeRaw,
    bool? isCrossReference,
    String? referencedCondition,
    bool? unresolvedReference,
    List<String>? classicalReferenceIds,
    String? sourceText,
    String? recipeCompleteness,
    List<BastiIngredient>? ingredients,
    List<String>? diseaseIds,
  }) {
    return BastiFormulationModel(
      id: id ?? this.id,
      mongoId: mongoId ?? this.mongoId,
      name: name ?? this.name,
      rawName: rawName ?? this.rawName,
      bastiType: bastiType ?? this.bastiType,
      formulationDetails: formulationDetails ?? this.formulationDetails,
      ingredientsRaw: ingredientsRaw ?? this.ingredientsRaw,
      formulationRecipeRaw: formulationRecipeRaw ?? this.formulationRecipeRaw,
      isCrossReference: isCrossReference ?? this.isCrossReference,
      referencedCondition: referencedCondition ?? this.referencedCondition,
      unresolvedReference: unresolvedReference ?? this.unresolvedReference,
      classicalReferenceIds: classicalReferenceIds ?? this.classicalReferenceIds,
      sourceText: sourceText ?? this.sourceText,
      recipeCompleteness: recipeCompleteness ?? this.recipeCompleteness,
      ingredients: ingredients ?? this.ingredients,
      diseaseIds: diseaseIds ?? this.diseaseIds,
    );
  }

  factory BastiFormulationModel.fromJson(Map<String, dynamic> json) {
    return BastiFormulationModel(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      mongoId: json['_id'] as String?,
      name: (json['name'] as String?) ?? '',
      rawName: (json['rawName'] as String?) ?? '',
      bastiType: (json['bastiType'] as String?) ?? '',
      formulationDetails: (json['formulationDetails'] as String?) ?? '',
      ingredientsRaw: (json['ingredientsRaw'] as String?) ?? '',
      formulationRecipeRaw: (json['formulationRecipeRaw'] as String?) ?? '',
      isCrossReference: (json['isCrossReference'] as bool?) ?? false,
      referencedCondition: json['referencedCondition'] as String?,
      unresolvedReference: (json['unresolvedReference'] as bool?) ?? false,
      classicalReferenceIds: (json['classicalReferenceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sourceText: (json['sourceText'] as String?) ?? '',
      recipeCompleteness: json['recipeCompleteness'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => BastiIngredient.fromJson(
                    e is Map<String, dynamic>
                        ? e
                        : (e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}),
                  ))
              .toList() ??
          const [],
      diseaseIds: (json['diseaseIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (mongoId != null) '_id': mongoId,
      'name': name,
      'rawName': rawName,
      'bastiType': bastiType,
      'formulationDetails': formulationDetails,
      'ingredientsRaw': ingredientsRaw,
      'formulationRecipeRaw': formulationRecipeRaw,
      'isCrossReference': isCrossReference,
      if (referencedCondition != null) 'referencedCondition': referencedCondition,
      'unresolvedReference': unresolvedReference,
      'classicalReferenceIds': classicalReferenceIds,
      'sourceText': sourceText,
      if (recipeCompleteness != null) 'recipeCompleteness': recipeCompleteness,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'diseaseIds': diseaseIds,
    };
  }

  @override
  String toString() => name;
}
