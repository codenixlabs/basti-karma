import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';
import '../widgets/sticky_nav.dart';
import 'basic_info1.dart';
import 'clinic_info3.dart';
import 'female_history5.dart';
import 'general_exam6.dart';
import 'hospital_info2.dart';
import 'investigations8.dart';
import 'life_style4.dart';
import 'rogi_pariksha7.dart';
import 'treatment9.dart';

class AddPatientScreen extends StatelessWidget {
  const AddPatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddPatientController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Rebuilds on step change and sex change (totalSteps / stepTitle depend on both)
            Obx(() => FormStepHeader(
              title: 'Add New Patient',
              subtitle: ctrl.stepTitle,
              currentStep: ctrl.currentStep.value + 1,
              totalSteps: ctrl.totalSteps,
              onBack: ctrl.prev,
            )),
            // Rebuilds only when sex changes (isFemale changes page count)
            Expanded(
              child: Obx(() {
                final pages = _buildPages(ctrl);
                return PageView.builder(
                  controller: ctrl.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pages.length,
                  itemBuilder: (_, i) => pages[i],
                );
              }),
            ),
            // Rebuilds on step change (button label and Prev visibility)
            Obx(() => StickyNav(
              showPrev: ctrl.currentStep.value > 0,
              isLastStep: ctrl.currentStep.value == ctrl.totalSteps - 1,
              onPrev: ctrl.prev,
              onNext: () => ctrl.validateAndNext(),
              onSubmit: () => ctrl.submitForm(),
            )),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPages(AddPatientController ctrl) {
    final pages = <Widget>[
      const Step1BasicInfo(),
      const Step2HospitalInfo(),
      const Step3ClinicalInfo(),
      const Step4Lifestyle(),
    ];
    if (ctrl.isFemale) pages.add(const Step5FemaleHistory());
    pages.addAll([
      const Step6GeneralExam(),
      const Step7RogiPariksha(),
      const Step8Investigations(),
      const Step9Treatment(),
    ]);
    return pages;
  }
}
