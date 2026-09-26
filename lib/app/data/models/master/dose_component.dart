class DoseComponent {
  final String name;
  final double amount;
  final String unit; // 'ml' or 'gm'

  const DoseComponent({
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory DoseComponent.fromJson(Map<String, dynamic> json) {
    return DoseComponent(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
    };
  }

  @override
  String toString() => '$name: ${amount % 1 == 0 ? amount.toInt() : amount} $unit';
}
