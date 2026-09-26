import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/core/theme/app_text_styles.dart';
import '../../../app/data/services/basti_dose_calculator_service.dart';
import '../../../app/shared/widgets/app_dialog.dart';
import '../../../app/shared/widgets/app_dropdown.dart';
import '../controller/assessment_controller.dart';
import '../controller/treatment_plan_controller.dart';
import '../widgets/assessment_widgets.dart';
import '../widgets/basti_option_card.dart';
import '../widgets/dose_breakdown_card.dart';
import '../widgets/basti_pattern_selector.dart';
import '../../../app/shared/widgets/physician_yukti_banner.dart';

class PradhanKarmaScreen extends StatefulWidget {
  final int initialStep;

  const PradhanKarmaScreen({super.key, this.initialStep = 0});

  @override
  State<PradhanKarmaScreen> createState() => _PradhanKarmaScreenState();
}

class _PradhanKarmaScreenState extends State<PradhanKarmaScreen> {
  late final PageController _pageCtrl;
  late int _step;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AssessmentController>()) {
      final ctrl = Get.find<AssessmentController>();
      ctrl.syncBalaFromPoorvaKarma();
      if (!ctrl.isLoadingPradhanaKarma.value && !ctrl.hasLoadedPradhanaKarma) {
        ctrl.loadPradhanaKarma().then((_) {
          if (mounted && widget.initialStep == 0 && ctrl.loggedSessionCount > 0) {
            setState(() {
              _step = 3;
              _pageCtrl.jumpToPage(3);
            });
          }
        });
      }
    }
    _step = widget.initialStep;
    _pageCtrl = PageController(initialPage: widget.initialStep);
  }

  static const int _totalSteps = 4;
  static const List<String> _stepTitles = [
    'Disease & Basti Selection',
    'Dose Breakdown & Matra',
    'Basti Pattern Selection',
    'Treatment Schedule & Observation Log',
  ];

  bool _isNavigating = false;

  Future<void> _next() async {
    if (_isNavigating) return;
    if (_step >= _totalSteps - 1) return;

    // ── Clinical prerequisite validation at progression points ───────────────
    // Step 0 → Step 1: Dose Breakdown requires Bala (for dose calculation)
    if (_step == 0) {
      final ctrl = Get.find<AssessmentController>();
      if (ctrl.isLoadingClinicalData.value) return;

      if (ctrl.bala.value == null || ctrl.bala.value!.isEmpty) {
        await ctrl.syncBalaFromPoorvaKarma();
      }
      if (ctrl.bala.value == null || ctrl.bala.value!.isEmpty) {
        ctrl.bala.value = 'Madhyama';
      }
      if (ctrl.selectedBastiOption.value == null) {
        Get.snackbar(
          'Basti Selection Required',
          'Please select a Basti formulation before proceeding.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE65100),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        );
        return;
      }
    }

    // Step 1 → Step 2: Pattern Selection requires dose to be calculated
    if (_step == 1) {
      final ctrl = Get.find<AssessmentController>();
      if (ctrl.calculatedNiruhaDose.value == null &&
          ctrl.calculatedAnuvasanaDose.value == null &&
          ctrl.calculatedMatraDose.value == null &&
          ctrl.calculatedYapanaDose.value == null) {
        Get.snackbar(
          'Dose Calculation Required',
          'Please ensure the dose is calculated before selecting a Basti pattern.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE65100),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        );
        return;
      }
    }

    // Step 2 → Step 3: Persist the confirmed treatment plan before starting observation log
    if (_step == 2) {
      final ctrl = Get.find<AssessmentController>();
      ctrl.persistTreatmentPlan();
    }

    _isNavigating = true;
    setState(() => _step++);
    _pageCtrl
        .nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (mounted) setState(() => _isNavigating = false);
        });
  }

  void _prev() {
    if (_isNavigating) return;
    if (_step == 0) {
      Get.back();
      return;
    }
    _isNavigating = true;
    setState(() => _step--);
    _pageCtrl
        .previousPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (mounted) setState(() => _isNavigating = false);
        });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    // Ensure TreatmentPlanController is available for this screen
    if (!Get.isRegistered<TreatmentPlanController>()) {
      Get.put(TreatmentPlanController());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AssessmentPageHeader(
              phase: 'Pradhan Karma',
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
                  _BastiTypePage(),
                  _DravyaDosePage(),
                  _SchedulePage(),
                  _ObservationPage(),
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
                    ctrl.observationTick.value;
                    final tpc = Get.isRegistered<TreatmentPlanController>()
                        ? Get.find<TreatmentPlanController>()
                        : null;
                    final total = ctrl.sessions.length;
                    final logged = ctrl.loggedSessionCount;
                    final isAllLogged =
                        (tpc != null && tpc.allSessionsCompleted) ||
                        (total > 0 && logged == total);

                    if (!isAllLogged) {
                      return OutlinedButton.icon(
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Continue Treatment',
                          style: AppTextStyles.button,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primaryGreen,
                            width: 1.5,
                          ),
                          foregroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Get.back(),
                      );
                    }

                    return ElevatedButton(
                      onPressed: () async {
                        if (_isCompleting) return;
                        _isCompleting = true;
                        try {
                          await ctrl.completePradhanKarma();
                          if (ctrl.pradhankarmaComplete.value) {
                            Get.back();
                            if (Get.isSnackbarOpen != true) {
                              Get.snackbar(
                                'Pradhan Karma Complete',
                                'Paschatkarma phase is now unlocked.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.successGreen,
                                colorText: Colors.white,
                                duration: const Duration(seconds: 3),
                                margin: const EdgeInsets.all(16),
                                borderRadius: 14,
                              );
                            }
                          }
                        } finally {
                          _isCompleting = false;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 3,
                        shadowColor: AppColors.primaryGreen.withValues(
                          alpha: 0.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Complete Pradhan Karma',
                        style: AppTextStyles.button,
                      ),
                    );
                  })
                : Obx(() {
                    final isLoadingClinical = ctrl.isLoadingClinicalData.value;
                    final isLoadingFormulations =
                        _step == 0 && isLoadingClinical;
                    final isDisabled = isLoadingFormulations || _isNavigating;

                    return ElevatedButton(
                      onPressed: isDisabled ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        disabledBackgroundColor: AppColors.primaryGreen
                            .withValues(alpha: 0.5),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 3,
                        shadowColor: AppColors.primaryGreen.withValues(
                          alpha: 0.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoadingFormulations
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Next', style: AppTextStyles.button),
                    );
                  }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 1 — Disease & Basti Selection
// ─────────────────────────────────────────────────────────────────────────────

class _BastiTypePage extends StatelessWidget {
  const _BastiTypePage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssessmentCard(
            title: 'Disease & Basti Selection',
            icon: Icons.category_outlined,
            children: [
              Obx(() {
                final diseases = ctrl.availableDiseases;
                final selected = ctrl.selectedDisease.value;
                return AppBottomSheet<String>(
                  label: 'Selected Disease / Diagnosis',
                  hint: 'Select disease',
                  value: selected?.id,
                  required: true,
                  showSearch: true,
                  searchHint: 'Search disease...',
                  sortAlphabetically: true,
                  addNewLabel: 'Add Other / New Disease',
                  onAddNew: (name) => ctrl.addNewDiseaseAndSelect(name),
                  onChanged: (id) {
                    final d = diseases.firstWhereOrNull(
                      (element) => element.id == id,
                    );
                    if (d != null) {
                      ctrl.selectDisease(d);
                    }
                  },
                  options: diseases
                      .map(
                        (d) => BottomSheetOption(
                          value: d.id,
                          label: d.displayLabel,
                        ),
                      )
                      .toList(),
                );
              }),
              const SizedBox(height: 16),
              Obx(() {
                final options = ctrl.availableBastiOptions;
                final selectedOption = ctrl.selectedBastiOption.value;
                final isLoading = ctrl.isLoadingClinicalData.value;
                final error = ctrl.clinicalDataError.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Available Formulations',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDarkGreen,
                          ),
                        ),
                        if (!isLoading &&
                            error.isEmpty &&
                            options.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.25,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '${options.length} ${options.length == 1 ? 'formulation' : 'formulations'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose and administer the appropriate Basti according to the physician’s Yukti',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkGrey,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (ctrl.isTreatmentPlanActive)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: AppColors.primaryGreen,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Treatment schedule is active. Formulation is locked.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDarkGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isLoading)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Loading Basti formulations...',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.darkGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (error.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade700,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => ctrl.loadClinicalMasterData(
                                forceRefresh: true,
                              ),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry Loading'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade800,
                                side: BorderSide(color: Colors.red.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (options.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No Basti Formulations Available',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDarkGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'No clinical formulations found for the selected disease.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.darkGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: options.map((opt) {
                          final isSel = selectedOption?.id == opt.id;
                          return BastiOptionCard(
                            option: opt,
                            isSelected: isSel,
                            onTap: () => ctrl.selectBastiOption(opt),
                          );
                        }).toList(),
                      ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          const PhysicianYuktiBanner(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2 — Dose Breakdown & Matra
// ─────────────────────────────────────────────────────────────────────────────

class _DravyaDosePage extends StatelessWidget {
  const _DravyaDosePage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AssessmentCard(
              title: 'Automated Dose & Formulation Breakdown',
              icon: Icons.science_outlined,
              children: [
                Obx(() {
                  final opt = ctrl.selectedBastiOption.value;
                  final bType = (opt?.bastiTypeCode.isNotEmpty == true ? opt!.bastiTypeCode : opt?.bastiTypeDisplay ?? '').toLowerCase();
                  
                  final niruha = ctrl.calculatedNiruhaDose.value;
                  final anuvasana = ctrl.calculatedAnuvasanaDose.value;
                  final matra = ctrl.calculatedMatraDose.value;
                  final yapana = ctrl.calculatedYapanaDose.value;
                  final activeBala = ctrl.bala.value ?? 'Avara';

                  List<DoseCalculationResult> doses = [];
                  if (bType.contains('yapana') || bType == 'yb') {
                    if (yapana == null) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                    doses.add(yapana);
                  } else if (bType.contains('matra') || (bType.contains('sneha') && !bType.contains('niruha')) || bType == 'mb') {
                    if (matra == null) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                    doses.add(matra);
                  } else {
                    if (niruha == null || anuvasana == null) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                    doses.add(niruha);
                    doses.add(anuvasana);
                  }

                  return DoseBreakdownCard(
                    doses: doses,
                    patientBala: activeBala,
                  );
                }),
                const SizedBox(height: 12),
                _AssessTextField(
                  controller: ctrl.formulationCtrl,
                  label: 'Formulation Details',
                  hint: 'Enter ingredients and preparation details',
                  maxLines: 4,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const PhysicianYuktiBanner(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 3 — Pattern Selection
// ─────────────────────────────────────────────────────────────────────────────

class _SchedulePage extends StatelessWidget {
  const _SchedulePage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AssessmentCard(
              title: 'Basti Treatment Pattern',
              icon: Icons.calendar_month_outlined,
              children: [
                if (ctrl.isTreatmentPlanActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Treatment schedule is active. Pattern is locked.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDarkGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Obx(() {
                  final patterns = ctrl.availablePatterns;
                  final selectedCode =
                      ctrl.selectedPattern.value?.code ?? 'yoga';
                  final activeBala = ctrl.bala.value ?? 'Avara';

                  return BastiPatternSelector(
                    patterns: patterns,
                    selectedPatternCode: selectedCode,
                    patientBala: activeBala,
                    onPatternSelected: (p) => ctrl.selectPattern(p),
                  );
                }),
                const SizedBox(height: 12),
                _AssessTextField(
                  controller: ctrl.scheduleCtrl,
                  label: 'Generated Pattern Sequence',
                  hint: 'Generated pattern schedule summary',
                  required: true,
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const PhysicianYuktiBanner(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 4 — Observation Log (session-based)
// ─────────────────────────────────────────────────────────────────────────────

class _ObservationPage extends StatefulWidget {
  const _ObservationPage();

  @override
  State<_ObservationPage> createState() => _ObservationPageState();
}

class _ObservationPageState extends State<_ObservationPage> {
  int? _expandedIndex;

  void _handleToggle(int i, AssessmentController ctrl) {
    final wasExpanded = _expandedIndex == i;
    setState(() => _expandedIndex = wasExpanded ? null : i);
    // Restore persisted data when expanding a session card
    if (!wasExpanded) {
      ctrl.restoreSessionData(i + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return Obx(() {
      final sessions = ctrl.sessions;

      if (sessions.isEmpty) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    size: 36,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 16),
                Text('No sessions yet', style: AppTextStyles.sectionHeading),
                const SizedBox(height: 6),
                Text(
                  'Select a Basti type in Step 1 to generate session log.',
                  style: AssessmentTextStyles.noteText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const PhysicianYuktiBanner(),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          // ── Progress header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Obx(() {
                        ctrl.observationTick.value;
                        final logged = ctrl.loggedSessionCount;
                        final total = sessions.length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$logged of $total sessions logged',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textDarkGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total == 0 ? 0 : logged / total,
                                minHeight: 5,
                                backgroundColor: AppColors.inputBackground,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      flex: 2,
                      child: Obx(() {
                        final bastiName =
                            ctrl.selectedBastiOption.value?.name ??
                            ctrl.initialPlan?.bastiName ??
                            ctrl.selectedBastiType.value ??
                            '';
                        if (bastiName.trim().isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            bastiName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Session list ───────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              itemCount: sessions.length + 1,
              itemBuilder: (_, i) {
                if (i == sessions.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: PhysicianYuktiBanner(),
                  );
                }
                return _SessionCard(
                  session: sessions[i],
                  ctrl: ctrl,
                  isExpanded: _expandedIndex == i,
                  onToggle: () => _handleToggle(i, ctrl),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session accordion card
// ─────────────────────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final BastiSessionData session;
  final AssessmentController ctrl;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SessionCard({
    required this.session,
    required this.ctrl,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Obx(() {
                    ctrl.observationTick.value;
                    final tpcRegistered =
                        Get.isRegistered<TreatmentPlanController>();
                    final isPersistedComplete =
                        tpcRegistered &&
                        Get.find<TreatmentPlanController>().persistedSessions
                            .any(
                              (ps) =>
                                  ps.dayNumber == session.sessionNumber &&
                                  ps.isCompleted,
                            );

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? AppColors.primaryGreen
                            : (isPersistedComplete
                                  ? AppColors.successGreen.withValues(
                                      alpha: 0.12,
                                    )
                                  : AppColors.inputBackground),
                        borderRadius: BorderRadius.circular(10),
                        border: isPersistedComplete && !isExpanded
                            ? Border.all(
                                color: AppColors.successGreen.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Center(
                        child: isPersistedComplete && !isExpanded
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: AppColors.successGreen,
                              )
                            : Text(
                                '${session.sessionNumber}',
                                style: TextStyle(
                                  color: isExpanded
                                      ? Colors.white
                                      : AppColors.textDarkGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() {
                          final schedule = ctrl.generatedSchedule;
                          final dayIndex = session.sessionNumber - 1;
                          final hasSchedule = schedule.length > dayIndex;
                          final dayModel = hasSchedule
                              ? schedule[dayIndex]
                              : null;

                          final titleText = dayModel != null
                              ? '${session.sessionNumber} — ${dayModel.scheduledBastiType} (${dayModel.scheduledDose.toInt()} ${dayModel.doseUnit})'
                              : '${session.sessionNumber}';

                          return Text(
                            titleText,
                            style: AssessmentTextStyles.sectionTitle,
                          );
                        }),
                        const SizedBox(height: 2),
                        Obx(() {
                          ctrl.observationTick.value;
                          final s = ctrl.sessions.isNotEmpty ? session : null;
                          if (s == null) return const SizedBox.shrink();

                          // Check persisted status
                          final tpcRegistered =
                              Get.isRegistered<TreatmentPlanController>();
                          final isPersistedComplete =
                              tpcRegistered &&
                              Get.find<TreatmentPlanController>()
                                  .persistedSessions
                                  .any(
                                    (ps) =>
                                        ps.dayNumber == session.sessionNumber &&
                                        ps.isCompleted,
                                  );

                          final isSaving =
                              ctrl.savingSessionDay.value ==
                              session.sessionNumber;
                          final isDeleting =
                              ctrl.deletingSessionDay.value ==
                              session.sessionNumber;

                          if (isSaving) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isPersistedComplete
                                      ? 'Updating...'
                                      : 'Saving...',
                                  style: AssessmentTextStyles.noteText.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          }

                          if (isDeleting) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.errorRed,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Deleting...',
                                  style: AssessmentTextStyles.noteText.copyWith(
                                    color: AppColors.errorRed,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          }

                          if (isPersistedComplete) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: AppColors.successGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Logged',
                                  style: AssessmentTextStyles.noteText.copyWith(
                                    color: AppColors.successGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.radio_button_unchecked_rounded,
                                size: 13,
                                color: AppColors.darkGrey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Not Logged',
                                style: AssessmentTextStyles.noteText.copyWith(
                                  color: AppColors.darkGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.darkGrey,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Expandable body ──────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: isExpanded
                ? _SessionBody(
                    session: session,
                    ctrl: ctrl,
                    onCollapseRequested: onToggle,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session body — time fields + three symptom groups
// ─────────────────────────────────────────────────────────────────────────────

class _SessionBody extends StatelessWidget {
  final BastiSessionData session;
  final AssessmentController ctrl;
  final VoidCallback onCollapseRequested;

  const _SessionBody({
    required this.session,
    required this.ctrl,
    required this.onCollapseRequested,
  });

  @override
  Widget build(BuildContext context) {
    final dayIndex = session.sessionNumber - 1;
    final isKwatha = (dayIndex >= 0 && dayIndex < ctrl.generatedSchedule.length)
        ? ctrl.generatedSchedule[dayIndex].isKwathaBased
        : (ctrl.selectedBastiOption.value?.bastiTypeDisplay.toLowerCase().contains('yapana') == true ||
           ctrl.selectedBastiType.value != 'Anuvasan Basti');

    final samyakaList = isKwatha
        ? AssessmentController.niruhasamyakaSymptoms
        : AssessmentController.anuvasanSamyakaSymptoms;
    final ayogaList = isKwatha
        ? AssessmentController.niruhaAyogaSymptoms
        : AssessmentController.anuvasanAyogaSymptoms;
    final atiyogaList = isKwatha
        ? AssessmentController.niruhaAtiyogaSymptoms
        : AssessmentController.anuvasanAtiyogaSymptoms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: Color(0xFFF0EDE8), thickness: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time fields row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Adana Kala',
                      controller: session.adanaKala,
                      hint: '08:30 AM',
                      isTimePicker: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeField(
                      label: 'Pratyagamana',
                      controller: session.pratyagamana,
                      hint: '09:15 AM',
                      isTimePicker: true,
                      referenceTimeController: session.adanaKala,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeField(
                      label: 'Vega',
                      controller: session.vega,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      suffixIcon: Icons.format_list_numbered_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Samyaka — green
              _SymptomGroup(
                title: 'Samyaka Basti Lakshana',
                subtitle: 'Signs of proper action',
                color: AppColors.successGreen,
                symptoms: samyakaList,
                selected: session.samyaka,
                onToggle: (i) =>
                    ctrl.toggleSessionSymptom(session, 'samyaka', i),
              ),
              // Ayoga — amber
              _SymptomGroup(
                title: 'Ayoga Basti Lakshana',
                subtitle: 'Signs of under-action',
                color: const Color(0xFFE6A817),
                symptoms: ayogaList,
                selected: session.ayoga,
                onToggle: (i) => ctrl.toggleSessionSymptom(session, 'ayoga', i),
              ),
              // Atiyoga — red
              _SymptomGroup(
                title: 'Atiyoga Basti Lakshana',
                subtitle: 'Signs of over-action',
                color: AppColors.errorRed,
                symptoms: atiyogaList,
                selected: session.atiyoga,
                onToggle: (i) =>
                    ctrl.toggleSessionSymptom(session, 'atiyoga', i),
              ),
              const SizedBox(height: 16),
              // Paschata Karma (Vyapada)
              Text(
                'Paschata Karma (Vyapada)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDarkGreen,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() {
                if (isKwatha) {
                  return AppBottomSheet<String>(
                    label: 'Niruha Vyapada',
                    hint: 'Select Vyapada',
                    value: session.niruhaVyapada.value.isEmpty ? 'none' : session.niruhaVyapada.value,
                    options: const [
                      BottomSheetOption(value: 'none', label: 'None'),
                      BottomSheetOption(value: 'ayoga', label: 'Ayoga'),
                      BottomSheetOption(value: 'atiyoga', label: 'Atiyoga'),
                      BottomSheetOption(value: 'klama', label: 'Klama'),
                      BottomSheetOption(value: 'adhmana', label: 'Adhmana'),
                      BottomSheetOption(value: 'hikka', label: 'Hikka'),
                      BottomSheetOption(value: 'hadprapti', label: 'Hadprapti'),
                      BottomSheetOption(value: 'udavarta', label: 'Udavarta'),
                      BottomSheetOption(value: 'pravahika', label: 'Pravahika'),
                      BottomSheetOption(value: 'shiroArti', label: 'Shiro Arti'),
                      BottomSheetOption(value: 'angaArti', label: 'Anga Arti'),
                      BottomSheetOption(value: 'parikartika', label: 'Parikartika'),
                      BottomSheetOption(value: 'parisrava', label: 'Parisrava'),
                    ],
                    onChanged: (val) => session.niruhaVyapada.value = val ?? '',
                  );
                } else {
                  return AppBottomSheet<String>(
                    label: 'Anuvasana Vyapada',
                    hint: 'Select Vyapada',
                    value: session.anuvasanaVyapada.value.isEmpty ? 'none' : session.anuvasanaVyapada.value,
                    options: const [
                      BottomSheetOption(value: 'none', label: 'None'),
                      BottomSheetOption(value: 'vatavrutaSneha', label: 'Vatavruta Sneha'),
                      BottomSheetOption(value: 'pittavrutaSneha', label: 'Pittavruta Sneha'),
                      BottomSheetOption(value: 'kaphavrutaSneha', label: 'Kaphavruta Sneha'),
                      BottomSheetOption(value: 'annaVrutaSneha', label: 'Anna Vruta Sneha'),
                      BottomSheetOption(value: 'purishaVrutaSneha', label: 'Purisha Vruta Sneha'),
                      BottomSheetOption(value: 'abhuktaPranita', label: 'Abhukta Pranita'),
                    ],
                    onChanged: (val) => session.anuvasanaVyapada.value = val ?? '',
                  );
                }
              }),
              const SizedBox(height: 16),
              // ── Save & Complete Day button ──────────────────────────────
              Obx(() {
                ctrl.observationTick.value;
                final tpcRegistered =
                    Get.isRegistered<TreatmentPlanController>();
                final isPersistedComplete =
                    tpcRegistered &&
                    Get.find<TreatmentPlanController>().persistedSessions.any(
                      (ps) =>
                          ps.dayNumber == session.sessionNumber &&
                          ps.isCompleted,
                    );
                final isSaving =
                    ctrl.savingSessionDay.value == session.sessionNumber;
                final isDeleting =
                    ctrl.deletingSessionDay.value == session.sessionNumber;
                final isBusy = isSaving || isDeleting;

                return Column(
                  children: [
                    if (isSaving) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.25,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isPersistedComplete
                                    ? 'Updating session log and syncing with backend...'
                                    : 'Saving observation for session ${session.sessionNumber}...',
                                style: const TextStyle(
                                  color: AppColors.textDarkGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSaving
                              ? AppColors.primaryGreen.withValues(alpha: 0.75)
                              : AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: isSaving ? 0 : 2,
                          shadowColor: AppColors.primaryGreen.withValues(
                            alpha: 0.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: isBusy
                            ? null
                            : () async {
                                FocusScope.of(context).unfocus();
                                try {
                                  await ctrl.saveCurrentSession(
                                    session.sessionNumber,
                                  );
                                  onCollapseRequested();
                                  Get.snackbar(
                                    'Session ${session.sessionNumber} Saved',
                                    isPersistedComplete
                                        ? 'Session log updated successfully.'
                                        : 'Session recorded successfully.',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColors.successGreen,
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 2),
                                    margin: const EdgeInsets.all(16),
                                    borderRadius: 14,
                                    icon: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                    ),
                                  );
                                } catch (e) {
                                  Get.snackbar(
                                    'Error Saving Session ${session.sessionNumber}',
                                    e.toString().replaceAll('Exception: ', ''),
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColors.errorRed,
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 4),
                                    margin: const EdgeInsets.all(16),
                                    borderRadius: 14,
                                    icon: const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isPersistedComplete
                                        ? 'Updating Session Log'
                                        : 'Saving Session...',
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isPersistedComplete
                                        ? Icons.check_circle_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isPersistedComplete
                                        ? 'Update Session Log'
                                        : 'Save & Complete',
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (isPersistedComplete) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.errorRed.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isBusy
                              ? null
                              : () async {
                                  final confirmed = await AppDialog.showConfirmation(
                                    icon: Icons.delete_outline_rounded,
                                    iconColor: AppColors.errorRed,
                                    title:
                                        'Delete Session ${session.sessionNumber} Log?',
                                    content:
                                        'Are you sure you want to delete this session log? This will reset the observation for this session.',
                                    cancelText: 'Cancel',
                                    confirmText: 'Delete',
                                    confirmColor: AppColors.errorRed,
                                  );
                                  if (confirmed == true) {
                                    try {
                                      await ctrl.deleteSession(
                                        session.sessionNumber,
                                      );
                                      onCollapseRequested();
                                      Get.snackbar(
                                        'Session Log Deleted',
                                        'Session ${session.sessionNumber} log has been removed.',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: const Color(
                                          0xFF616161,
                                        ),
                                        colorText: Colors.white,
                                        duration: const Duration(seconds: 2),
                                        margin: const EdgeInsets.all(16),
                                        borderRadius: 14,
                                        icon: const Icon(
                                          Icons.delete_sweep_rounded,
                                          color: Colors.white,
                                        ),
                                      );
                                    } catch (e) {
                                      Get.snackbar(
                                        'Error Deleting Session',
                                        e.toString().replaceAll(
                                          'Exception: ',
                                          '',
                                        ),
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.errorRed,
                                        colorText: Colors.white,
                                        duration: const Duration(seconds: 4),
                                        margin: const EdgeInsets.all(16),
                                        borderRadius: 14,
                                        icon: const Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.white,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isDeleting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.errorRed,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Deleting Session Log...',
                                      style: TextStyle(
                                        color: AppColors.errorRed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: AppColors.errorRed,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete Session Log',
                                      style: TextStyle(
                                        color: AppColors.errorRed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Symptom group with coloured header
// ─────────────────────────────────────────────────────────────────────────────

class _SymptomGroup extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final List<String> symptoms;
  final RxList<bool> selected;
  final ValueChanged<int> onToggle;

  const _SymptomGroup({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.symptoms,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AssessmentTextStyles.noteText.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  final count = selected.where((v) => v).length;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Symptom tiles
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              children: List.generate(
                symptoms.length,
                (i) => Obx(
                  () => _SymptomTile(
                    label: symptoms[i],
                    isChecked: selected[i],
                    color: color,
                    onTap: () => onToggle(i),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single symptom checkbox tile
// ─────────────────────────────────────────────────────────────────────────────

class _SymptomTile extends StatelessWidget {
  final String label;
  final bool isChecked;
  final Color color;
  final VoidCallback onTap;

  const _SymptomTile({
    required this.label,
    required this.isChecked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: isChecked ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isChecked ? color : const Color(0xFFCCCCCC),
                  width: 1.5,
                ),
              ),
              child: isChecked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AssessmentTextStyles.optionText.copyWith(
                  color: isChecked
                      ? AppColors.textDarkGreen
                      : AppColors.darkGrey,
                  fontWeight: isChecked ? FontWeight.w500 : FontWeight.w400,
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
// Compact time/vega input field
// ─────────────────────────────────────────────────────────────────────────────

class _TimeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool isTimePicker;
  final TextEditingController? referenceTimeController;
  final IconData? suffixIcon;

  const _TimeField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.isTimePicker = false,
    this.referenceTimeController,
    this.suffixIcon,
  });

  DateTime _parseTimeString(String text) {
    final now = DateTime.now();
    if (text.trim().isEmpty) return now;
    try {
      final clean = text.trim();
      final parts = clean.split(RegExp(r'[:\s]+'));
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (parts.length >= 3) {
          final period = parts[2].toUpperCase();
          if (period == 'PM' && hour < 12) hour += 12;
          if (period == 'AM' && hour == 12) hour = 0;
        }
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (_) {}
    return now;
  }

  void _openTimePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetCtx) => _TimePickerBottomSheet(
        title: label,
        initialTime: _parseTimeString(controller.text),
        referenceTime:
            referenceTimeController != null &&
                referenceTimeController!.text.isNotEmpty
            ? _parseTimeString(referenceTimeController!.text)
            : null,
        onTimeSelected: (formatted) {
          controller.text = formatted;
        },
        onCleared: () {
          controller.clear();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIcon =
        suffixIcon ?? (isTimePicker ? Icons.access_time_rounded : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDarkGreen,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 42,
          child: GestureDetector(
            onTap: isTimePicker ? () => _openTimePicker(context) : null,
            child: AbsorbPointer(
              absorbing: isTimePicker,
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                readOnly: isTimePicker,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  color: AppColors.textDarkGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AssessmentTextStyles.hintText.copyWith(fontSize: 12),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  isDense: true,
                  suffixIcon: effectiveIcon != null
                      ? Icon(
                          effectiveIcon,
                          color: AppColors.primaryGreen,
                          size: 16,
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.primaryGreen.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom-sheet time picker with wheel and quick Ayurvedic retention presets
// ─────────────────────────────────────────────────────────────────────────────

class _TimePickerBottomSheet extends StatefulWidget {
  final String title;
  final DateTime initialTime;
  final DateTime? referenceTime;
  final ValueChanged<String> onTimeSelected;
  final VoidCallback onCleared;

  const _TimePickerBottomSheet({
    required this.title,
    required this.initialTime,
    required this.onTimeSelected,
    required this.onCleared,
    this.referenceTime,
  });

  @override
  State<_TimePickerBottomSheet> createState() => _TimePickerBottomSheetState();
}

class _TimePickerBottomSheetState extends State<_TimePickerBottomSheet> {
  late DateTime _selected;
  late final ValueNotifier<DateTime> _selectedNotifier;
  int _pickerResetKey = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialTime;
    _selectedNotifier = ValueNotifier<DateTime>(_selected);
  }

  @override
  void dispose() {
    _selectedNotifier.dispose();
    super.dispose();
  }

  void _applyPresetTime(DateTime newTime) {
    setState(() {
      _selected = newTime;
      _selectedNotifier.value = newTime;
      _pickerResetKey++;
    });
  }

  String _formatTime(DateTime dt) {
    final int h = dt.hour;
    final int m = dt.minute;
    final String period = h >= 12 ? 'PM' : 'AM';
    final int hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final String hourStr = hour12.toString().padLeft(2, '0');
    final String minStr = m.toString().padLeft(2, '0');
    return '$hourStr:$minStr $period';
  }

  @override
  Widget build(BuildContext context) {
    final isPratyagamana = widget.title.toLowerCase().contains('pratyagamana');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time_filled_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.textDarkGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Time badge with ValueListenableBuilder for zero-cost updates on scroll
                ValueListenableBuilder<DateTime>(
                  valueListenable: _selectedNotifier,
                  builder: (context, current, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatTime(current),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Quick preset chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // "Now" chip
                  ActionChip(
                    avatar: const Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                    label: const Text('Now'),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                    backgroundColor: AppColors.primaryGreen.withValues(
                      alpha: 0.1,
                    ),
                    side: BorderSide(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                    onPressed: () {
                      _applyPresetTime(DateTime.now());
                    },
                  ),
                  const SizedBox(width: 8),

                  // If Pratyagamana and referenceTime is available: retention chips
                  if (isPratyagamana && widget.referenceTime != null) ...[
                    for (final mins in [15, 30, 45, 60, 90, 120, 180]) ...[
                      ActionChip(
                        label: Text(
                          mins < 60
                              ? '+$mins m'
                              : '+${mins ~/ 60} h${mins % 60 > 0 ? ' ${mins % 60}m' : ''}',
                        ),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDarkGreen,
                        ),
                        backgroundColor: AppColors.inputBackground,
                        side: BorderSide(color: Colors.grey.shade300),
                        onPressed: () {
                          _applyPresetTime(
                            widget.referenceTime!.add(Duration(minutes: mins)),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ] else ...[
                    // Common Ayurvedic Basti administration times
                    for (final preset in [
                      const TimeOfDay(hour: 7, minute: 30),
                      const TimeOfDay(hour: 8, minute: 0),
                      const TimeOfDay(hour: 8, minute: 30),
                      const TimeOfDay(hour: 9, minute: 0),
                      const TimeOfDay(hour: 9, minute: 30),
                      const TimeOfDay(hour: 10, minute: 0),
                    ]) ...[
                      ActionChip(
                        label: Text(
                          '${preset.hourOfPeriod.toString().padLeft(2, '0')}:${preset.minute.toString().padLeft(2, '0')} ${preset.period == DayPeriod.am ? 'AM' : 'PM'}',
                        ),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDarkGreen,
                        ),
                        backgroundColor: AppColors.inputBackground,
                        side: BorderSide(color: Colors.grey.shade300),
                        onPressed: () {
                          final now = DateTime.now();
                          _applyPresetTime(
                            DateTime(
                              now.year,
                              now.month,
                              now.day,
                              preset.hour,
                              preset.minute,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Cupertino time picker wheel — uses stable key so gesture inertia and scrolling are completely smooth
          SizedBox(
            height: 190,
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                brightness: Brightness.light,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    color: AppColors.textDarkGreen,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                key: ValueKey('picker_$_pickerResetKey'),
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _selected,
                use24hFormat: false,
                onDateTimeChanged: (DateTime newDateTime) {
                  _selected = newDateTime;
                  _selectedNotifier.value = newDateTime;
                },
              ),
            ),
          ),

          // Bottom actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    widget.onCleared();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: AppColors.darkGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onTimeSelected(_formatTime(_selected));
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Set Time'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared text field for assessment forms
// ─────────────────────────────────────────────────────────────────────────────

class _AssessTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool required;
  final int maxLines;

  const _AssessTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.required = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDarkGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(color: AppColors.errorRed, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: maxLines > 1
                ? TextInputType.multiline
                : TextInputType.text,
            maxLines: maxLines,
            style: const TextStyle(
              color: AppColors.textDarkGreen,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AssessmentTextStyles.hintText,
              filled: true,
              fillColor: AppColors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primaryGreen,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
