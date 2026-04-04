import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';

class Step9Treatment extends StatelessWidget {
  const Step9Treatment({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddPatientController>();
    final formKey = GlobalKey<FormState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.registerValidation(ctrl.totalSteps - 1, () {
        if (formKey.currentState!.validate()) {
          return true;
        }
        return false;
      });
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Form(
        key: formKey,
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
