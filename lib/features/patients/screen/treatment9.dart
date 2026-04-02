import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';
import '../widgets/sticky_nav.dart';

class Step9Treatment extends StatefulWidget {
  const Step9Treatment({super.key});

  @override
  State<Step9Treatment> createState() => _Step9TreatmentState();
}

class _Step9TreatmentState extends State<Step9Treatment> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddPatientController>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Scrollable content — critical when keyboard is open
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                child: FormSectionCard(
                  title: 'Treatment',
                  icon: Icons.medication_outlined,
                  children: [
                    // Summary banner
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGreen.withValues(alpha: 0.08),
                            AppColors.primaryGreen.withValues(alpha: 0.03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.summarize_outlined,
                                size: 16,
                                color: AppColors.primaryGreen,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Final Step',
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enter the treatment prescribed for the patient. '
                            'This completes the patient record.',
                            style: TextStyle(
                              color: AppColors.darkGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

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

            StickyNav(
              isLastStep: true,
              onPrev: ctrl.prev,
              onSubmit: () {
                if (_formKey.currentState!.validate()) {
                  _showSuccessDialog(context, ctrl);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, AddPatientController ctrl) {
    final name = ctrl.nameCtrl.text.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.primaryGreen,
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Patient Added!',
              style: TextStyle(
                color: AppColors.textDarkGreen,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${name.isEmpty ? 'Patient' : name} has been successfully registered.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.darkGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back(); // close dialog
                  Get.back(); // pop AddPatientScreen (controller auto-disposed)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
