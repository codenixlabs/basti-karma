import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/widgets/app_dropdown.dart';
import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';

class Step1BasicInfo extends StatefulWidget {
  const Step1BasicInfo({super.key});

  @override
  State<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends State<Step1BasicInfo> {
  final _formKey = GlobalKey<FormState>();
  bool _showSexError = false;

  @override
  void initState() {
    super.initState();
    final ctrl = Get.find<AddPatientController>();
    ctrl.registerValidation(0, () {
      final formValid = _formKey.currentState?.validate() ?? false;
      if (ctrl.sex.value == null) {
        setState(() => _showSexError = true);
        return false;
      }
      return formValid;
    });
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
                        if (age == null || age < 1) return 'Enter a valid age';
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
                      autovalidateMode: AutovalidateMode.onUnfocus,
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
              Obx(() {
                final hasError = _showSexError && ctrl.sex.value == null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormRadioGroup<String>(
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
                    if (hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 10, left: 4),
                        child: Text(
                          'Please select sex',
                          style: const TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 11,
                            height: 0.8,
                          ),
                        ),
                      ),
                  ],
                );
              }),

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
