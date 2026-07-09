import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';

class Step8Investigations extends StatelessWidget {
  const Step8Investigations({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddPatientController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.registerValidation(ctrl.isFemale ? 7 : 6, () => true);
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
        child: FormSectionCard(
          title: 'Investigations',
          icon: Icons.biotech_outlined,
          children: [
            FormTextField(
              label: 'Pathological',
              hint: 'CBC, LFT, KFT, Sugar, etc.',
              controller: ctrl.pathologicalCtrl,
              focusNode: ctrl.pathologicalFocus,
              nextFocusNode: ctrl.radiologicalFocus,
              maxLines: 4,
            ),
            FormTextField(
              label: 'Radiological',
              hint: 'X-Ray, USG, MRI findings...',
              controller: ctrl.radiologicalCtrl,
              focusNode: ctrl.radiologicalFocus,
              maxLines: 4,
              textInputAction: TextInputAction.done,
            ),
            const FieldLabel(label: 'Upload Photos'),
            GestureDetector(
              onTap: ctrl.showImageSourceSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
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
                      'Tap to upload — Camera or Gallery',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Max size: 5 MB per image',
                      style: TextStyle(color: AppColors.darkGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            Obx(() {
              if (ctrl.uploadedPhotos.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ctrl.uploadedPhotos.map((path) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 80,
                              height: 80,
                              color: AppColors.inputBackground,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.darkGrey,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => ctrl.removePhoto(path),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: AppColors.errorRed,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
