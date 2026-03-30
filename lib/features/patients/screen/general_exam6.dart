import 'package:flutter/material.dart';
import '../widgets/form_widget.dart';
import '../../../app/core/theme/app_theme.dart';

class Step6GeneralExam extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const Step6GeneralExam({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrev,
  });

  @override
  State<Step6GeneralExam> createState() => _Step6GeneralExamState();
}

class _Step6GeneralExamState extends State<Step6GeneralExam> {
  late final TextEditingController _bpCtrl;
  late final TextEditingController _rrCtrl;
  late final TextEditingController _hrCtrl;
  late final TextEditingController _tempCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;

  String _bmi = '';

  @override
  void initState() {
    super.initState();
    _bpCtrl = TextEditingController(text: widget.data['bp'] ?? '');
    _rrCtrl = TextEditingController(text: widget.data['rr']?.toString() ?? '');
    _hrCtrl = TextEditingController(text: widget.data['hr']?.toString() ?? '');
    _tempCtrl = TextEditingController(
      text: widget.data['temperature']?.toString() ?? '',
    );
    _weightCtrl = TextEditingController(
      text: widget.data['weight']?.toString() ?? '',
    );
    _heightCtrl = TextEditingController(
      text: widget.data['height']?.toString() ?? '',
    );

    _weightCtrl.addListener(_calcBmi);
    _heightCtrl.addListener(_calcBmi);

    // Compute initial BMI if values exist
    _calcBmi();
  }

  void _calcBmi() {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    if (w != null && h != null && h > 0) {
      final hm = h / 100;
      final bmi = w / (hm * hm);
      String category;
      if (bmi < 18.5) {
        category = 'Underweight';
      } else if (bmi < 25) {
        category = 'Normal';
      } else if (bmi < 30) {
        category = 'Overweight';
      } else {
        category = 'Obese';
      }
      setState(() => _bmi = '${bmi.toStringAsFixed(1)} ($category)');
    } else {
      setState(() => _bmi = '');
    }
  }

  @override
  void dispose() {
    _bpCtrl.dispose();
    _rrCtrl.dispose();
    _hrCtrl.dispose();
    _tempCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.data['bp'] = _bpCtrl.text;
    widget.data['rr'] = double.tryParse(_rrCtrl.text);
    widget.data['hr'] = double.tryParse(_hrCtrl.text);
    widget.data['temperature'] = double.tryParse(_tempCtrl.text);
    widget.data['weight'] = double.tryParse(_weightCtrl.text);
    widget.data['height'] = double.tryParse(_heightCtrl.text);
    widget.data['bmi'] = _bmi;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSectionCard(
          title: 'General Examination',
          icon: Icons.monitor_heart_outlined,
          children: [
            Row(
              children: [
                Expanded(
                  child: FormTextField(
                    label: 'BP (mmHg)',
                    hint: '120/80',
                    controller: _bpCtrl,
                    keyboardType: TextInputType.text,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormTextField(
                    label: 'RR (bpm)',
                    hint: '16',
                    controller: _rrCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: FormTextField(
                    label: 'HR (bpm)',
                    hint: '72',
                    controller: _hrCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormTextField(
                    label: 'Temperature (°F)',
                    hint: '98.6',
                    controller: _tempCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: FormTextField(
                    label: 'Weight (kg)',
                    hint: '70',
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormTextField(
                    label: 'Height (cm)',
                    hint: '170',
                    controller: _heightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            // BMI display
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel(label: 'BMI'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _bmi.isEmpty
                          ? AppColors.inputBackground
                          : AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: _bmi.isEmpty
                          ? null
                          : Border.all(
                        color: AppColors.primaryGreen.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Text(
                      _bmi.isEmpty ? 'Auto-calculated from Weight & Height' : _bmi,
                      style: TextStyle(
                        color: _bmi.isEmpty
                            ? AppColors.darkGrey
                            : AppColors.primaryGreen,
                        fontSize: 14,
                        fontWeight: _bmi.isEmpty
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
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