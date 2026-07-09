import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/core/theme/app_text_styles.dart';
import '../../../app/shared/widgets/app_dropdown.dart';
import '../controller/assessment_controller.dart';
import '../widgets/assessment_widgets.dart';

class PurvakarmaScreen extends StatefulWidget {
  const PurvakarmaScreen({super.key});

  @override
  State<PurvakarmaScreen> createState() => _PurvakarmaScreenState();
}

class _PurvakarmaScreenState extends State<PurvakarmaScreen> {
  final _pageCtrl = PageController();
  int _step = 0;

  static const int _totalSteps = 6;
  static const List<String> _stepTitles = [
    'Niruha Basti — Eligibility',
    'Anuvasana Basti — Eligibility',
    'Pariksha',
    'Agni Assessment',
    'Koshtha Assessment',
    'Saama, Nirama & Bala',
  ];

  void _next() {
    if (_step >= _totalSteps - 1) return;
    setState(() => _step++);
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _prev() {
    if (_step == 0) {
      Get.back();
      return;
    }
    setState(() => _step--);
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
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
              phase: 'Purvakarma',
              subTitle: _stepTitles[_step],
              onBack: _prev,
              currentStep: _step + 1,
              totalSteps: _totalSteps,
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _NiruhaPage(),
                  _AnuvasanPage(),
                  _ParikshaPage(),
                  _AgniPage(),
                  _KoshthaPage(),
                  _SaamaNiramaAndBalaPage(),
                ],
              ),
            ),
            _buildNav(ctrl),
          ],
        ),
      ),
    );
  }

  Widget _buildNav(AssessmentController ctrl) {
    final isLast = _step == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _prev,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  foregroundColor: AppColors.primaryGreen,
                ),
                child: const Text('Previous', style: AppTextStyles.button),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: isLast ? 2 : 1,
            child: isLast
                ? Obx(() {
                    final canComplete = ctrl.canCompletePurvakarma;
                    return ElevatedButton(
                      onPressed: canComplete
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canComplete
                            ? AppColors.primaryGreen
                            : AppColors.darkGrey.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: canComplete ? 3 : 0,
                        shadowColor:
                            AppColors.primaryGreen.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Complete Purvakarma',
                        style: AppTextStyles.button,
                      ),
                    );
                  })
                : ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shadowColor:
                          AppColors.primaryGreen.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Next', style: AppTextStyles.button),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 1 — Niruha Basti Eligibility
// ─────────────────────────────────────────────────────────────────────────────

class _NiruhaPage extends StatelessWidget {
  const _NiruhaPage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: AssessmentCard(
        title: 'Niruha Basti — Eligibility Check',
        icon: Icons.fact_check_outlined,
        trailing: _CitationBadge(text: 'Cha. Si. 1/3-4, 2/14'),
        children: [
          Text(
            'Answer all questions. A single "Yes" contraindicates Niruha Basti.',
            style: AssessmentTextStyles.noteText,
          ),
          const SizedBox(height: 14),
          ...List.generate(
            AssessmentController.niruhaQuestions.length,
            (i) => Obx(
              () => Column(
                children: [
                  _EligibilityQuestionRow(
                    index: i + 1,
                    question: AssessmentController.niruhaQuestions[i],
                    value: ctrl.niruhaAnswers[i],
                    onChanged: (v) => ctrl.setNiruhaAnswer(i, v),
                  ),
                  if (i < AssessmentController.niruhaQuestions.length - 1)
                    const Divider(height: 1, color: Color(0xFFF0EDE8), thickness: 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Obx(() {
            if (!ctrl.niruhaAllAnswered) return const SizedBox.shrink();
            return ctrl.isNiruhaEligible
                ? const ResultBanner(
                    message: 'Eligible — No Niruha Basti contraindications detected.',
                    type: BannerType.success,
                  )
                : const ResultBanner(
                    message: 'Contraindicated — Niruha Basti is not indicated. One or more contraindications present.',
                    type: BannerType.danger,
                  );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2 — Anuvasana Basti Eligibility
// ─────────────────────────────────────────────────────────────────────────────

class _AnuvasanPage extends StatelessWidget {
  const _AnuvasanPage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          // ── Niruha result context banner for Q1 ──────────────────────────
          Obx(() {
            if (!ctrl.niruhaAllAnswered) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ctrl.isNiruhaEligible
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ctrl.isNiruhaEligible
                      ? const Color(0xFF43A047)
                      : const Color(0xFFE53935),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    ctrl.isNiruhaEligible
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                    size: 16,
                    color: ctrl.isNiruhaEligible
                        ? const Color(0xFF43A047)
                        : const Color(0xFFE53935),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Niruha Basti result: ${ctrl.isNiruhaEligible ? "Eligible" : "Contraindicated"} — use this to answer Q1 below.',
                      style: AssessmentTextStyles.noteText.copyWith(
                        color: ctrl.isNiruhaEligible
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          AssessmentCard(
            title: 'Anuvasana Basti — Eligibility Check',
            icon: Icons.fact_check_outlined,
            trailing: _CitationBadge(text: 'Cha. Si. 2/17'),
            children: [
              Text(
                'Answer all questions. A single "Yes" contraindicates Anuvasana Basti.',
                style: AssessmentTextStyles.noteText,
              ),
              const SizedBox(height: 14),
              ...List.generate(
                AssessmentController.anuvasanQuestions.length,
                (i) => Obx(
                  () => Column(
                    children: [
                      _EligibilityQuestionRow(
                        index: i + 1,
                        question: AssessmentController.anuvasanQuestions[i],
                        value: ctrl.anuvasanAnswers[i],
                        onChanged: (v) => ctrl.setAnuvasanAnswer(i, v),
                      ),
                      if (i < AssessmentController.anuvasanQuestions.length - 1)
                        const Divider(height: 1, color: Color(0xFFF0EDE8), thickness: 1),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Obx(() {
                if (!ctrl.anuvasanAllAnswered) return const SizedBox.shrink();
                return ctrl.isAnuvasanEligible
                    ? const ResultBanner(
                        message: 'Eligible — No Anuvasana Basti contraindications detected.',
                        type: BannerType.success,
                      )
                    : const ResultBanner(
                        message: 'Contraindicated — Anuvasana Basti is not indicated. One or more contraindications present.',
                        type: BannerType.danger,
                      );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 3 — Pariksha (auto-filled from CRF)
// ─────────────────────────────────────────────────────────────────────────────

class _ParikshaPage extends StatelessWidget {
  const _ParikshaPage();

  static AppBottomSheet<String> _drop({
    required String label,
    required Rxn<String> rxn,
    required List<String> options,
    bool required = false,
  }) =>
      AppBottomSheet<String>(
        label: label,
        hint: 'Select $label',
        value: rxn.value,
        required: required,
        onChanged: (v) => rxn.value = v,
        options: options.map((o) => BottomSheetOption(value: o, label: o)).toList(),
      );

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    const pmaOptions = ['Pravar', 'Madhyam', 'Avara'];
    const prakritiOptions = [
      'Vata Pradhana',
      'Pitta Pradhana',
      'Kapha Pradhana',
      'Vata-Pitta',
      'Vata-Kapha',
      'Pitta-Kapha',
      'Sama',
    ];
    const jihwaOptions = ['Nirlipta', 'Ishat Lipta', 'Lipta'];
    const vayaOptions = [
      'Bala (Child 0–16)',
      'Madhyama (Adult 16–60)',
      'Vriddha (Old 60+)',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: AssessmentCard(
        title: 'Pariksha',
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
          Obx(() => _drop(
                label: 'Prakriti',
                rxn: ctrl.parikshaPrakriti,
                options: prakritiOptions,
                required: true,
              )),
          Obx(() => _drop(
                label: 'Sarataha',
                rxn: ctrl.parikshaSarataha,
                options: pmaOptions,
              )),
          Obx(() => _drop(
                label: 'Sanhanan',
                rxn: ctrl.parikshaSanhanan,
                options: pmaOptions,
              )),
          Obx(() => _drop(
                label: 'Pramana',
                rxn: ctrl.parikshaPramana,
                options: pmaOptions,
              )),
          Obx(() => _drop(
                label: 'Satva',
                rxn: ctrl.parikshaSatva,
                options: pmaOptions,
              )),
          Obx(() => _drop(
                label: 'Satmya (Sneha Satmya)',
                rxn: ctrl.parikshaSatmya,
                options: pmaOptions,
              )),
          Obx(() => _drop(
                label: 'Ahara Shakti',
                rxn: ctrl.parikshAhara,
                options: pmaOptions,
              )),
          Obx(() => _drop(
                label: 'Vyayama Shakti',
                rxn: ctrl.parikshVyayama,
                options: pmaOptions,
              )),
          Obx(() =>
              _drop(label: 'Vaya', rxn: ctrl.parikshVaya, options: vayaOptions)),
          Obx(() => _drop(
                label: 'Jihwa',
                rxn: ctrl.parikshJihwa,
                options: jihwaOptions,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 4 — Agni Assessment
// ─────────────────────────────────────────────────────────────────────────────

class _AgniPage extends StatelessWidget {
  const _AgniPage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: AssessmentCard(
        title: 'Agni Assessment',
        icon: Icons.local_fire_department_outlined,
        children: [
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
            "Select the option that best describes the patient's food intake.",
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
            "Select the option that best describes the patient's appetite.",
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
          Obx(() {
            if (!ctrl.agniAllAnswered) return const SizedBox.shrink();
            return ResultBanner(
              message: 'Agni Status: ${ctrl.agniResult}',
              type: BannerType.info,
              icon: Icons.local_fire_department_rounded,
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 5 — Koshtha Assessment
// ─────────────────────────────────────────────────────────────────────────────

class _KoshthaPage extends StatelessWidget {
  const _KoshthaPage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: AssessmentCard(
        title: 'Koshtha Assessment',
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 6 — Saama / Nirama Lakshana + Bala Assessment
// ─────────────────────────────────────────────────────────────────────────────

class _SaamaNiramaAndBalaPage extends StatelessWidget {
  const _SaamaNiramaAndBalaPage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          // ── Saama / Nirama ──
          AssessmentCard(
            title: 'Saama / Nirama Lakshana',
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
                            thickness: 1),
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
          ),

          // ── Bala Assessment ──
          AssessmentCard(
            title: 'Bala Assessment',
            icon: Icons.fitness_center_outlined,
            children: [
              Text(
                'Select the patient\'s overall strength (Bala).',
                style: AssessmentTextStyles.noteText,
              ),
              const SizedBox(height: 12),
              Obx(
                () => Column(
                  children: AssessmentController.balaOptions.map((opt) {
                    final selected = ctrl.bala.value == opt;
                    return GestureDetector(
                      onTap: () => ctrl.bala.value = opt,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryGreen.withValues(alpha: 0.08)
                              : AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryGreen
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 20,
                              color: selected
                                  ? AppColors.primaryGreen
                                  : AppColors.darkGrey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                opt,
                                style: AssessmentTextStyles.optionText.copyWith(
                                  color: selected
                                      ? AppColors.textDarkGreen
                                      : AppColors.darkGrey,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: classical text citation badge
// ─────────────────────────────────────────────────────────────────────────────

class _CitationBadge extends StatelessWidget {
  final String text;
  const _CitationBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: numbered eligibility question row with Yes/No chips
// ─────────────────────────────────────────────────────────────────────────────

class _EligibilityQuestionRow extends StatelessWidget {
  final int index;
  final String question;
  final bool? value;
  final ValueChanged<bool> onChanged;

  const _EligibilityQuestionRow({
    required this.index,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question number badge
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1, right: 8),
                decoration: BoxDecoration(
                  color: value == true
                      ? AppColors.errorRed.withValues(alpha: 0.1)
                      : value == false
                          ? AppColors.successGreen.withValues(alpha: 0.1)
                          : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: value == true
                          ? AppColors.errorRed
                          : value == false
                              ? AppColors.successGreen
                              : AppColors.darkGrey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  question,
                  style: AssessmentTextStyles.questionText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _EligChip(
                label: 'Yes',
                isSelected: value == true,
                activeColor: AppColors.errorRed,
                onTap: () => onChanged(true),
              ),
              const SizedBox(width: 8),
              _EligChip(
                label: 'No',
                isSelected: value == false,
                activeColor: AppColors.successGreen,
                onTap: () => onChanged(false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EligChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _EligChip({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFDDD8D0),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AssessmentTextStyles.chipLabel.copyWith(
            color: isSelected ? activeColor : AppColors.darkGrey,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
