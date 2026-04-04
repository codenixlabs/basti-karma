import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/widgets/app_dropdown.dart';
import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';

class Step4Lifestyle extends StatelessWidget {
  const Step4Lifestyle({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddPatientController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.registerValidation(3, () => true);
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
        child: FormSectionCard(
          title: 'Lifestyle (Ahara & Vihara)',
          icon: Icons.restaurant_outlined,
          children: [
            Obx(
              () => FormRadioGroup<String>(
                label: 'Ahara (Diet)',
                groupValue: ctrl.diet.value,
                options: const [
                  (value: 'Vegetarian', label: 'Veg'),
                  (value: 'Non-Vegetarian', label: 'Non-Veg'),
                  (value: 'Mixed', label: 'Mixed'),
                ],
                onChanged: (v) => ctrl.diet.value = v,
              ),
            ),

            _AddictionsField(ctrl: ctrl),

            Obx(
              () => AppBottomSheet<String>(
                label: 'Bowel Habits',
                hint: 'Select bowel habits',
                value: ctrl.bowelHabits.value,
                onChanged: (v) => ctrl.bowelHabits.value = v,
                options: [
                  BottomSheetOption(value: 'Regular', label: 'Regular'),
                  BottomSheetOption(value: 'Irregular', label: 'Irregular'),
                  BottomSheetOption(value: 'Constipated', label: 'Constipated'),
                  BottomSheetOption(value: 'Watery', label: 'Watery'),
                  BottomSheetOption(value: 'Others', label: 'Others'),
                ],
              ),
            ),

            Obx(
              () => AppBottomSheet<String>(
                label: 'Nidra (Sleep)',
                hint: 'Select sleep pattern',
                value: ctrl.nidra.value,
                onChanged: (v) => ctrl.nidra.value = v,
                options: [
                  BottomSheetOption(value: 'Sound', label: 'Sound'),
                  BottomSheetOption(value: 'Disturbed', label: 'Disturbed'),
                ],
              ),
            ),

            FormTextField(
              label: 'Urine Frequency',
              hint: 'e.g., 6-8 times/day',
              controller: ctrl.urineFreqCtrl,
              focusNode: ctrl.urineFreqFocus,
              textInputAction: TextInputAction.done,
            ),

            Obx(
              () => AppBottomSheet<String>(
                label: 'Blood Group',
                hint: 'Select blood group',
                value: ctrl.bloodGroup.value,
                onChanged: (v) => ctrl.bloodGroup.value = v,
                options: [
                  BottomSheetOption(value: 'A+', label: 'A+'),
                  BottomSheetOption(value: 'A-', label: 'A-'),
                  BottomSheetOption(value: 'B+', label: 'B+'),
                  BottomSheetOption(value: 'B-', label: 'B-'),
                  BottomSheetOption(value: 'AB+', label: 'AB+'),
                  BottomSheetOption(value: 'AB-', label: 'AB-'),
                  BottomSheetOption(value: 'O+', label: 'O+'),
                  BottomSheetOption(value: 'O-', label: 'O-'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddictionsField extends StatelessWidget {
  final AddPatientController ctrl;

  const _AddictionsField({required this.ctrl});

  static const _options = [
    'Tea',
    'Coffee',
    'Smoking',
    'Alcohol',
    'Gutka',
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vihara — Addictions',
            style: TextStyle(
              color: AppColors.textDarkGreen,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _options.map((opt) {
                final selected = ctrl.addictions.contains(opt);
                return GestureDetector(
                  onTap: () => ctrl.toggleAddiction(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryGreen
                          : AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryGreen
                            : AppColors.primaryGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : AppColors.textDarkGreen,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Obx(
            () => ctrl.hasOtherAddiction
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FormTextField(
                      label: 'Please specify other addiction',
                      hint: 'Enter details...',
                      controller: ctrl.otherAddictionCtrl,
                      focusNode: ctrl.otherAddictionFocus,
                      textInputAction: TextInputAction.done,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
