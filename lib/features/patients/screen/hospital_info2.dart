import 'package:flutter/material.dart';
import '../widgets/form_widget.dart';

class Step2HospitalInfo extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const Step2HospitalInfo({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrev,
  });

  @override
  State<Step2HospitalInfo> createState() => _Step2HospitalInfoState();
}

class _Step2HospitalInfoState extends State<Step2HospitalInfo> {
  late final TextEditingController _opdCtrl;
  late final TextEditingController _ipdCtrl;
  late final TextEditingController _diagnosisCtrl;

  @override
  void initState() {
    super.initState();
    _opdCtrl = TextEditingController(text: widget.data['opdNo'] ?? '');
    _ipdCtrl = TextEditingController(text: widget.data['ipdNo'] ?? '');
    _diagnosisCtrl = TextEditingController(text: widget.data['diagnosis'] ?? '');
  }

  @override
  void dispose() {
    _opdCtrl.dispose();
    _ipdCtrl.dispose();
    _diagnosisCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.data['opdNo'] = _opdCtrl.text;
    widget.data['ipdNo'] = _ipdCtrl.text;
    widget.data['diagnosis'] = _diagnosisCtrl.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSectionCard(
          title: 'Hospital Information',
          icon: Icons.local_hospital_outlined,
          children: [
            Row(
              children: [
                Expanded(
                  child: FormTextField(
                    label: 'OPD No',
                    hint: 'Enter OPD number',
                    controller: _opdCtrl,
                    keyboardType: TextInputType.text,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormTextField(
                    label: 'IPD No',
                    hint: 'Enter IPD number',
                    controller: _ipdCtrl,
                    keyboardType: TextInputType.text,
                  ),
                ),
              ],
            ),
            FormTextField(
              label: 'Diagnosis',
              hint: 'Enter clinical diagnosis',
              controller: _diagnosisCtrl,
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