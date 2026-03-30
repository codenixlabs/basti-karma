import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/form_widget.dart';
import '../../../app/core/theme/app_theme.dart';

class Step5FemaleHistory extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const Step5FemaleHistory({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrev,
  });

  @override
  State<Step5FemaleHistory> createState() => _Step5FemaleHistoryState();
}

class _Step5FemaleHistoryState extends State<Step5FemaleHistory> {
  late final TextEditingController _deliveriesCtrl;
  late final TextEditingController _abortionCtrl;
  late final TextEditingController _surgicalCtrl;

  @override
  void initState() {
    super.initState();
    _deliveriesCtrl = TextEditingController(
      text: widget.data['numberOfDeliveries']?.toString() ?? '',
    );
    _abortionCtrl = TextEditingController(
      text: widget.data['abortion']?.toString() ?? '',
    );
    _surgicalCtrl = TextEditingController(
      text: widget.data['surgicalIntervention'] ?? '',
    );
  }

  @override
  void dispose() {
    _deliveriesCtrl.dispose();
    _abortionCtrl.dispose();
    _surgicalCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.data['numberOfDeliveries'] =
        int.tryParse(_deliveriesCtrl.text);
    widget.data['abortion'] = int.tryParse(_abortionCtrl.text);
    widget.data['surgicalIntervention'] = _surgicalCtrl.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSectionCard(
          title: 'Menstrual & Obstetric History',
          icon: Icons.female_rounded,
          children: [
            // Info banner
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
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
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
                    label: 'Number of Deliveries',
                    hint: '0',
                    controller: _deliveriesCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormTextField(
                    label: 'Abortions',
                    hint: '0',
                    controller: _abortionCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            FormTextField(
              label: 'Surgical Intervention',
              hint: 'Details of any surgical procedures...',
              controller: _surgicalCtrl,
              maxLines: 3,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormNavButtons(
          onPrev: widget.onPrev,
          onNext: () {
            _save();
            widget.onNext();
          },
        ),
      ],
    );
  }
}