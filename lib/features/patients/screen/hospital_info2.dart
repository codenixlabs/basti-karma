import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart'; // FieldLabel lives here — no need to duplicate
import '../widgets/sticky_nav.dart';

class Step2HospitalInfo extends StatefulWidget {
  const Step2HospitalInfo({super.key});

  @override
  State<Step2HospitalInfo> createState() => _Step2HospitalInfoState();
}

class _Step2HospitalInfoState extends State<Step2HospitalInfo> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddPatientController>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
              child: Form(
                key: _formKey,
                child: FormSectionCard(
                  title: 'Hospital Information',
                  icon: Icons.local_hospital_outlined,
                  children: [
                    // OPD / IPD toggle
                    Obx(() {
                      final isOpd = ctrl.admissionType.value == 'OPD';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Uses shared FieldLabel, no duplicate
                          const FieldLabel(label: 'Admission Type'),
                          const SizedBox(height: 8),
                          Row(
                            children: ['OPD', 'IPD'].map((type) {
                              final selected = ctrl.admissionType.value == type;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => ctrl.admissionType.value = type,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: EdgeInsets.only(
                                      right: type == 'OPD' ? 6 : 0,
                                      left: type == 'IPD' ? 6 : 0,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primaryGreen
                                          : AppColors.inputBackground,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.primaryGreen,
                                        width: selected ? 0 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          type == 'OPD'
                                              ? Icons.person_outlined
                                              : Icons.bed_outlined,
                                          size: 18,
                                          color: selected
                                              ? Colors.white
                                              : AppColors.primaryGreen,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          type,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: selected
                                                ? Colors.white
                                                : AppColors.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          if (isOpd)
                            FormTextField(
                              label: 'OPD Number',
                              hint: 'Enter OPD number (optional)',
                              controller: ctrl.opdCtrl,
                              focusNode: ctrl.opdFocus,
                              nextFocusNode: ctrl.diagnosisFocus,
                            )
                          else
                            FormTextField(
                              label: 'IPD Number',
                              hint: 'Enter IPD number (optional)',
                              controller: ctrl.ipdCtrl,
                              focusNode: ctrl.ipdFocus,
                              nextFocusNode: ctrl.diagnosisFocus,
                            ),
                        ],
                      );
                    }),

                    // Diagnosis — required
                    FormTextField(
                      label: 'Diagnosis',
                      hint: 'Enter clinical diagnosis',
                      controller: ctrl.diagnosisCtrl,
                      focusNode: ctrl.diagnosisFocus,
                      maxLines: 3,
                      required: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Diagnosis is required'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          StickyNav(
            onPrev: ctrl.prev,
            onNext: () {
              if (_formKey.currentState!.validate()) ctrl.next();
            },
          ),
        ],
      ),
    );
  }
}
