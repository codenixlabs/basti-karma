import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';
import '../widgets/sticky_nav.dart';

class Step5FemaleHistory extends StatelessWidget {
  const Step5FemaleHistory({super.key});

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
              child: FormSectionCard(
                title: 'Menstrual & Obstetric History',
                icon: Icons.female_rounded,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This section is shown for female patients only.',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FormTextField(
                          label: 'No. of Deliveries',
                          hint: '0',
                          controller: ctrl.deliveriesCtrl,
                          focusNode: ctrl.deliveriesFocus,
                          nextFocusNode: ctrl.abortionFocus,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FormTextField(
                          label: 'Abortions',
                          hint: '0',
                          controller: ctrl.abortionCtrl,
                          focusNode: ctrl.abortionFocus,
                          nextFocusNode: ctrl.surgicalFocus,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  FormTextField(
                    label: 'Surgical Intervention',
                    hint: 'Details of any surgical procedures...',
                    controller: ctrl.surgicalCtrl,
                    focusNode: ctrl.surgicalFocus,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
          ),
          StickyNav(onPrev: ctrl.prev, onNext: ctrl.next),
        ],
      ),
    );
  }
}