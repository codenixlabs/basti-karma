import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/core/theme/app_text_styles.dart';
import '../../../app/shared/widgets/app_dropdown.dart';
import '../controller/assessment_controller.dart';
import '../widgets/assessment_widgets.dart';

class PradhanKarmaScreen extends StatefulWidget {
  const PradhanKarmaScreen({super.key});

  @override
  State<PradhanKarmaScreen> createState() => _PradhanKarmaScreenState();
}

class _PradhanKarmaScreenState extends State<PradhanKarmaScreen> {
  final _pageCtrl = PageController();
  int _step = 0;

  static const int _totalSteps = 4;
  static const List<String> _stepTitles = [
    'Basti Type Selection',
    'Dravya, Dose & Formulation',
    'Schedule of Basti',
    'Observation Log',
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
                    final canComplete = ctrl.pradhanAllFilled;
                    return ElevatedButton(
                      onPressed: canComplete
                          ? () {
                              ctrl.completePradhanKarma();
                              Get.back();
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
                        'Complete Pradhan Karma',
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
// Page 1 — Basti Type
// ─────────────────────────────────────────────────────────────────────────────

class _BastiTypePage extends StatelessWidget {
  const _BastiTypePage();

  static const List<String> _bastiTypes = [
    'Niruha Basti',
    'Anuvasan Basti',
    'Matra Basti',
    'Ksheera Basti',
    'Piccha Basti',
    'Tikshna Basti',
    'Madhura Basti',
    'Lekhana Basti',
    'Brumhana Basti',
    'Uttara Basti',
    'Yoga Basti',
    'Karma Basti',
    'Kala Basti',
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: AssessmentCard(
        title: 'Basti Type Selection',
        icon: Icons.category_outlined,
        children: [
          Text(
            'Select the indicated Basti type for this patient based on Purvakarma assessment.',
            style: AssessmentTextStyles.noteText,
          ),
          const SizedBox(height: 16),
          Obx(
            () => AppBottomSheet<String>(
              label: 'Basti Type',
              hint: 'Select Basti type',
              value: ctrl.selectedBastiType.value,
              required: true,
              onChanged: (v) => ctrl.selectedBastiType.value = v,
              options: _bastiTypes
                  .map((t) => BottomSheetOption(value: t, label: t))
                  .toList(),
            ),
          ),
          Obx(() {
            final selected = ctrl.selectedBastiType.value;
            if (selected == null) return const SizedBox.shrink();
            return ResultBanner(
              message: '$selected selected.',
              type: BannerType.info,
              icon: Icons.check_circle_outline_rounded,
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2 — Dravya, Dose & Formulation
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
        child: AssessmentCard(
          title: 'Dravya, Dose & Formulation',
          icon: Icons.science_outlined,
          children: [
            Text(
              'Specify the medicinal components, dosage, and preparation.',
              style: AssessmentTextStyles.noteText,
            ),
            const SizedBox(height: 12),
            _AssessTextField(
              controller: ctrl.dravyaDoseCtrl,
              label: 'Dravya Dose',
              hint: 'e.g. 480 ml, 960 ml',
              required: true,
            ),
            const SizedBox(height: 4),
            _AssessTextField(
              controller: ctrl.formulationCtrl,
              label: 'Formulation Details',
              hint: 'Enter ingredients and preparation details',
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 3 — Schedule of Basti
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
        child: AssessmentCard(
          title: 'Schedule of Basti',
          icon: Icons.calendar_month_outlined,
          children: [
            Text(
              'Define the administration schedule — type, frequency, and duration.',
              style: AssessmentTextStyles.noteText,
            ),
            const SizedBox(height: 12),
            _AssessTextField(
              controller: ctrl.scheduleCtrl,
              label: 'Schedule',
              hint:
                  'e.g. Yoga Basti (8 days), Karma Basti (30 days), Kala Basti (16 days)',
              required: true,
              maxLines: 4,
            ),
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

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return Obx(() {
      final sessions = ctrl.sessions;

      if (sessions.isEmpty) {
        return Center(
          child: Padding(
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
                Text(
                  'No sessions yet',
                  style: AppTextStyles.sectionHeading,
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a Basti type in Step 1 to generate session log.',
                  style: AssessmentTextStyles.noteText,
                  textAlign: TextAlign.center,
                ),
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
                      child: Obx(() {
                        ctrl.observationTick.value;
                        final logged = ctrl.loggedSessionCount;
                        final total = sessions.length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$logged of $total sessions logged',
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
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryGreen),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ctrl.selectedBastiType.value ?? '',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Doc note about sneha basti retention
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFF9A825).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: Color(0xFFF9A825)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'If Sneha Basti does not come out — give Tikshna Basti or Phala Varti.',
                          style: AssessmentTextStyles.noteText.copyWith(
                            fontSize: 11,
                            color: const Color(0xFF7B5E00),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Session list ───────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              itemCount: sessions.length,
              itemBuilder: (_, i) => _SessionCard(
                session: sessions[i],
                ctrl: ctrl,
                isExpanded: _expandedIndex == i,
                onToggle: () => setState(
                  () => _expandedIndex = _expandedIndex == i ? null : i,
                ),
              ),
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? AppColors.primaryGreen
                          : AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session ${session.sessionNumber}',
                          style: AssessmentTextStyles.sectionTitle,
                        ),
                        Obx(() {
                          ctrl.observationTick.value;
                          final s = ctrl.sessions.isNotEmpty ? session : null;
                          if (s == null) return const SizedBox.shrink();
                          final sc = s.samyaka.where((v) => v).length;
                          final ac = s.ayoga.where((v) => v).length;
                          final atc = s.atiyoga.where((v) => v).length;
                          final parts = [
                            if (sc > 0) '$sc Samyaka',
                            if (ac > 0) '$ac Ayoga',
                            if (atc > 0) '$atc Atiyoga',
                          ];
                          if (parts.isEmpty && session.adanaKala.text.isEmpty) {
                            return Text(
                              'Not yet logged',
                              style: AssessmentTextStyles.noteText,
                            );
                          }
                          return Text(
                            parts.isNotEmpty
                                ? parts.join(' · ')
                                : 'Time recorded',
                            style: AssessmentTextStyles.noteText.copyWith(
                              color: AppColors.primaryGreen,
                            ),
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
                ? _SessionBody(session: session, ctrl: ctrl)
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

  const _SessionBody({required this.session, required this.ctrl});

  @override
  Widget build(BuildContext context) {
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
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Adana Kala',
                      controller: session.adanaKala,
                      hint: '08:30 AM',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeField(
                      label: 'Pratyagamana',
                      controller: session.pratyagamana,
                      hint: '09:15 AM',
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 68,
                    child: _TimeField(
                      label: 'Vega',
                      controller: session.vega,
                      hint: '0',
                      keyboardType: TextInputType.number,
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
                symptoms: ctrl.activeSamyakaSymptoms,
                selected: session.samyaka,
                onToggle: (i) =>
                    ctrl.toggleSessionSymptom(session, 'samyaka', i),
              ),
              // Ayoga — amber
              _SymptomGroup(
                title: 'Ayoga Basti Lakshana',
                subtitle: 'Signs of under-action',
                color: const Color(0xFFE6A817),
                symptoms: ctrl.activeAyogaSymptoms,
                selected: session.ayoga,
                onToggle: (i) =>
                    ctrl.toggleSessionSymptom(session, 'ayoga', i),
              ),
              // Atiyoga — red
              _SymptomGroup(
                title: 'Atiyoga Basti Lakshana',
                subtitle: 'Signs of over-action',
                color: AppColors.errorRed,
                symptoms: ctrl.activeAtiyogaSymptoms,
                selected: session.atiyoga,
                onToggle: (i) =>
                    ctrl.toggleSessionSymptom(session, 'atiyoga', i),
              ),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
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
                        style: AssessmentTextStyles.noteText
                            .copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  final count = selected.where((v) => v).length;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
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
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
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
                  fontWeight:
                      isChecked ? FontWeight.w500 : FontWeight.w400,
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

  const _TimeField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: AppColors.textDarkGreen,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AssessmentTextStyles.hintText.copyWith(fontSize: 12),
            filled: true,
            fillColor: AppColors.inputBackground,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
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
      ],
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
  final TextInputType keyboardType;

  const _AssessTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
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
            keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
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
