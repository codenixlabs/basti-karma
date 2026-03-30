import 'package:flutter/material.dart';
import '../../../app/core/theme/app_theme.dart';

class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  static const _calculators = [
    {
      'icon': Icons.calculate_outlined,
      'title': 'Dose Calculator',
      'subtitle': 'Calculate next Snehapana dose',
      'arrow': true,
    },
    {
      'icon': Icons.balance_outlined,
      'title': 'BMI Calculator',
      'subtitle': 'Body Mass Index calculation',
      'arrow': false,
    },
    {
      'icon': Icons.monitor_heart_outlined,
      'title': 'Agni Score Calculator',
      'subtitle': 'Quick Agni assessment score',
      'arrow': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, Color(0xFF3D7A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculators',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Medical calculation tools',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  // Calculator cards
                  ..._calculators.map(
                    (calc) => _CalculatorCard(
                      icon: calc['icon'] as IconData,
                      title: calc['title'] as String,
                      subtitle: calc['subtitle'] as String,
                      showArrow: calc['arrow'] as bool,
                      onTap: () {},
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Clinical Tools info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_hospital_outlined,
                              color: AppColors.primaryGreen,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Clinical Tools',
                              style: TextStyle(
                                color: AppColors.textDarkGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'These calculators are designed to assist in clinical decision-making. Always combine calculated results with clinical judgment and patient assessment.',
                          style: TextStyle(
                            color: AppColors.darkGrey,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showArrow;
  final VoidCallback onTap;

  const _CalculatorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.showArrow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textDarkGreen,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.darkGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              const Icon(
                Icons.arrow_forward,
                color: AppColors.darkGrey,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
