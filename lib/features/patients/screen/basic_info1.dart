import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/form_widget.dart';

class Step1BasicInfo extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;
  final VoidCallback? onPrev;

  const Step1BasicInfo({
    super.key,
    required this.data,
    required this.onNext,
    this.onPrev,
  });

  @override
  State<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends State<Step1BasicInfo> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _occupationCtrl;
  late final TextEditingController _addressCtrl;

  String? _sex;
  String? _religion;
  String? _maritalStatus;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data['name'] ?? '');
    _ageCtrl = TextEditingController(text: widget.data['age']?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: widget.data['phone'] ?? '');
    _occupationCtrl = TextEditingController(text: widget.data['occupation'] ?? '');
    _addressCtrl = TextEditingController(text: widget.data['address'] ?? '');
    _sex = widget.data['sex'];
    _religion = widget.data['religion'];
    _maritalStatus = widget.data['maritalStatus'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _occupationCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.data['name'] = _nameCtrl.text;
    widget.data['age'] = int.tryParse(_ageCtrl.text);
    widget.data['sex'] = _sex;
    widget.data['phone'] = _phoneCtrl.text;
    widget.data['occupation'] = _occupationCtrl.text;
    widget.data['address'] = _addressCtrl.text;
    widget.data['religion'] = _religion;
    widget.data['maritalStatus'] = _maritalStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          FormSectionCard(
            title: 'Basic Patient Information',
            icon: Icons.person_outline_rounded,
            children: [
              FormTextField(
                label: 'Full Name',
                hint: 'Enter patient name',
                controller: _nameCtrl,
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
                      controller: _ageCtrl,
                      required: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FormTextField(
                      label: 'Phone No',
                      hint: '+91 XXXXXXXXXX',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              FormRadioGroup<String>(
                label: 'Sex',
                required: true,
                groupValue: _sex,
                options: const [
                  (value: 'Male', label: 'Male'),
                  (value: 'Female', label: 'Female'),
                  (value: 'Other', label: 'Other'),
                ],
                onChanged: (v) => setState(() => _sex = v),
              ),
              FormDropdownField<String>(
                label: 'Religion',
                hint: 'Select religion',
                value: _religion,
                onChanged: (v) => setState(() => _religion = v),
                items: const [
                  DropdownMenuItem(value: 'Hindu', child: Text('Hindu')),
                  DropdownMenuItem(value: 'Muslim', child: Text('Muslim')),
                  DropdownMenuItem(
                    value: 'Christian',
                    child: Text('Christian'),
                  ),
                  DropdownMenuItem(value: 'Sikh', child: Text('Sikh')),
                  DropdownMenuItem(value: 'Jain', child: Text('Jain')),
                  DropdownMenuItem(
                    value: 'Buddhist',
                    child: Text('Buddhist'),
                  ),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
              ),
              FormTextField(
                label: 'Occupation',
                hint: 'e.g., Farmer, Teacher, Business',
                controller: _occupationCtrl,
              ),
              FormDropdownField<String>(
                label: 'Marital Status',
                hint: 'Select marital status',
                value: _maritalStatus,
                onChanged: (v) => setState(() => _maritalStatus = v),
                items: const [
                  DropdownMenuItem(value: 'Single', child: Text('Single')),
                  DropdownMenuItem(value: 'Married', child: Text('Married')),
                  DropdownMenuItem(
                    value: 'Widowed',
                    child: Text('Widowed'),
                  ),
                  DropdownMenuItem(
                    value: 'Divorced',
                    child: Text('Divorced'),
                  ),
                ],
              ),
              FormTextField(
                label: 'Address',
                hint: 'Enter full address',
                controller: _addressCtrl,
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FormNavButtons(
            showPrev: false,
            onNext: () {
              if (_formKey.currentState!.validate()) {
                _save();
                widget.onNext();
              }
            },
          ),
        ],
      ),
    );
  }
}