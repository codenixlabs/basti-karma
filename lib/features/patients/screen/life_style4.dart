import 'package:flutter/material.dart';
import '../widgets/form_widget.dart';

class Step4Lifestyle extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const Step4Lifestyle({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrev,
  });

  @override
  State<Step4Lifestyle> createState() => _Step4LifestyleState();
}

class _Step4LifestyleState extends State<Step4Lifestyle> {
  String? _diet;
  Set<String> _addictions = {};
  String? _bowelHabits;
  String? _nidra;
  String? _bloodGroup;
  late final TextEditingController _urineFreqCtrl;

  @override
  void initState() {
    super.initState();
    _diet = widget.data['diet'];
    _addictions = Set<String>.from(widget.data['addictions'] ?? []);
    _bowelHabits = widget.data['bowelHabits'];
    _nidra = widget.data['nidra'];
    _bloodGroup = widget.data['bloodGroup'];
    _urineFreqCtrl = TextEditingController(
      text: widget.data['urineFrequency'] ?? '',
    );
  }

  @override
  void dispose() {
    _urineFreqCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.data['diet'] = _diet;
    widget.data['addictions'] = _addictions.toList();
    widget.data['bowelHabits'] = _bowelHabits;
    widget.data['nidra'] = _nidra;
    widget.data['bloodGroup'] = _bloodGroup;
    widget.data['urineFrequency'] = _urineFreqCtrl.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSectionCard(
          title: 'Lifestyle (Ahara & Vihara)',
          icon: Icons.restaurant_outlined,
          children: [
            FormRadioGroup<String>(
              label: 'Ahara (Diet)',
              groupValue: _diet,
              options: const [
                (value: 'Vegetarian', label: 'Vegetarian'),
                (value: 'Mixed', label: 'Mixed'),
              ],
              onChanged: (v) => setState(() => _diet = v),
            ),
            FormChipGroup(
              label: 'Vihara — Addictions',
              options: const [
                'Tea',
                'Coffee',
                'Smoking',
                'Alcohol',
                'Gutka',
                'Others',
              ],
              selected: _addictions,
              onToggle: (opt) => setState(() {
                if (_addictions.contains(opt)) {
                  _addictions.remove(opt);
                } else {
                  _addictions.add(opt);
                }
              }),
            ),
            FormDropdownField<String>(
              label: 'Bowel Habits',
              hint: 'Select bowel habits',
              value: _bowelHabits,
              onChanged: (v) => setState(() => _bowelHabits = v),
              items: const [
                DropdownMenuItem(value: 'Regular', child: Text('Regular')),
                DropdownMenuItem(
                  value: 'Irregular',
                  child: Text('Irregular'),
                ),
                DropdownMenuItem(
                  value: 'Constipated',
                  child: Text('Constipated'),
                ),
                DropdownMenuItem(value: 'Watery', child: Text('Watery')),
                DropdownMenuItem(value: 'Others', child: Text('Others')),
              ],
            ),
            FormDropdownField<String>(
              label: 'Nidra (Sleep)',
              hint: 'Select sleep pattern',
              value: _nidra,
              onChanged: (v) => setState(() => _nidra = v),
              items: const [
                DropdownMenuItem(value: 'Sound', child: Text('Sound')),
                DropdownMenuItem(
                  value: 'Disturbed',
                  child: Text('Disturbed'),
                ),
              ],
            ),
            FormTextField(
              label: 'Urine Frequency',
              hint: 'e.g., 6-8 times/day',
              controller: _urineFreqCtrl,
            ),
            FormDropdownField<String>(
              label: 'Blood Group',
              hint: 'Select blood group',
              value: _bloodGroup,
              onChanged: (v) => setState(() => _bloodGroup = v),
              items: const [
                DropdownMenuItem(value: 'A+', child: Text('A+')),
                DropdownMenuItem(value: 'A-', child: Text('A-')),
                DropdownMenuItem(value: 'B+', child: Text('B+')),
                DropdownMenuItem(value: 'B-', child: Text('B-')),
                DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                DropdownMenuItem(value: 'O+', child: Text('O+')),
                DropdownMenuItem(value: 'O-', child: Text('O-')),
              ],
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