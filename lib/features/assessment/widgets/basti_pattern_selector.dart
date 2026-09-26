// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/data/models/master/basti_pattern_model.dart';

class BastiPatternSelector extends StatelessWidget {
  final List<BastiPatternModel> patterns;
  final String selectedPatternCode;
  final String patientBala;
  final ValueChanged<BastiPatternModel> onPatternSelected;

  const BastiPatternSelector({
    super.key,
    required this.patterns,
    required this.selectedPatternCode,
    required this.patientBala,
    required this.onPatternSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: patterns.map((pattern) {
        final isSelected = pattern.code.toLowerCase() == selectedPatternCode.toLowerCase();
        final isRecommended = pattern.recommendedBala.toLowerCase() == patientBala.toLowerCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => onPatternSelected(pattern),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio<String>(
                      value: pattern.code,
                      groupValue: selectedPatternCode,
                      onChanged: (_) => onPatternSelected(pattern),
                      activeColor: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text(
                                pattern.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDarkGreen,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${pattern.totalDays} Days',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDarkGreen,
                                  ),
                                ),
                              ),
                              if (isRecommended)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.successGreen.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.successGreen),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.thumb_up_alt_outlined, size: 12, color: AppColors.successGreen),
                                      SizedBox(width: 4),
                                      Text(
                                        'Recommended',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.successGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pattern.clinicalIndications,
                            style: const TextStyle(fontSize: 12, color: AppColors.darkGrey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Schedule Sequence:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDarkGreen),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: pattern.sequence.asMap().entries.map((entry) {
                              final dayIndex = entry.key + 1;
                              final code = entry.value.trim().toUpperCase();

                              final Color bgColor;
                              final Color borderColor;
                              final Color textColor;

                              if (code == 'MB') {
                                bgColor = const Color(0xFFFFEDD5); // Orange/Gold
                                borderColor = const Color(0xFFEA580C);
                                textColor = const Color(0xFF9A3412);
                              } else if (code == 'YB') {
                                bgColor = const Color(0xFFF3E8FF); // Purple
                                borderColor = const Color(0xFF9333EA);
                                textColor = const Color(0xFF581C87);
                              } else if (code == 'N') {
                                bgColor = Colors.teal.shade100;
                                borderColor = Colors.teal.shade700;
                                textColor = Colors.teal.shade900;
                              } else {
                                bgColor = Colors.amber.shade100;
                                borderColor = Colors.amber.shade700;
                                textColor = Colors.brown.shade900;
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Text(
                                  '$dayIndex:$code',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
