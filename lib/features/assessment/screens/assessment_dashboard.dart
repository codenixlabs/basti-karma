import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/core/theme/app_text_styles.dart';
import '../controller/assessment_controller.dart';
import '../widgets/assessment_widgets.dart';
import 'purvakarma_screen.dart';
import 'pradhankarma_screen.dart';
import 'paschatkarma_screen.dart';
import '../../../app/shared/widgets/physician_yukti_banner.dart';

// ── Phase status (replaces binary isUnlocked) ──────────────────────────────

enum _PhaseStatus { notStarted, inProgress, completed }

class AssessmentDashboardScreen extends StatelessWidget {
  const AssessmentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 20),

                    // ── 01 Purvakarma ── always open ────────────────────────
                    Obx(() {
                      final status = ctrl.purvakarmaComplete.value
                          ? _PhaseStatus.completed
                          : _PhaseStatus.notStarted;
                      return _PhaseCard(
                        number: '01',
                        title: 'Purvakarma',
                        subtitle: 'Pre-procedure assessment',
                        icon: Icons.checklist_rounded,
                        color: const Color(0xFF2E7D4F),
                        status: status,
                        onTap: () => Get.to(() => const PurvakarmaScreen()),
                      );
                    }),
                    const SizedBox(height: 14),

                    // ── 02 Pradhan Karma ── always open ─────────────────────
                    Obx(() {
                      final status = ctrl.pradhankarmaComplete.value
                          ? _PhaseStatus.completed
                          : ctrl.purvakarmaComplete.value
                              ? _PhaseStatus.inProgress
                              : _PhaseStatus.notStarted;
                      return _PhaseCard(
                        number: '02',
                        title: 'Pradhan Karma',
                        subtitle: 'Main procedure planning',
                        icon: Icons.medical_services_outlined,
                        color: const Color(0xFF1565C0),
                        status: status,
                        onTap: () {
                          final hasActiveSessions = ctrl.loggedSessionCount > 0;
                          final initialStep =
                              (ctrl.purvakarmaComplete.value && hasActiveSessions)
                                  ? 3
                                  : 0;
                          Get.to(() => PradhanKarmaScreen(initialStep: initialStep));
                        },
                      );
                    }),
                    const SizedBox(height: 14),

                    // ── 03 Paschatkarma ── always open; prerequisite check on
                    //    clinical progression (not on navigation) ────────────
                    Obx(() {
                      final status = ctrl.paschatkarmaComplete.value
                          ? _PhaseStatus.completed
                          : ctrl.pradhankarmaComplete.value
                              ? _PhaseStatus.inProgress
                              : _PhaseStatus.notStarted;
                      return _PhaseCard(
                        number: '03',
                        title: 'Paschatkarma',
                        subtitle: 'Post-procedure care',
                        icon: Icons.healing_outlined,
                        color: const Color(0xFF6A1B9A),
                        status: status,
                        onTap: () {
                          if (!ctrl.pradhankarmaComplete.value) {
                            // Clinical prerequisite warning — navigation is NOT blocked
                            Get.snackbar(
                              'Pradhan Karma Incomplete',
                              'Please complete all required Basti sessions before proceeding to Paschatkarma.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: const Color(0xFFE65100),
                              colorText: Colors.white,
                              duration: const Duration(seconds: 4),
                              margin: const EdgeInsets.all(16),
                              borderRadius: 14,
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                              ),
                            );
                          }
                          // Doctor can still open the screen to review
                          Get.to(() => const PaschatkarmaScreen());
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    const PhysicianYuktiBanner(),
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

// ─────────────────────────────────────────────────────────────────────────────
// Phase card — no locking, neutral status indicator
// ─────────────────────────────────────────────────────────────────────────────

class _PhaseCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final _PhaseStatus status;
  final VoidCallback? onTap;

  const _PhaseCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: status == _PhaseStatus.completed
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
                    style: AppTextStyles.sectionHeading,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.captionText,
                  ),
                ],
              ),
            ),
            // Status indicator — neutral, never a lock
            _StatusBadge(status: status, color: color),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge: ✓ Completed | ● In Progress | ○ Not Started
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final _PhaseStatus status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _PhaseStatus.completed:
        return const Icon(
          Icons.check_circle_rounded,
          color: AppColors.successGreen,
          size: 24,
        );
      case _PhaseStatus.inProgress:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radio_button_checked_rounded,
                color: color.withValues(alpha: 0.7), size: 18),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        );
      case _PhaseStatus.notStarted:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radio_button_unchecked_rounded,
                color: AppColors.darkGrey, size: 18),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        );
    }
  }
}
