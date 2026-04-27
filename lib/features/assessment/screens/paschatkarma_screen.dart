import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/widgets/app_dropdown.dart';
import '../controller/assessment_controller.dart';
import '../widgets/assessment_widgets.dart';

class PaschatkarmaScreen extends StatelessWidget {
  const PaschatkarmaScreen({super.key});

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
