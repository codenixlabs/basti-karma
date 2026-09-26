import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../../../app/data/models/patient/patient_model.dart';
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

class AddPatientScreen extends StatefulWidget {
  final PatientModel? patientToEdit;
  final int initialStep;

  const AddPatientScreen({
    super.key,
    this.patientToEdit,
    this.initialStep = 0,
  });

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  late final AddPatientController ctrl;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AddPatientController>()) {
      ctrl = Get.find<AddPatientController>();
    } else {
      ctrl = Get.put(AddPatientController());
    }

    if (widget.patientToEdit != null) {
      ctrl.initForEdit(widget.patientToEdit!, initialStep: widget.initialStep);
    } else {
      ctrl.resetForm();
    }
  }

  void _showStepSelectionSheet(BuildContext context, AddPatientController ctrl) {
    final titles = ctrl.allStepTitles;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Jump to Section',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDarkGreen,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: titles.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final isCurrent = i == ctrl.currentStep.value;
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      radius: 13,
                      backgroundColor: isCurrent
                          ? AppColors.primaryGreen
                          : AppColors.primaryGreen.withValues(alpha: 0.1),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? Colors.white : AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    title: Text(
                      titles[i],
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent ? AppColors.primaryGreen : AppColors.textDarkGreen,
                      ),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 18)
                        : const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.darkGrey),
                    onTap: () {
                      Get.back();
                      ctrl.goToStep(i);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Rebuilds on step change and sex change (totalSteps / stepTitle depend on both)
            Obx(() => FormStepHeader(
              title: ctrl.isEditMode ? 'Edit Patient' : 'Add New Patient',
              subtitle: ctrl.isEditMode
                  ? '${ctrl.nameCtrl.text.isNotEmpty ? ctrl.nameCtrl.text : "Patient"} • ${ctrl.stepTitle}'
                  : ctrl.stepTitle,
              currentStep: ctrl.currentStep.value + 1,
              totalSteps: ctrl.totalSteps,
              onBack: ctrl.prev,
              onTapProgress: () => _showStepSelectionSheet(context, ctrl),
              action: ctrl.isEditMode
                  ? GestureDetector(
                      onTap: ctrl.isSubmitting.value ? null : ctrl.submitForm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (ctrl.isSubmitting.value)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGreen,
                                ),
                              )
                            else ...[
                              const Icon(
                                Icons.save_outlined,
                                size: 16,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Save',
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : null,
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
              isLoading: ctrl.isSubmitting.value,
              submitLabel: ctrl.isEditMode ? 'Update Patient' : 'Submit',
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
