import '../models/master/dose_component.dart';
import '../repositories/basti_clinical_repository.dart';

class DoseCalculationResult {
  final String bastiType;
  final String bala;
  final double totalVolume;
  final String unit;
  final List<DoseComponent> components;
  final String sourceReference;

  const DoseCalculationResult({
    required this.bastiType,
    required this.bala,
    required this.totalVolume,
    required this.unit,
    required this.components,
    required this.sourceReference,
  });

  String get summaryText {
    if (components.isEmpty) {
      return '$bastiType ($bala Bala): ${totalVolume.toInt()} $unit';
    }
    final compList = components.map((c) => '${c.name}: ${c.amount % 1 == 0 ? c.amount.toInt() : c.amount} ${c.unit}').join(', ');
    return '$bastiType ($bala Bala): ${totalVolume.toInt()} $unit [$compList]';
  }
}

class BastiDoseCalculatorService {
  final BastiClinicalRepository repository;

  BastiDoseCalculatorService({BastiClinicalRepository? repository})
      : repository = repository ?? BastiClinicalRepository();

  Future<DoseCalculationResult?> calculateDose({
    required String bastiType,
    required String patientBala,
  }) async {
    // 1. Direct query via repository (uses GET /api/master/dose-rules?bastiType={type}&bala={bala})
    final rule = await repository.getDoseRule(bastiType, patientBala);
    if (rule != null) {
      return DoseCalculationResult(
        bastiType: rule.bastiType,
        bala: rule.bala,
        totalVolume: rule.totalVolume,
        unit: rule.unit,
        components: rule.components,
        sourceReference: rule.sourceReference,
      );
    }

    // 2. Fallbacks for dynamic Matra and Yapana if not distinct in DB
    final lower = bastiType.toLowerCase();
    if (lower.contains('matra') || lower == 'mb') {
      final anuvasanaRule = await repository.getDoseRule('Anuvasana', patientBala);
      if (anuvasanaRule != null) {
        final matraVol = (anuvasanaRule.totalVolume > 60)
            ? (anuvasanaRule.totalVolume / 2)
            : anuvasanaRule.totalVolume;
        return DoseCalculationResult(
          bastiType: 'Matra Basti',
          bala: anuvasanaRule.bala,
          totalVolume: matraVol,
          unit: anuvasanaRule.unit,
          components: anuvasanaRule.components.map((c) => DoseComponent(
            name: c.name,
            amount: (c.amount > 30) ? (c.amount / 2) : c.amount,
            unit: c.unit,
          )).toList(),
          sourceReference: anuvasanaRule.sourceReference,
        );
      }
    } else if (lower.contains('yapana') || lower == 'yb') {
      final niruhaRule = await repository.getDoseRule('Niruha', patientBala);
      if (niruhaRule != null) {
        return DoseCalculationResult(
          bastiType: 'Yapana Basti',
          bala: niruhaRule.bala,
          totalVolume: niruhaRule.totalVolume,
          unit: niruhaRule.unit,
          components: niruhaRule.components,
          sourceReference: niruhaRule.sourceReference,
        );
      }
    }

    return null;
  }
}
