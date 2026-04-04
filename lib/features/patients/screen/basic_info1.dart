import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/shared/widgets/app_dropdown.dart';
import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';

class Step1BasicInfo extends StatelessWidget {
  const Step1BasicInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddPatientController>();
    final formKey = GlobalKey<FormState>();

    // Register validation callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.registerValidation(0, () {
        if (formKey.currentState!.validate()) {
          return true;
        }
        return false;
      });
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
        child: Form(
          key: formKey,
          child: FormSectionCard(
            title: 'Basic Patient Information',
            icon: Icons.person_outline_rounded,
            children: [
              // Full Name
              FormTextField(
                label: 'Full Name',
                hint: 'Enter patient name',
                controller: ctrl.nameCtrl,
                focusNode: ctrl.nameFocus,
                nextFocusNode: ctrl.ageFocus,
                required: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FormTextField(
                      label: 'Age',
                      hint: 'Years',
                      controller: ctrl.ageCtrl,
                      focusNode: ctrl.ageFocus,
                      nextFocusNode: ctrl.phoneFocus,
                      required: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final age = int.tryParse(v);
                        if (age == null || age <= 0 || age > 120) {
                          return 'Enter valid age (1–120)';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormTextField(
                      label: 'Phone No',
                      hint: 'XXXXXXXXXX',
                      controller: ctrl.phoneCtrl,
                      focusNode: ctrl.phoneFocus,
                      nextFocusNode: ctrl.occupationFocus,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (v.length != 10) return 'Must be 10 digits';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              // Sex
              Obx(
                () => FormRadioGroup<String>(
                  label: 'Sex',
                  required: true,
                  groupValue: ctrl.sex.value,
                  options: const [
                    (value: 'Male', label: 'Male'),
                    (value: 'Female', label: 'Female'),
                    (value: 'Other', label: 'Other'),
                  ],
                  onChanged: (v) => ctrl.sex.value = v,
                ),
              ),

              // Religion
              Obx(
                () => AppBottomSheet<String>(
                  label: 'Religion',
                  hint: 'Select religion',
                  value: ctrl.religion.value,
                  onChanged: (v) => ctrl.religion.value = v,
                  options: [
                    BottomSheetOption(value: 'Hindu', label: 'Hindu'),
                    BottomSheetOption(value: 'Muslim', label: 'Muslim'),
                    BottomSheetOption(value: 'Christian', label: 'Christian'),
                    BottomSheetOption(value: 'Sikh', label: 'Sikh'),
                    BottomSheetOption(value: 'Jain', label: 'Jain'),
                    BottomSheetOption(value: 'Buddhist', label: 'Buddhist'),
                    BottomSheetOption(value: 'Other', label: 'Other'),
                  ],
                ),
              ),

              // Occupation
              FormTextField(
                label: 'Occupation',
                hint: 'e.g., Farmer, Teacher, Business',
                controller: ctrl.occupationCtrl,
                focusNode: ctrl.occupationFocus,
                nextFocusNode: ctrl.addressFocus,
              ),

              // Marital Status
              Obx(
                () => AppBottomSheet<String>(
                  label: 'Marital Status',
                  hint: 'Select marital status',
                  value: ctrl.maritalStatus.value,
                  onChanged: (v) => ctrl.maritalStatus.value = v,
                  options: [
                    BottomSheetOption(value: 'Single', label: 'Single'),
                    BottomSheetOption(value: 'Married', label: 'Married'),
                    BottomSheetOption(value: 'Widowed', label: 'Widowed'),
                    BottomSheetOption(value: 'Divorced', label: 'Divorced'),
                  ],
                ),
              ),

              // Address
              FormTextField(
                label: 'Address',
                hint: 'Enter full address',
                controller: ctrl.addressCtrl,
                focusNode: ctrl.addressFocus,
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
