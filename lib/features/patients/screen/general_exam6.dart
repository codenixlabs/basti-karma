import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';

class Step6GeneralExam extends StatelessWidget {
  const Step6GeneralExam({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddPatientController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.registerValidation(5, () => true);
      ctrl.weightCtrl.addListener(ctrl.calcBmi);
      ctrl.heightCtrl.addListener(ctrl.calcBmi);
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
        child: FormSectionCard(
          title: 'General Examination',
          icon: Icons.monitor_heart_outlined,
          children: [
            Row(
              children: [
                Expanded(
                  child: FormTextField(
                    label: 'BP (mmHg)',
                    hint: '120/80',
                    controller: ctrl.bpCtrl,
                    focusNode: ctrl.bpFocus,
                    nextFocusNode: ctrl.rrFocus,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormTextField(
                    label: 'RR (bpm)',
                    hint: '16',
                    controller: ctrl.rrCtrl,
                    focusNode: ctrl.rrFocus,
                    nextFocusNode: ctrl.hrFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: FormTextField(
                    label: 'HR (bpm)',
                    hint: '72',
                    controller: ctrl.hrCtrl,
                    focusNode: ctrl.hrFocus,
                    nextFocusNode: ctrl.tempFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormTextField(
                    label: 'Temperature (°F)',
                    hint: '98.6',
                    controller: ctrl.tempCtrl,
                    focusNode: ctrl.tempFocus,
                    nextFocusNode: ctrl.weightFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: FormTextField(
                    label: 'Weight (kg)',
                    hint: '70',
                    controller: ctrl.weightCtrl,
                    focusNode: ctrl.weightFocus,
                    nextFocusNode: ctrl.heightFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormTextField(
                    label: 'Height (cm)',
                    hint: '170',
                    controller: ctrl.heightCtrl,
                    focusNode: ctrl.heightFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),
            Obx(() {
              final bmi = ctrl.bmiDisplay.value;
              final isEmpty = bmi.isEmpty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel(label: 'BMI'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isEmpty
                            ? AppColors.inputBackground
                            : AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: isEmpty
                            ? null
                            : Border.all(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                      ),
                      child: Text(
                        isEmpty ? 'Auto-calculated from Weight & Height' : bmi,
                        style: TextStyle(
                          color: isEmpty
                              ? AppColors.darkGrey
                              : AppColors.primaryGreen,
                          fontSize: 14,
                          fontWeight: isEmpty
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
