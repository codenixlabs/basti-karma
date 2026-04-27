import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/widgets/app_dropdown.dart';
import '../controller/assessment_controller.dart';
import '../widgets/assessment_widgets.dart';

class PurvakarmaScreen extends StatelessWidget {
  const PurvakarmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            AssessmentPageHeader(
              phase: 'Purvakarma',
              subTitle: 'Pre-procedure assessment — ${ctrl.patientName}',
              onBack: () => Get.back(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  children: [
                    _NiruhaEligibilitySection(),
                    _AnuvasanEligibilitySection(),
                    _ParikshaSection(),
                    _AgniSection(),
                    _KoshthaSection(),
                    _SaamaNiramaSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Obx(
              () => AssessmentBottomButton(
                label: 'Complete Purvakarma',
                onPressed: ctrl.canCompletePurvakarma
                    ? () {
                        ctrl.completePurvakarma();
                        Get.back();
                        Get.snackbar(
                          'Purvakarma Complete',
                          'Pradhan Karma phase is now unlocked.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.successGreen,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 3),
                          margin: const EdgeInsets.all(16),
                          borderRadius: 14,
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A. Niruha Basti eligibility
// ─────────────────────────────────────────────────────────────────────────────

class _NiruhaEligibilitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return AssessmentCard(
      title: 'A. Niruha Basti — Eligibility',
      icon: Icons.fact_check_outlined,
      children: [
        Text(
          'Answer all questions. If any is "Yes", Niruha Basti is contraindicated.',
          style: AssessmentTextStyles.noteText,
        ),
        const SizedBox(height: 12),
        ...List.generate(
          AssessmentController.niruhaQuestions.length,
          (i) => Obx(
            () => Column(
              children: [
                YesNoChipRow(
                  question: AssessmentController.niruhaQuestions[i],
                  value: ctrl.niruhaAnswers[i],
                  onChanged: (v) => ctrl.setNiruhaAnswer(i, v),
                ),
                if (i < AssessmentController.niruhaQuestions.length - 1)
                  const Divider(
                    height: 1,
                    color: Color(0xFFF0EDE8),
                    thickness: 1,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Result banner
        Obx(() {
          if (!ctrl.niruhaAllAnswered) return const SizedBox.shrink();
          return ctrl.isNiruhaEligible
              ? const ResultBanner(
                  message:
                      'Eligible — No Niruha Basti contraindications detected.',
                  type: BannerType.success,
                )
              : const ResultBanner(
                  message:
                      'Contraindicated — Niruha Basti is not indicated. One or more contraindications present.',
                  type: BannerType.danger,
                );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A. Anuvasan Basti eligibility
// ─────────────────────────────────────────────────────────────────────────────

class _AnuvasanEligibilitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return AssessmentCard(
      title: 'A. Anuvasan Basti — Eligibility',
      icon: Icons.fact_check_outlined,
      children: [
        Text(
          'Answer all questions. If any is "Yes", Anuvasan Basti is contraindicated.',
          style: AssessmentTextStyles.noteText,
        ),
        const SizedBox(height: 12),
        ...List.generate(
          AssessmentController.anuvasanQuestions.length,
          (i) => Obx(
            () => Column(
              children: [
                YesNoChipRow(
                  question: AssessmentController.anuvasanQuestions[i],
                  value: ctrl.anuvasanAnswers[i],
                  onChanged: (v) => ctrl.setAnuvasanAnswer(i, v),
                ),
                if (i < AssessmentController.anuvasanQuestions.length - 1)
                  const Divider(
                    height: 1,
                    color: Color(0xFFF0EDE8),
                    thickness: 1,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Obx(() {
          if (!ctrl.anuvasanAllAnswered) return const SizedBox.shrink();
          return ctrl.isAnuvasanEligible
              ? const ResultBanner(
                  message:
                      'Eligible — No Anuvasan Basti contraindications detected.',
                  type: BannerType.success,
                )
              : const ResultBanner(
                  message:
                      'Contraindicated — Anuvasan Basti is not indicated. One or more contraindications present.',
                  type: BannerType.danger,
                );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// B. Pariksha (auto-filled from CRF)
// ─────────────────────────────────────────────────────────────────────────────

class _ParikshaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    List<String> pmaOptions = ['Pravar', 'Madhyam', 'Avara'];
    List<String> prakritiOptions = [
      'Vata Pradhana',
      'Pitta Pradhana',
      'Kapha Pradhana',
      'Vata-Pitta',
      'Vata-Kapha',
      'Pitta-Kapha',
      'Sama',
    ];
    List<String> jihwaOptions = ['Nirlipta', 'Ishat Lipta', 'Lipta'];
    List<String> vayaOptions = [
      'Bala (Child 0–16)',
      'Madhyama (Adult 16–60)',
      'Vriddha (Old 60+)',
    ];

    AppBottomSheet<String> _drop({
      required String label,
      required Rxn<String> rxn,
      required List<String> options,
      bool required = false,
    }) => AppBottomSheet<String>(
      label: label,
      hint: 'Select $label',
      value: rxn.value,
      required: required,
      onChanged: (v) => rxn.value = v,
      options: options
          .map((o) => BottomSheetOption(value: o, label: o))
          .toList(),
    );

    return AssessmentCard(
      title: 'B. Pariksha',
      icon: Icons.person_search_outlined,
      trailing: Text(
        'Auto-filled from CRF',
        style: AssessmentTextStyles.hintText.copyWith(fontSize: 11),
      ),
      children: [
        Text(
          'Values pre-filled from the patient\'s CRF. Update if needed.',
          style: AssessmentTextStyles.noteText,
        ),
        const SizedBox(height: 12),
        Obx(
          () => _drop(
            label: 'Prakriti',
            rxn: ctrl.parikshaPrakriti,
            options: prakritiOptions,
            required: true,
          ),
        ),
        Obx(
          () => _drop(
            label: 'Sarataha',
            rxn: ctrl.parikshaSarataha,
            options: pmaOptions,
          ),
        ),
        Obx(
          () => _drop(
            label: 'Sanhanan',
            rxn: ctrl.parikshaSanhanan,
            options: pmaOptions,
          ),
        ),
        Obx(
          () => _drop(
            label: 'Pramana',
            rxn: ctrl.parikshaPramana,
            options: pmaOptions,
          ),
        ),
        Obx(
          () => _drop(
            label: 'Satva',
            rxn: ctrl.parikshaSatva,
            options: pmaOptions,
          ),
        ),
        Obx(
          () => _drop(
            label: 'Satmya (Sneha Satmya)',
            rxn: ctrl.parikshaSatmya,
            options: pmaOptions,
          ),
        ),
        Obx(
          () => _drop(
            label: 'Ahara Shakti',
            rxn: ctrl.parikshAhara,
            options: pmaOptions,
          ),
        ),
        Obx(
          () => _drop(
            label: 'Vyayama Shakti',
            rxn: ctrl.parikshVyayama,
            options: pmaOptions,
          ),
        ),
        Obx(
          () =>
              _drop(label: 'Vaya', rxn: ctrl.parikshVaya, options: vayaOptions),
        ),
        Obx(
          () => _drop(
            label: 'Jihwa',
            rxn: ctrl.parikshJihwa,
            options: jihwaOptions,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// C. Agni Assessment  (scoring hidden from doctor)
// ─────────────────────────────────────────────────────────────────────────────

class _AgniSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return AssessmentCard(
      title: 'C. Agni Assessment',
      icon: Icons.local_fire_department_outlined,
      children: [
        // ── Jaran Shakti (multi-select symptoms) ────
        Text('Jaran Shakti', style: AssessmentTextStyles.sectionTitle),
        const SizedBox(height: 4),
        Text(
          'Select all symptoms currently present in the patient.',
          style: AssessmentTextStyles.noteText,
        ),
        const SizedBox(height: 10),
        Obx(
          () => Column(
            children: List.generate(
              AssessmentController.jaranShaktiSymptoms.length,
              (i) => CheckableSymptomRow(
                label: AssessmentController.jaranShaktiSymptoms[i],
                isChecked: ctrl.jaranShaktiSelected.contains(i),
                onTap: () => ctrl.toggleJaranSymptom(i),
              ),
            ),
          ),
        ),

        const LabeledDivider(label: 'Abhyavaharana Shakti'),

        Text('Abhyavaharana Shakti', style: AssessmentTextStyles.sectionTitle),
        const SizedBox(height: 4),
        Text(
          'Select the option that best describes the patient\'s food intake.',
          style: AssessmentTextStyles.noteText,
        ),
        const SizedBox(height: 10),
        Obx(
          () => Column(
            children: List.generate(
              AssessmentController.abhyavaharanaOptions.length,
              (i) => SelectableOptionRow(
                label: AssessmentController.abhyavaharanaOptions[i],
                isSelected: ctrl.abhyavaharanaIndex.value == i,
                onTap: () => ctrl.setAbhyavaharana(i),
              ),
            ),
          ),
        ),

        const LabeledDivider(label: 'Ruchi'),

        Text('Ruchi', style: AssessmentTextStyles.sectionTitle),
        const SizedBox(height: 4),
        Text(
          'Select the option that best describes the patient\'s appetite.',
          style: AssessmentTextStyles.noteText,
        ),
        const SizedBox(height: 10),
        Obx(
          () => Column(
            children: List.generate(
              AssessmentController.ruchiOptions.length,
              (i) => SelectableOptionRow(
                label: AssessmentController.ruchiOptions[i],
                isSelected: ctrl.ruchiIndex.value == i,
                onTap: () => ctrl.setRuchi(i),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        // Result — category only, no numbers shown
        Obx(() {
          if (!ctrl.agniAllAnswered) return const SizedBox.shrink();
          return ResultBanner(
            message: 'Agni Status: ${ctrl.agniResult}',
            type: BannerType.info,
            icon: Icons.local_fire_department_rounded,
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// D. Koshtha  (scoring hidden)
// ─────────────────────────────────────────────────────────────────────────────

class _KoshthaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return AssessmentCard(
      title: 'D. Koshtha Assessment',
      icon: Icons.straighten_outlined,
      children: [
        Text(
          'Select one option for each question.',
          style: AssessmentTextStyles.noteText,
        ),
        const SizedBox(height: 12),
        ...List.generate(
          AssessmentController.koshthaQuestions.length,
          (qi) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (qi > 0) const SizedBox(height: 14),
              Text(
                '${qi + 1}. ${AssessmentController.koshthaQuestions[qi]}',
                style: AssessmentTextStyles.questionText,
              ),
              const SizedBox(height: 8),
              Obx(
                () => Column(
                  children: List.generate(
                    AssessmentController.koshthaOptions[qi].length,
                    (oi) => SelectableOptionRow(
                      label: AssessmentController.koshthaOptions[qi][oi],
                      isSelected: ctrl.koshthaAnswers[qi] == oi + 1,
                      onTap: () => ctrl.setKoshtha(qi, oi),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (!ctrl.koshthaAllAnswered) return const SizedBox.shrink();
          return ResultBanner(
            message: 'Koshtha: ${ctrl.koshthaResult}',
            type: BannerType.info,
            icon: Icons.straighten_rounded,
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// E. Saama / Nirama Lakshana
// ─────────────────────────────────────────────────────────────────────────────

class _SaamaNiramaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return AssessmentCard(
      title: 'E. Saama / Nirama Lakshana',
      icon: Icons.balance_outlined,
      children: [
        Text(
          'Mark all symptoms currently present in the patient.',
          style: AssessmentTextStyles.noteText,
        ),
        const SizedBox(height: 12),
        ...List.generate(
          AssessmentController.saamaSymptoms.length,
          (i) => Obx(
            () => Column(
              children: [
                YesNoChipRow(
                  question: AssessmentController.saamaSymptoms[i],
                  value: ctrl.saamaAnswers[i],
                  onChanged: (v) => ctrl.setSaama(i, v),
                ),
                if (i < AssessmentController.saamaSymptoms.length - 1)
                  const Divider(
                    height: 1,
                    color: Color(0xFFF0EDE8),
                    thickness: 1,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Obx(() {
          if (!ctrl.saamaAllAnswered) return const SizedBox.shrink();
          if (ctrl.hasSaamaLakshana) {
            return Column(
              children: [
                const ResultBanner(
                  message:
                      'Saama Avastha — Perform Deepan Pachana before proceeding with Basti karma.',
                  type: BannerType.warning,
                ),
                PrescriptionBox(
                  title: 'Recommended Deepan Pachana',
                  content: ctrl.agniDeepanPachana,
                ),
              ],
            );
          }
          return const ResultBanner(
            message: 'Nirama Avastha — Patient is ready for Basti karma.',
            type: BannerType.success,
          );
        }),
      ],
    );
  }
}
