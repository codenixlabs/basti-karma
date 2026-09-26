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
  bool _isLoadingSaved = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAssessment();
  }

  Future<void> _loadSavedAssessment() async {
    final ctrl = Get.find<AssessmentController>();
    if (ctrl.patientId == null || ctrl.patientId!.isEmpty) return;
    setState(() => _isLoadingSaved = true);
    final resumeStep = await ctrl.loadPoorvaKarma();
    if (mounted) {
      setState(() {
        _step = resumeStep;
        _isLoadingSaved = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageCtrl.hasClients && resumeStep > 0) {
          _pageCtrl.jumpToPage(resumeStep);
        }
      });
    }
  }

  static const int _totalSteps = 6;
  static const List<String> _stepTitles = [
    'Niruha Basti — Eligibility',
    'Anuvasana Basti — Eligibility',
    'Pariksha',
    'Agni Assessment',
    'Koshtha Assessment',
    'Saama, Nirama & Bala',
  ];

  bool _isStepReady(AssessmentController ctrl, int step) {
    switch (step) {
      case 0:
        return ctrl.niruhaAllAnswered;
      case 1:
        return ctrl.anuvasanAllAnswered;
      case 2:
        return ctrl.parikshAllFilled;
      case 3:
        return ctrl.agniAllAnswered;
      case 4:
        return ctrl.koshthaAllAnswered;
      case 5:
        return ctrl.canCompletePurvakarma;
      default:
        return true;
    }
  }

  Future<void> _next() async {
    final ctrl = Get.find<AssessmentController>();
    if (ctrl.isSavingStep.value) return;
    if (_step >= _totalSteps - 1) return;

    if (!_isStepReady(ctrl, _step)) {
      Get.snackbar(
        'Incomplete Assessment',
        'Please answer all questions before proceeding.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE65100),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      return;
    }

    final saved = await ctrl.saveCurrentPoorvaStep(_step);
    if (!saved) {
      final errorMsg = ctrl.poorvaKarmaError.value;
      final msg = (errorMsg != null && errorMsg.isNotEmpty)
          ? errorMsg
          : 'Could not save ${_stepTitles[_step]}. Please try again.';
      await _showSaveErrorSheet(onRetry: _next, message: msg);
      return;
    }

    void advanceStep() {
      setState(() => _step++);
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }

    switch (_step) {
      case 0: // Niruha
        final niruhaRes = ctrl.niruhaBackendResult.value;
        final isEligible = niruhaRes?.isEligible ?? false;
        final msg =
            niruhaRes?.message ??
            (isEligible
                ? 'Patient has no contraindications for Niruha Basti.'
                : 'One or more contraindications present for Niruha Basti.');
        await _showEligibilitySheet(
          title: 'Niruha Basti Eligibility',
          isEligible: isEligible,
          message: msg,
          proceedButtonText: 'Continue',
          onProceed: advanceStep,
        );
        break;

      case 1: // Anuvasana
        final anuvasanaRes = ctrl.anuvasanaBackendResult.value;
        final isEligible = anuvasanaRes?.isEligible ?? false;
        final msg =
            anuvasanaRes?.message ??
            (isEligible
                ? 'Patient has no contraindications for Anuvasana Basti.'
                : 'One or more contraindications present for Anuvasana Basti.');
        await _showEligibilitySheet(
          title: 'Anuvasana Basti Eligibility',
          isEligible: isEligible,
          message: msg,
          proceedButtonText: 'Continue',
          onProceed: advanceStep,
        );
        break;

      case 2: // Pariksha
        advanceStep();
        break;

      case 3: // Agni
        final agniRes = ctrl.agniBackendResult.value;
        final agniType = agniRes?.agniType ?? 'Agni Evaluated';
        final score = agniRes?.totalScore ?? 0;
        final isAvarAgni =
            agniType.toLowerCase().contains('avar') ||
            agniType.toLowerCase().contains('manda');
        final recommendedDrugs =
            (agniRes?.recommendedDrugs != null &&
                agniRes!.recommendedDrugs!.trim().isNotEmpty)
            ? agniRes.recommendedDrugs!
            : ctrl.agniDeepanPachana;
        await _showClinicalResultSheet(
          title: 'Agni Assessment',
          subtitle: 'Score: $score / 15',
          resultValue: agniType,
          recommendationTitle: isAvarAgni ? 'Recommended Deepan Pachana' : null,
          recommendationContent: isAvarAgni ? recommendedDrugs : null,
          icon: Icons.local_fire_department_rounded,
          iconColor: const Color(0xFFE65100),
          buttonText: 'Continue',
          onProceed: advanceStep,
        );
        break;

      case 4: // Koshtha
        final kosthaRes = ctrl.kosthaBackendResult.value;
        final kosthaType = kosthaRes?.kosthaType ?? 'Kostha Evaluated';
        final score = kosthaRes?.totalScore ?? 0;
        await _showClinicalResultSheet(
          title: 'Kostha Assessment',
          subtitle: 'Score: $score / 15',
          resultValue: kosthaType,
          icon: Icons.straighten_rounded,
          iconColor: AppColors.primaryGreen,
          buttonText: 'Continue',
          onProceed: advanceStep,
        );
        break;

      default:
        advanceStep();
        break;
    }
  }

  Future<T?> _showResultBottomSheet<T>({required Widget child}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => PoorvaBottomSheetContainer(child: child),
    );
  }

  Future<void> _showEligibilitySheet({
    required String title,
    required bool isEligible,
    required String message,
    String proceedButtonText = 'Continue',
    required VoidCallback onProceed,
  }) async {
    await _showResultBottomSheet<void>(
      child: Builder(
        builder: (ctx) => PoorvaEligibilitySheet(
          title: title,
          isEligible: isEligible,
          message: message,
          proceedButtonText: proceedButtonText,
          onProceed: () {
            Navigator.of(ctx).pop();
            onProceed();
          },
          onReviewAnswers: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  Future<void> _showClinicalResultSheet({
    required String title,
    required String resultValue,
    String? subtitle,
    String? recommendationTitle,
    String? recommendationContent,
    required IconData icon,
    required Color iconColor,
    String buttonText = 'Continue',
    required VoidCallback onProceed,
  }) async {
    await _showResultBottomSheet<void>(
      child: Builder(
        builder: (ctx) => PoorvaClinicalResultSheet(
          title: title,
          resultValue: resultValue,
          subtitle: subtitle,
          recommendationTitle: recommendationTitle,
          recommendationContent: recommendationContent,
          icon: icon,
          iconColor: iconColor,
          buttonText: buttonText,
          onProceed: () {
            Navigator.of(ctx).pop();
            onProceed();
          },
        ),
      ),
    );
  }

  Future<void> _handleComplete(AssessmentController ctrl) async {
    if (ctrl.isSavingStep.value) return;
    final ok = await ctrl.completePurvakarma();
    if (!ok) {
      final errorMsg = ctrl.poorvaKarmaError.value;
      final msg = (errorMsg != null && errorMsg.isNotEmpty)
          ? errorMsg
          : 'Could not mark Poorva Karma complete. Please try again.';
      await _showSaveErrorSheet(
        onRetry: () => _handleComplete(ctrl),
        message: msg,
      );
      return;
    }

    final saamaRes = ctrl.saamaBackendResult.value;
    final deepanRequired = saamaRes?.deepanPachanaRequired ?? false;

    if (!mounted) return;

    await _showCompleteSheet(ctrl: ctrl, deepanRequired: deepanRequired);
  }

  Future<void> _showCompleteSheet({
    required AssessmentController ctrl,
    required bool deepanRequired,
  }) async {
    await _showResultBottomSheet<void>(
      child: Builder(
        builder: (ctx) => PoorvaCompleteSheet(
          deepanRequired: deepanRequired,
          deepanRecommendation:
              (ctrl.agniBackendResult.value?.recommendedDrugs != null &&
                  ctrl.agniBackendResult.value!.recommendedDrugs!
                      .trim()
                      .isNotEmpty)
              ? ctrl.agniBackendResult.value!.recommendedDrugs!
              : ctrl.agniDeepanPachana,
          onContinue: () {
            Navigator.of(ctx).pop();
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
          },
        ),
      ),
    );
  }

  Future<void> _showSaveErrorSheet({
    required VoidCallback onRetry,
    required String message,
  }) async {
    await _showResultBottomSheet<void>(
      child: Builder(
        builder: (ctx) => PoorvaSaveErrorSheet(
          message: message,
          onStay: () => Navigator.of(ctx).pop(),
          onRetry: () {
            Navigator.of(ctx).pop();
            onRetry();
          },
        ),
      ),
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
            Obx(() {
              if (!ctrl.purvakarmaComplete.value) {
                return const SizedBox.shrink();
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: const Color(0xFFE8F5E9),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Poorva Karma completed for this patient (Review Mode).',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (_isLoadingSaved)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryGreen),
                      SizedBox(height: 16),
                      Text(
                        'Restoring saved assessment...',
                        style: TextStyle(
                          color: AppColors.textDarkGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
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
                    final isReady = _isStepReady(ctrl, _step);
                    final isSaving = ctrl.isSavingStep.value;
                    return ElevatedButton(
                      onPressed: (isReady && !isSaving)
                          ? () => _handleComplete(ctrl)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isReady && !isSaving)
                            ? AppColors.primaryGreen
                            : AppColors.darkGrey.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: (isReady && !isSaving) ? 3 : 0,
                        shadowColor: AppColors.primaryGreen.withValues(
                          alpha: 0.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Complete Purvakarma',
                              style: AppTextStyles.button,
                            ),
                    );
                  })
                : Obx(() {
                    final isReady = _isStepReady(ctrl, _step);
                    final isSaving = ctrl.isSavingStep.value;
                    return ElevatedButton(
                      onPressed: (isReady && !isSaving) ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isReady && !isSaving)
                            ? AppColors.primaryGreen
                            : AppColors.darkGrey.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: (isReady && !isSaving) ? 3 : 0,
                        shadowColor: AppColors.primaryGreen.withValues(
                          alpha: 0.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Checking...',
                                  style: AppTextStyles.button,
                                ),
                              ],
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
// Poorva Karma Result & Status Bottom Sheet Widgets
// ─────────────────────────────────────────────────────────────────────────────

class PoorvaBottomSheetContainer extends StatelessWidget {
  final Widget child;

  const PoorvaBottomSheetContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class PoorvaEligibilitySheet extends StatelessWidget {
  final String title;
  final bool isEligible;
  final String message;
  final String proceedButtonText;
  final VoidCallback onProceed;
  final VoidCallback onReviewAnswers;

  const PoorvaEligibilitySheet({
    super.key,
    required this.title,
    required this.isEligible,
    required this.message,
    this.proceedButtonText = 'Continue',
    required this.onProceed,
    required this.onReviewAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isEligible
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEligible ? Icons.check_rounded : Icons.priority_high_rounded,
                color: isEligible
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEligible ? '✓ Eligible' : '! Not Eligible',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isEligible
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFFB71C1C),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: TextStyle(
            fontSize: 13.5,
            color: Colors.grey.shade800,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        if (isEligible)
          ElevatedButton(
            onPressed: onProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              proceedButtonText,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          )
        else
          OutlinedButton(
            onPressed: onReviewAnswers,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC62828), width: 1.5),
              foregroundColor: const Color(0xFFC62828),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Review Answers',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class PoorvaClinicalResultSheet extends StatelessWidget {
  final String title;
  final String resultValue;
  final String? subtitle;
  final String? recommendationTitle;
  final String? recommendationContent;
  final IconData icon;
  final Color iconColor;
  final String buttonText;
  final VoidCallback onProceed;

  const PoorvaClinicalResultSheet({
    super.key,
    required this.title,
    required this.resultValue,
    this.subtitle,
    this.recommendationTitle,
    this.recommendationContent,
    required this.icon,
    required this.iconColor,
    this.buttonText = 'Continue',
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            resultValue,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDarkGreen,
            ),
          ),
        ),
        if (recommendationContent != null &&
            recommendationContent!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendationTitle ?? 'Recommendation',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB78103),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recommendationContent!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF5D4037),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onProceed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            buttonText,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class PoorvaCompleteSheet extends StatelessWidget {
  final bool deepanRequired;
  final String deepanRecommendation;
  final VoidCallback onContinue;

  const PoorvaCompleteSheet({
    super.key,
    required this.deepanRequired,
    required this.deepanRecommendation,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: deepanRequired
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                deepanRequired
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: deepanRequired
                    ? const Color(0xFFE65100)
                    : const Color(0xFF2E7D32),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deepanRequired ? 'Saama Avastha' : 'Nirama Avastha',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: deepanRequired
                          ? const Color(0xFFBF360C)
                          : const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    deepanRequired
                        ? 'Deepan Pachana protocol required'
                        : 'Poorva Karma Completed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (deepanRequired && deepanRecommendation.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended Deepan Pachana Protocol',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB78103),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deepanRecommendation,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF5D4037),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ] else if (!deepanRequired) ...[
          const SizedBox(height: 8),
          Text(
            'Nirama Avastha confirmed. Ready to proceed to Pradhana Karma.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class PoorvaSaveErrorSheet extends StatelessWidget {
  final String message;
  final VoidCallback onStay;
  final VoidCallback onRetry;

  const PoorvaSaveErrorSheet({
    super.key,
    required this.message,
    required this.onStay,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('connection') ||
        message.toLowerCase().contains('network');
    final isAuth =
        message.toLowerCase().contains('credential') ||
        message.toLowerCase().contains('session') ||
        message.toLowerCase().contains('unauthorized') ||
        message.toLowerCase().contains('token');
    final iconData = isNetwork
        ? Icons.wifi_off_rounded
        : (isAuth ? Icons.lock_clock_outlined : Icons.error_outline_rounded);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: const Color(0xFFC62828), size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Save Failed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF424242),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onStay,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Stay',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
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
        children: [
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
                    const Divider(
                      height: 1,
                      color: Color(0xFFF0EDE8),
                      thickness: 1,
                    ),
                ],
              ),
            ),
          ),
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
      child: AssessmentCard(
        title: 'Anuvasana Basti — Eligibility Check',
        icon: Icons.fact_check_outlined,
        children: [
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
                    const Divider(
                      height: 1,
                      color: Color(0xFFF0EDE8),
                      thickness: 1,
                    ),
                ],
              ),
            ),
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
  }) => AppBottomSheet<String>(
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
        children: [
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
            () => _drop(
              label: 'Vaya',
              rxn: ctrl.parikshVaya,
              options: vayaOptions,
            ),
          ),
          Obx(
            () => _drop(
              label: 'Jihwa',
              rxn: ctrl.parikshJihwa,
              options: jihwaOptions,
            ),
          ),
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
          Text(
            'Abhyavaharana Shakti',
            style: AssessmentTextStyles.sectionTitle,
          ),
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
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                child: Text(question, style: AssessmentTextStyles.questionText),
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
