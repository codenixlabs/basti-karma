import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/theme/app_theme.dart';
import '../controller/assessment_controller.dart';
import '../widgets/assessment_widgets.dart';
import 'purvakarma_screen.dart';
import 'pradhankarma_screen.dart';
import 'paschatkarma_screen.dart';

class AssessmentDashboardScreen extends StatelessWidget {
  const AssessmentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            AssessmentPageHeader(
              phase: 'Assessment',
              subTitle: ctrl.patientName,
              onBack: () => Get.back(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select a phase to begin',
                      style: TextStyle(
                        color: AppColors.darkGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Obx(
                      () => _PhaseCard(
                        number: '01',
                        title: 'Purvakarma',
                        subtitle: 'Pre-procedure assessment',
                        icon: Icons.checklist_rounded,
                        color: const Color(0xFF2E7D4F),
                        isUnlocked: true,
                        isComplete: ctrl.purvakarmaComplete.value,
                        onTap: () => Get.to(() => const PurvakarmaScreen()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Obx(
                      () => _PhaseCard(
                        number: '02',
                        title: 'Pradhan Karma',
                        subtitle: 'Main procedure planning',
                        icon: Icons.medical_services_outlined,
                        color: const Color(0xFF1565C0),
                        isUnlocked: ctrl.purvakarmaComplete.value,
                        isComplete: ctrl.pradhankarmaComplete.value,
                        onTap: ctrl.purvakarmaComplete.value
                            ? () => Get.to(() => const PradhanKarmaScreen())
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Obx(
                      () => _PhaseCard(
                        number: '03',
                        title: 'Paschatkarma',
                        subtitle: 'Post-procedure care',
                        icon: Icons.healing_outlined,
                        color: const Color(0xFF6A1B9A),
                        isUnlocked: ctrl.pradhankarmaComplete.value,
                        isComplete: false,
                        onTap: ctrl.pradhankarmaComplete.value
                            ? () => Get.to(() => const PaschatkarmaScreen())
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final bool isComplete;
  final VoidCallback? onTap;

  const _PhaseCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.isComplete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dimmed = !isUnlocked;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: dimmed ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isComplete
                ? Border.all(color: AppColors.successGreen, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Phase number + icon circle
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textDarkGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.darkGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Status icon
              if (isComplete)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.successGreen,
                  size: 24,
                )
              else if (!isUnlocked)
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.darkGrey,
                  size: 22,
                )
              else
                Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
