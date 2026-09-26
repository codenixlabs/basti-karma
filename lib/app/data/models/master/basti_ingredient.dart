class BastiIngredient {
  final String? id;
  final String? bastiId;
  final String name;
  final String category; // 'Kwatha Dravya', 'Prakshepa Dravya', 'Sneha', 'Kalka'
  final String? quantity;
  final String? unit;
  final String? sourceText;

  const BastiIngredient({
    this.id,
    this.bastiId,
    required this.name,
    required this.category,
    this.quantity,
    this.unit,
    this.sourceText,
  });

  BastiIngredient copyWith({
    String? id,
    String? bastiId,
    String? name,
    String? category,
    String? quantity,
    String? unit,
    String? sourceText,
  }) {
    return BastiIngredient(
      id: id ?? this.id,
      bastiId: bastiId ?? this.bastiId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      sourceText: sourceText ?? this.sourceText,
    );
  }

  factory BastiIngredient.fromJson(Map<String, dynamic> json) {
    return BastiIngredient(
      id: (json['id'] as String?) ?? (json['_id'] as String?),
      bastiId: json['bastiId'] as String?,
      name: (json['name'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'Herb / Ingredient',
      quantity: json['quantity']?.toString(),
      unit: json['unit']?.toString(),
      sourceText: json['sourceText']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (bastiId != null) 'bastiId': bastiId,
      'name': name,
      'category': category,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (sourceText != null) 'sourceText': sourceText,
    };
  }

  @override
  String toString() => name;
}
