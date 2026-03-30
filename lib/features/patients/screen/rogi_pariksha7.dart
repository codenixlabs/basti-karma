import 'package:flutter/material.dart';
import '../widgets/form_widget.dart';

class Step7RogiPariksha extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const Step7RogiPariksha({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrev,
  });

  @override
  State<Step7RogiPariksha> createState() => _Step7RogiParikshaState();
}

class _Step7RogiParikshaState extends State<Step7RogiPariksha> {
  String? _prakriti;
  String? _sarataha;
  String? _sanhanan;
  String? _pramana;
  String? _satva;
  String? _satmya;
  String? _aharaShakti;
  String? _vyayamaShakti;
  String? _vaya;
  String? _jihwa;
  String? _desha;

  @override
  void initState() {
    super.initState();
    _prakriti = widget.data['prakriti'];
    _sarataha = widget.data['sarataha'];
    _sanhanan = widget.data['sanhanan'];
    _pramana = widget.data['pramana'];
    _satva = widget.data['satva'];
    _satmya = widget.data['satmya'];
    _aharaShakti = widget.data['aharaShakti'];
    _vyayamaShakti = widget.data['vyayamaShakti'];
    _vaya = widget.data['vaya'];
    _jihwa = widget.data['jihwa'];
    _desha = widget.data['desha'];
  }

  void _save() {
    widget.data['prakriti'] = _prakriti;
    widget.data['sarataha'] = _sarataha;
    widget.data['sanhanan'] = _sanhanan;
    widget.data['pramana'] = _pramana;
    widget.data['satva'] = _satva;
    widget.data['satmya'] = _satmya;
    widget.data['aharaShakti'] = _aharaShakti;
    widget.data['vyayamaShakti'] = _vyayamaShakti;
    widget.data['vaya'] = _vaya;
    widget.data['jihwa'] = _jihwa;
    widget.data['desha'] = _desha;
  }

  DropdownMenuItem<String> _item(String v) =>
      DropdownMenuItem(value: v, child: Text(v));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSectionCard(
          title: 'Rogi Pariksha',
          icon: Icons.spa_outlined,
          children: [
            FormDropdownField<String>(
              label: 'Prakriti',
              hint: 'Select Prakriti',
              value: _prakriti,
              onChanged: (v) => setState(() => _prakriti = v),
              items: [
                _item('Vata'),
                _item('Pitta'),
                _item('Kapha'),
                _item('Vata-Pitta'),
                _item('Pitta-Kapha'),
                _item('Vata-Kapha'),
                _item('Sama Prakriti'),
              ],
            ),
            FormDropdownField<String>(
              label: 'Sarataha (Tissue Quality)',
              hint: 'Select Sarataha',
              value: _sarataha,
              onChanged: (v) => setState(() => _sarataha = v),
              items: [
                _item('Pravara (Excellent)'),
                _item('Madhyama (Moderate)'),
                _item('Avara (Poor)'),
              ],
            ),
            FormDropdownField<String>(
              label: 'Sanhanan (Body Constitution)',
              hint: 'Select Sanhanan',
              value: _sanhanan,
              onChanged: (v) => setState(() => _sanhanan = v),
              items: [
                _item('Pravara (Excellent)'),
                _item('Madhyama (Moderate)'),
                _item('Avara (Poor)'),
              ],
            ),
            FormDropdownField<String>(
              label: 'Pramana (Body Proportion)',
              hint: 'Select Pramana',
              value: _pramana,
              onChanged: (v) => setState(() => _pramana = v),
              items: [
                _item('Pravara (Excellent)'),
                _item('Madhyama (Moderate)'),
                _item('Avara (Poor)'),
              ],
            ),
            FormDropdownField<String>(
              label: 'Satva (Mental Strength)',
              hint: 'Select Satva',
              value: _satva,
              onChanged: (v) => setState(() => _satva = v),
              items: [
                _item('Pravara (Excellent)'),
                _item('Madhyama (Moderate)'),
                _item('Avara (Poor)'),
              ],
            ),
            FormDropdownField<String>(
              label: 'Satmya (Adaptability)',
              hint: 'Select Satmya',
              value: _satmya,
              onChanged: (v) => setState(() => _satmya = v),
              items: [
                _item('Sarvarasa Satmya'),
                _item('Madhyama Satmya'),
                _item('Ekarasa Satmya'),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: FormDropdownField<String>(
                    label: 'Ahara Shakti',
                    hint: 'Select',
                    value: _aharaShakti,
                    onChanged: (v) => setState(() => _aharaShakti = v),
                    items: [
                      _item('Pravara'),
                      _item('Madhyama'),
                      _item('Avara'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormDropdownField<String>(
                    label: 'Vyayama Shakti',
                    hint: 'Select',
                    value: _vyayamaShakti,
                    onChanged: (v) => setState(() => _vyayamaShakti = v),
                    items: [
                      _item('Pravara'),
                      _item('Madhyama'),
                      _item('Avara'),
                    ],
                  ),
                ),
              ],
            ),
            FormDropdownField<String>(
              label: 'Vaya (Age Group)',
              hint: 'Select Vaya',
              value: _vaya,
              onChanged: (v) => setState(() => _vaya = v),
              items: [
                _item('Bala (Child 0–16)'),
                _item('Madhyama (Adult 16–60)'),
                _item('Vriddha (Old 60+)'),
              ],
            ),
            FormDropdownField<String>(
              label: 'Jihwa (Tongue)',
              hint: 'Select Jihwa condition',
              value: _jihwa,
              onChanged: (v) => setState(() => _jihwa = v),
              items: [
                _item('Clean'),
                _item('Coated'),
                _item('Trembling'),
                _item('Dry'),
                _item('Moist'),
              ],
            ),
            FormDropdownField<String>(
              label: 'Desha (Habitat)',
              hint: 'Select Desha',
              value: _desha,
              onChanged: (v) => setState(() => _desha = v),
              items: [
                _item('Anupa (Marshy)'),
                _item('Jangala (Dry/Desert)'),
                _item('Sadharana (Normal)'),
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