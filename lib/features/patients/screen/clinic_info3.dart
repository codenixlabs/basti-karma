import 'package:flutter/material.dart';
import '../widgets/form_widget.dart';

class Step3ClinicalInfo extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const Step3ClinicalInfo({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrev,
  });

  @override
  State<Step3ClinicalInfo> createState() => _Step3ClinicalInfoState();
}

class _Step3ClinicalInfoState extends State<Step3ClinicalInfo> {
  late final TextEditingController _chiefComplaintsCtrl;
  late final TextEditingController _presentIllnessCtrl;
  late final TextEditingController _pastIllnessCtrl;
  late final TextEditingController _familyHistoryCtrl;

  @override
  void initState() {
    super.initState();
    _chiefComplaintsCtrl = TextEditingController(
      text: widget.data['chiefComplaints'] ?? '',
    );
    _presentIllnessCtrl = TextEditingController(
      text: widget.data['historyPresentIllness'] ?? '',
    );
    _pastIllnessCtrl = TextEditingController(
      text: widget.data['historyPastIllness'] ?? '',
    );
    _familyHistoryCtrl = TextEditingController(
      text: widget.data['familyHistory'] ?? '',
    );
  }

  @override
  void dispose() {
    _chiefComplaintsCtrl.dispose();
    _presentIllnessCtrl.dispose();
    _pastIllnessCtrl.dispose();
    _familyHistoryCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.data['chiefComplaints'] = _chiefComplaintsCtrl.text;
    widget.data['historyPresentIllness'] = _presentIllnessCtrl.text;
    widget.data['historyPastIllness'] = _pastIllnessCtrl.text;
    widget.data['familyHistory'] = _familyHistoryCtrl.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSectionCard(
          title: 'Clinical Information',
          icon: Icons.medical_services_outlined,
          children: [
            FormTextField(
              label: 'Chief Complaints',
              hint: 'Describe chief complaints...',
              controller: _chiefComplaintsCtrl,
              maxLines: 3,
              required: true,
            ),
            FormTextField(
              label: 'History of Present Illness',
              hint: 'Describe present illness history...',
              controller: _presentIllnessCtrl,
              maxLines: 4,
            ),
            FormTextField(
              label: 'History of Past Illness',
              hint: 'Any previous illnesses, surgeries...',
              controller: _pastIllnessCtrl,
              maxLines: 3,
            ),
            FormTextField(
              label: 'Family History',
              hint: 'Family medical history...',
              controller: _familyHistoryCtrl,
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