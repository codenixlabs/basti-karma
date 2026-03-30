import 'package:flutter/material.dart';
import '../widgets/form_widget.dart';
import '../../../app/core/theme/app_theme.dart';

class Step9Treatment extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onSubmit;
  final VoidCallback onPrev;

  const Step9Treatment({
    super.key,
    required this.data,
    required this.onSubmit,
    required this.onPrev,
  });

  @override
  State<Step9Treatment> createState() => _Step9TreatmentState();
}

class _Step9TreatmentState extends State<Step9Treatment> {
  late final TextEditingController _treatmentCtrl;

  @override
  void initState() {
    super.initState();
    _treatmentCtrl = TextEditingController(
      text: widget.data['treatment'] ?? '',
    );
  }

  @override
  void dispose() {
    _treatmentCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.data['treatment'] = _treatmentCtrl.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSectionCard(
          title: 'Treatment',
          icon: Icons.medication_outlined,
          children: [
            // Treatment summary banner
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
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
                  const SizedBox(height: 4),
                  const Text(
                    'Enter the treatment prescribed for the patient. This completes the patient record.',
                    style: TextStyle(color: AppColors.darkGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            FormTextField(
              label: 'Treatment Given',
              hint:
                  'Describe Ayurvedic/allopathic treatment, medicines, Panchakarma procedures...',
              controller: _treatmentCtrl,
              maxLines: 8,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormNavButtons(
          isLastStep: true,
          onPrev: widget.onPrev,
          onSubmit: () {
            _save();
            widget.onSubmit();
          },
        ),
      ],
    );
  }
}
