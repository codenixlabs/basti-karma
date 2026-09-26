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
              label: 'Pathological & Radiological Findings',
              hint: 'CBC, LFT, KFT, X-Ray, USG, MRI findings...',
              controller: ctrl.pathologicalRadiologicalCtrl,
              focusNode: ctrl.pathologicalRadiologicalFocus,
              maxLines: 4,
              textInputAction: TextInputAction.done,
            ),
            const FieldLabel(label: 'Investigation Document / Photo'),
            Obx(() {
              final doc = ctrl.selectedDocument.value;
              final fileName = ctrl.selectedDocumentName.value ?? 'document';
              if (doc == null) {
                return GestureDetector(
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
                          'Tap to upload document or photo',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Camera, gallery or PDF • Max 5 MB',
                          style: TextStyle(color: AppColors.darkGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final isPdf = fileName.toLowerCase().endsWith('.pdf');

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: isPdf
                          ? Container(
                              width: 56,
                              height: 56,
                              color: const Color(0xFFE8F5E9),
                              child: const Icon(
                                Icons.picture_as_pdf_rounded,
                                color: AppColors.primaryGreen,
                                size: 30,
                              ),
                            )
                          : Image.file(
                              doc,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 56,
                                height: 56,
                                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDarkGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPdf
                                ? 'PDF Document • Ready to upload'
                                : 'Image • Ready to upload',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      color: AppColors.primaryGreen,
                      tooltip: 'Change Document',
                      onPressed: ctrl.showImageSourceSheet,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.errorRed,
                      tooltip: 'Remove',
                      onPressed: ctrl.removeDocument,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
