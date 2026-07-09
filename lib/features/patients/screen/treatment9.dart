import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';

class Step9Treatment extends StatefulWidget {
  const Step9Treatment({super.key});

  @override
  State<Step9Treatment> createState() => _Step9TreatmentState();
}

class _Step9TreatmentState extends State<Step9Treatment> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final ctrl = Get.find<AddPatientController>();
    ctrl.registerValidation(ctrl.totalSteps - 1, () {
      return _formKey.currentState?.validate() ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddPatientController>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
          child: FormSectionCard(
            title: 'Treatment',
            icon: Icons.medication_outlined,
            children: [
              FormTextField(
                label: 'Treatment Given',
                hint:
                    'Ayurvedic/allopathic treatment, medicines, Panchakarma procedures...',
                controller: ctrl.treatmentCtrl,
                focusNode: ctrl.treatmentFocus,
                maxLines: 8,
                required: true,
                textInputAction: TextInputAction.done,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Treatment details are required'
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
