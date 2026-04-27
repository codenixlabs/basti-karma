import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/widgets/app_dropdown.dart';
import '../controller/assessment_controller.dart';
import '../widgets/assessment_widgets.dart';

class PradhanKarmaScreen extends StatelessWidget {
  const PradhanKarmaScreen({super.key});

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
              subTitle: 'Main procedure planning — ${ctrl.patientName}',
              onBack: () => Get.back(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  children: [
                    _BastiTypeSection(),
                    _DravyaDoseSection(),
                    _ScheduleSection(),
                    _ObservationSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Obx(
              () => AssessmentBottomButton(
                label: 'Complete Pradhan Karma',
                onPressed: ctrl.pradhanAllFilled
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Basti Type
// ─────────────────────────────────────────────────────────────────────────────

class _BastiTypeSection extends StatelessWidget {
  static const List<String> bastiTypes = [
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

    return AssessmentCard(
      title: '1. Basti Type',
      icon: Icons.category_outlined,
      children: [
        Text(
          'Select the indicated Basti type for this patient.',
          style: AssessmentTextStyles.noteText,
        ),
        const SizedBox(height: 12),
        Obx(
          () => AppBottomSheet<String>(
            label: 'Basti Type',
            hint: 'Select Basti type',
            value: ctrl.selectedBastiType.value,
            required: true,
            onChanged: (v) => ctrl.selectedBastiType.value = v,
            options: bastiTypes
                .map((t) => BottomSheetOption(value: t, label: t))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Dravya, Dose & Formulation
// ─────────────────────────────────────────────────────────────────────────────

class _DravyaDoseSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return AssessmentCard(
      title: '2. Dravya, Dose & Formulation',
      icon: Icons.science_outlined,
      children: [
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
          maxLines: 4,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Schedule of Basti
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return AssessmentCard(
      title: '3. Schedule of Basti',
      icon: Icons.calendar_month_outlined,
      children: [
        _AssessTextField(
          controller: ctrl.scheduleCtrl,
          label: 'Schedule',
          hint:
              'e.g. Yoga Basti (8 days), Karma Basti (30 days), Kala Basti (16 days)',
          required: true,
          maxLines: 3,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Observation Log
// ─────────────────────────────────────────────────────────────────────────────

class _ObservationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AssessmentController>();

    return AssessmentCard(
      title: '4. Observation of Basti',
      icon: Icons.assignment_outlined,
      children: [
        Text(
          'Record observations after each Basti administration.',
          style: AssessmentTextStyles.noteText,
        ),
        const SizedBox(height: 12),
        _AssessTextField(
          controller: ctrl.adanaKalaCtrl,
          label: 'Adana Kala (time of administration)',
          hint: 'e.g. 08:30 AM',
        ),
        _AssessTextField(
          controller: ctrl.pratyagamanaCtrl,
          label: 'Pratyagamana Kala (time of return)',
          hint: 'e.g. 09:15 AM',
        ),
        _AssessTextField(
          controller: ctrl.vegaCtrl,
          label: 'Vega (number of urges)',
          hint: 'e.g. 3',
          keyboardType: TextInputType.number,
        ),
        _AssessTextField(
          controller: ctrl.samyakLakshanaCtrl,
          label: 'Samyaka Basti Lakshana',
          hint: 'Describe signs of proper action',
          maxLines: 3,
        ),
        _AssessTextField(
          controller: ctrl.atiyogaLakshanaCtrl,
          label: 'Atiyoga Basti Lakshana',
          hint: 'Describe signs of over-action (if any)',
          maxLines: 3,
        ),
        _AssessTextField(
          controller: ctrl.ayogaLakshanaCtrl,
          label: 'Ayoga Basti Lakshana',
          hint: 'Describe signs of under-action (if any)',
          maxLines: 3,
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
