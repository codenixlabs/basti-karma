import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/widgets/app_dialog.dart';
import '../../../app/shared/widgets/app_dropdown.dart';
import '../controller/assessment_controller.dart';
import '../widgets/assessment_widgets.dart';

import '../../../app/core/theme/app_text_styles.dart';
import '../../../app/shared/widgets/physician_yukti_banner.dart';

class PaschatkarmaScreen extends StatefulWidget {
  const PaschatkarmaScreen({super.key});

  @override
  State<PaschatkarmaScreen> createState() => _PaschatkarmaScreenState();
}

class _PaschatkarmaScreenState extends State<PaschatkarmaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AssessmentController>().loadPaschatkarma();
    });
  }

  Future<void> _showSaveErrorDialog({
    required VoidCallback onRetry,
    required String message,
  }) async {
    final isNetwork = message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('connection') ||
        message.toLowerCase().contains('network');
    final isAuth = message.toLowerCase().contains('credential') ||
        message.toLowerCase().contains('session') ||
        message.toLowerCase().contains('unauthorized') ||
        message.toLowerCase().contains('token');
    final iconData = isNetwork
        ? Icons.wifi_off_rounded
        : (isAuth ? Icons.lock_clock_outlined : Icons.error_outline_rounded);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AppDialog(
        icon: iconData,
        iconColor: AppColors.errorRed,
        title: 'Save Failed',
        content: message,
        cancelText: 'Stay',
        confirmText: 'Retry',
        confirmIcon: Icons.refresh_rounded,
        confirmColor: AppColors.primaryGreen,
        onCancel: () => Navigator.of(dialogCtx).pop(),
        onConfirm: () {
          Navigator.of(dialogCtx).pop();
          onRetry();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            AssessmentPageHeader(
              phase: 'Paschatkarma',
              subTitle: 'Post-procedure care — ${ctrl.patientName}',
              onBack: () => Get.back(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  children: [
                    _VapayadaSection(),
                    _PariharaSection(),
                    _DietSection(),
                    const SizedBox(height: 16),
                    // Note about serious complications
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFF9A825).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: Color(0xFFF9A825),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'In more serious complications, the patient should be transferred to a higher centre.',
                              style: AssessmentTextStyles.noteText.copyWith(
                                color: const Color(0xFF7B5E00),
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const PhysicianYuktiBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Obx(() {
            final isSaving = ctrl.isSavingPaschatkarma.value;
            final isCompleted = ctrl.paschatkarmaComplete.value;
            return ElevatedButton.icon(
              onPressed: isSaving
                  ? null
                  : () async {
                      final ok = await ctrl.savePaschatkarma();
                      if (!ok) {
                        final errorMsg = ctrl.paschatkarmaError.value;
                        final msg = (errorMsg != null && errorMsg.isNotEmpty)
                            ? errorMsg
                            : 'Could not save Paschata Karma. Please try again.';
                        await _showSaveErrorDialog(
                          onRetry: () async {
                            final retryOk = await ctrl.savePaschatkarma();
                            if (retryOk) {
                              Get.back();
                              Get.snackbar(
                                'Paschatkarma Saved',
                                'Post-procedure care assessment saved successfully.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.successGreen,
                                colorText: Colors.white,
                                duration: const Duration(seconds: 3),
                                margin: const EdgeInsets.all(16),
                                borderRadius: 14,
                              );
                            }
                          },
                          message: msg,
                        );
                        return;
                      }
                      Get.back();
                      Get.snackbar(
                        'Paschatkarma Complete',
                        'Post-procedure care assessment saved successfully.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.successGreen,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                        margin: const EdgeInsets.all(16),
                        borderRadius: 14,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSaving
                    ? AppColors.darkGrey.withValues(alpha: 0.3)
                    : AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: isSaving ? 0 : 3,
                shadowColor: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
              icon: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(
                isCompleted ? 'Update Paschatkarma' : 'Complete Paschatkarma',
                style: AppTextStyles.button,
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Vyapada identification + Chikitsa
// ─────────────────────────────────────────────────────────────────────────────

class _VapayadaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return AssessmentCard(
      title: '1. Vyapada & Management',
      icon: Icons.medical_information_outlined,
      children: [
        // ── Niruha Vyapada ─────────────────────────────────────────────────
        Text('Niruha Basti Vyapada', style: AssessmentTextStyles.sectionTitle),
        const SizedBox(height: 6),
        Obx(
          () => AppBottomSheet<String>(
            label: 'Observed complication',
            hint: 'Select complication (if any)',
            value: ctrl.selectedNiruhaVyapada.value,
            onChanged: (v) => ctrl.selectedNiruhaVyapada.value = v,
            options: AssessmentController.niruhaVyapadas
                .map((v) => BottomSheetOption(value: v, label: v))
                .toList(),
          ),
        ),
        // Show Chikitsa when a complication is selected
        Obx(() {
          final chikitsa = ctrl.niruhaChikitsaText;
          if (chikitsa == null) return const SizedBox.shrink();
          return PrescriptionBox(
            title: 'Niruha Vyapada — Chikitsa',
            content: chikitsa,
          );
        }),

        const LabeledDivider(label: 'Anuvasan Basti'),

        // ── Anuvasan Vyapada ───────────────────────────────────────────────
        Text(
          'Anuvasan Basti Vyapada',
          style: AssessmentTextStyles.sectionTitle,
        ),
        const SizedBox(height: 6),
        Obx(
          () => AppBottomSheet<String>(
            label: 'Observed complication',
            hint: 'Select complication (if any)',
            value: ctrl.selectedAnuvasanVyapada.value,
            onChanged: (v) => ctrl.selectedAnuvasanVyapada.value = v,
            options: AssessmentController.anuvasanVyapadas
                .map((v) => BottomSheetOption(value: v, label: v))
                .toList(),
          ),
        ),
        Obx(() {
          final chikitsa = ctrl.anuvasanChikitsaText;
          if (chikitsa == null) return const SizedBox.shrink();
          return PrescriptionBox(
            title: 'Anuvasan Vyapada — Chikitsa',
            content: chikitsa,
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Parihara vishaya (restrictions checklist — read-only, always shown)
// ─────────────────────────────────────────────────────────────────────────────

class _PariharaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AssessmentCard(
      title: '2. Parihara Vishaya & Kala',
      icon: Icons.list_alt_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'For patient',
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      children: [
        Text(
          'Patient should follow these restrictions for double the duration of treatment.',
          style: AssessmentTextStyles.noteText,
        ),
        const SizedBox(height: 12),
        ...AssessmentController.pariharaItems.map(
          (item) => _PariharaItem(text: item),
        ),
      ],
    );
  }
}

class _PariharaItem extends StatelessWidget {
  final String text;

  const _PariharaItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AssessmentTextStyles.optionText)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Diet
// ─────────────────────────────────────────────────────────────────────────────

class _DietSection extends StatelessWidget {
  static const List<String> _dietItems = [
    'Take light and easily digestible food (Laghu Supachya Ahara)',
    'Avoid heavy, oily, or incompatible foods',
    'Prefer warm, freshly cooked, simple meals',
    'Avoid cold, stale, or processed food items',
    'Avoid excessive quantity of food',
    'Follow diet restrictions for double the duration of Basti administration (Dwikala — Cha. Si. 1/54)',
  ];

  @override
  Widget build(BuildContext context) {
    return AssessmentCard(
      title: '3. Diet',
      icon: Icons.restaurant_menu_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'For patient',
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      children: [
        Text(
          'Dietary restrictions should be followed for double the number of days Basti was administered (Dwikala).',
          style: AssessmentTextStyles.noteText,
        ),
        const SizedBox(height: 12),
        ..._dietItems.map((item) => _DietItem(text: item)),
      ],
    );
  }
}

class _DietItem extends StatelessWidget {
  final String text;

  const _DietItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AssessmentTextStyles.optionText)),
        ],
      ),
    );
  }
}
