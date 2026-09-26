import 'package:flutter/material.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/data/services/basti_dose_calculator_service.dart';

class DoseBreakdownCard extends StatelessWidget {
  final List<DoseCalculationResult> doses;
  final String patientBala;

  const DoseBreakdownCard({
    super.key,
    required this.doses,
    required this.patientBala,
  });

  Color _getBadgeColor(String bastiType) {
    final lower = bastiType.toLowerCase();
    if (lower.contains('anuvasana') || lower.contains('matra')) {
      return Colors.teal.shade700;
    }
    return AppColors.primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.calculate_outlined, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Automated Dose / Matra Calculation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Bala: $patientBala',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkGreen,
                    ),
                  ),
                ),
              ],
            ),
            
            if (doses.isNotEmpty) ...[
              const Divider(height: 20),
              ...List.generate(doses.length, (index) {
                final dose = doses[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == doses.length - 1 ? 0 : 16),
                  child: _buildDoseSection(
                    title: '${dose.bastiType} Matra (${dose.bala} Bala)',
                    totalVolume: dose.totalVolume,
                    unit: dose.unit,
                    components: dose.components,
                    badgeColor: _getBadgeColor(dose.bastiType),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoseSection({
    required String title,
    required double totalVolume,
    required String unit,
    required List components,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: ${totalVolume.toInt()} $unit',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (components.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: components.map<Widget>((comp) {
                return Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  label: Text(
                    '${comp.name}: ${comp.amount % 1 == 0 ? comp.amount.toInt() : comp.amount} ${comp.unit}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
