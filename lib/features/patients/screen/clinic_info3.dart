import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';

class Step3ClinicalInfo extends StatefulWidget {
  const Step3ClinicalInfo({super.key});

  @override
  State<Step3ClinicalInfo> createState() => _Step3ClinicalInfoState();
}

class _Step3ClinicalInfoState extends State<Step3ClinicalInfo> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final ctrl = Get.find<AddPatientController>();
    ctrl.registerValidation(2, () => _formKey.currentState?.validate() ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddPatientController>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
        child: Form(
          key: _formKey,
          child: FormSectionCard(
            title: 'Clinical Information',
            icon: Icons.medical_services_outlined,
            children: [
              FormTextField(
                label: 'Chief Complaints',
                hint: 'Describe chief complaints...',
                controller: ctrl.chiefComplaintsCtrl,
                focusNode: ctrl.chiefComplaintsFocus,
                nextFocusNode: ctrl.presentIllnessFocus,
                maxLines: 3,
                required: true,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Chief complaints are required'
                    : null,
              ),
              FormTextField(
                label: 'History of Present Illness',
                hint: 'Describe present illness history...',
                controller: ctrl.presentIllnessCtrl,
                focusNode: ctrl.presentIllnessFocus,
                nextFocusNode: ctrl.pastIllnessFocus,
                maxLines: 4,
              ),
              FormTextField(
                label: 'History of Past Illness',
                hint: 'Any previous illnesses, surgeries...',
                controller: ctrl.pastIllnessCtrl,
                focusNode: ctrl.pastIllnessFocus,
                nextFocusNode: ctrl.familyHistoryFocus,
                maxLines: 3,
              ),
              FormTextField(
                label: 'Family History',
                hint: 'Family medical history...',
                controller: ctrl.familyHistoryCtrl,
                focusNode: ctrl.familyHistoryFocus,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
