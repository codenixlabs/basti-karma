import 'package:flutter/material.dart';
import '../widgets/form_widget.dart';
import '../../../app/core/theme/app_theme.dart';

class Step8Investigations extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const Step8Investigations({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrev,
  });

  @override
  State<Step8Investigations> createState() => _Step8InvestigationsState();
}

class _Step8InvestigationsState extends State<Step8Investigations> {
  late final TextEditingController _pathologicalCtrl;
  late final TextEditingController _radiologicalCtrl;
  List<String> _uploadedPhotos = [];

  @override
  void initState() {
    super.initState();
    _pathologicalCtrl = TextEditingController(
      text: widget.data['pathological'] ?? '',
    );
    _radiologicalCtrl = TextEditingController(
      text: widget.data['radiological'] ?? '',
    );
    _uploadedPhotos = List<String>.from(widget.data['photos'] ?? []);
  }

  @override
  void dispose() {
    _pathologicalCtrl.dispose();
    _radiologicalCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.data['pathological'] = _pathologicalCtrl.text;
    widget.data['radiological'] = _radiologicalCtrl.text;
    widget.data['photos'] = _uploadedPhotos;
  }

  // Simulated photo upload — in real app use image_picker
  void _simulateUpload() {
    setState(() {
      _uploadedPhotos.add('photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSectionCard(
          title: 'Investigations',
          icon: Icons.biotech_outlined,
          children: [
            FormTextField(
              label: 'Pathological',
              hint: 'CBC, LFT, KFT, Sugar, etc.',
              controller: _pathologicalCtrl,
              maxLines: 4,
            ),
            FormTextField(
              label: 'Radiological',
              hint: 'X-Ray, USG, MRI findings...',
              controller: _radiologicalCtrl,
              maxLines: 4,
            ),
            // Photo Upload
            const FieldLabel(label: 'Upload Photos'),
            GestureDetector(
              onTap: _simulateUpload,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: AppColors.primaryGreen,
                      size: 32,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap to upload from gallery',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Max size: 5 MB per image',
                      style: TextStyle(
                        color: AppColors.darkGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_uploadedPhotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _uploadedPhotos
                    .map(
                      (photo) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                        AppColors.primaryGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          size: 14,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          photo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(
                                () => _uploadedPhotos.remove(photo),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.errorRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .toList(),
              ),
            ],
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