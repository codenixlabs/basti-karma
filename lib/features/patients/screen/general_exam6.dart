import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';
import '../widgets/sticky_nav.dart';

class Step6GeneralExam extends StatefulWidget {
  const Step6GeneralExam({super.key});

  @override
  State<Step6GeneralExam> createState() => _Step6GeneralExamState();
}

class _Step6GeneralExamState extends State<Step6GeneralExam> {
  late final AddPatientController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AddPatientController>();
    _ctrl.weightCtrl.addListener(_ctrl.calcBmi);
    _ctrl.heightCtrl.addListener(_ctrl.calcBmi);
  }

  @override
  void dispose() {
    _ctrl.weightCtrl.removeListener(_ctrl.calcBmi);
    _ctrl.heightCtrl.removeListener(_ctrl.calcBmi);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
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
                          controller: _ctrl.bpCtrl,
                          focusNode: _ctrl.bpFocus,
                          nextFocusNode: _ctrl.rrFocus,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FormTextField(
                          label: 'RR (bpm)',
                          hint: '16',
                          controller: _ctrl.rrCtrl,
                          focusNode: _ctrl.rrFocus,
                          nextFocusNode: _ctrl.hrFocus,
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
                          controller: _ctrl.hrCtrl,
                          focusNode: _ctrl.hrFocus,
                          nextFocusNode: _ctrl.tempFocus,
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
                          controller: _ctrl.tempCtrl,
                          focusNode: _ctrl.tempFocus,
                          nextFocusNode: _ctrl.weightFocus,
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
                          controller: _ctrl.weightCtrl,
                          focusNode: _ctrl.weightFocus,
                          nextFocusNode: _ctrl.heightFocus,
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
                          controller: _ctrl.heightCtrl,
                          focusNode: _ctrl.heightFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                    ],
                  ),

                  // Auto-calculated BMI display
                  Obx(() {
                    final bmi = _ctrl.bmiDisplay.value;
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
                                  : AppColors.primaryGreen.withValues(
                                      alpha: 0.1,
                                    ),
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
                              isEmpty
                                  ? 'Auto-calculated from Weight & Height'
                                  : bmi,
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
          ),
          StickyNav(onPrev: _ctrl.prev, onNext: _ctrl.next),
        ],
      ),
    );
  }
}
