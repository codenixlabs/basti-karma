import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/core/theme/app_text_styles.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/data/models/patient/patient_model.dart';
import '../../../app/data/services/api_service.dart';
import '../../../app/shared/utils/custom_snackbar.dart';
import '../controller/patient_controller.dart';

class PatientDocumentsSheet extends StatefulWidget {
  final PatientModel patient;

  const PatientDocumentsSheet({super.key, required this.patient});

  static String resolvePhotoUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final apiService = Get.isRegistered<ApiService>() ? Get.find<ApiService>() : null;
    final base = apiService?.baseUrl ?? ApiService.defaultBaseUrl;
    final uri = Uri.tryParse(base);
    final host = uri != null ? '${uri.scheme}://${uri.host}' : 'https://bhastikarma-app-backend.onrender.com';
    return url.startsWith('/') ? '$host$url' : '$host/$url';
  }

  static bool isPdfUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final cleanUrl = url.split('?').first.split('#').first.toLowerCase();
    return cleanUrl.endsWith('.pdf') || (Uri.tryParse(url)?.path.toLowerCase().endsWith('.pdf') ?? false);
  }

  static String getDocumentFileName(String? url) {
    if (url == null || url.trim().isEmpty) return 'Document.pdf';
    final rawName = Uri.tryParse(url)?.pathSegments.lastOrNull ?? url.split('/').last.split('?').first;
    if (rawName.isEmpty) return 'Document.pdf';
    final clean = rawName.replaceAll(RegExp(r'^\d+[-_]'), '');
    return clean.isNotEmpty ? clean : rawName;
  }

  static Future<void> openDocument(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null) {
      CustomSnackBar.showError('Invalid document URL.');
      return;
    }
    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
      if (!launched) {
        CustomSnackBar.showError('Could not open document. Please install a PDF viewer.');
      }
    } catch (e) {
      try {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback) {
          CustomSnackBar.showError('Failed to open document: $e');
        }
      } catch (_) {
        CustomSnackBar.showError('Failed to open document: $e');
      }
    }
  }

  @override
  State<PatientDocumentsSheet> createState() => _PatientDocumentsSheetState();
}

class _PatientDocumentsSheetState extends State<PatientDocumentsSheet> {
  late PatientModel _patient;
  bool _isUploading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        CustomSnackBar.showWarning(
          'Camera access is required to take photos.',
          title: 'Permission Denied',
        );
        return;
      }
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );

      if (picked == null) return;

      final file = File(picked.path);
      final size = await file.length();
      if (size > 5 * 1024 * 1024) {
        CustomSnackBar.showError(
          'File size exceeds the 5 MB limit. Please select a smaller file.',
        );
        return;
      }

      setState(() => _isUploading = true);

      if (Get.isRegistered<PatientController>()) {
        final pCtrl = Get.find<PatientController>();
        await pCtrl.uploadPatientPhoto(_patient.id, file);
        // Refresh local patient reference from controller (updated by uploadPatientPhoto)
        final updated = pCtrl.currentPatient.value;
        if (updated != null && mounted) {
          setState(() {
            _patient = updated;
          });
        }
      }

      CustomSnackBar.showSuccess('Document uploaded successfully');
    } catch (e) {
      CustomSnackBar.showError('Failed to upload document: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickPdfAndUpload() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (files.isEmpty) return;
      final platformFile = files.first;
      final path = platformFile.path;
      if (path == null) return;
      final file = File(path);
      final size = await file.length();
      if (size > 5 * 1024 * 1024) {
        CustomSnackBar.showError(
          'File size exceeds the 5 MB limit. Please select a smaller PDF.',
        );
        return;
      }

      setState(() => _isUploading = true);

      if (Get.isRegistered<PatientController>()) {
        final pCtrl = Get.find<PatientController>();
        await pCtrl.uploadPatientPhoto(_patient.id, file);
        // Refresh local patient reference from controller (updated by uploadPatientPhoto)
        final updated = pCtrl.currentPatient.value;
        if (updated != null && mounted) {
          setState(() {
            _patient = updated;
          });
        }
      }

      CustomSnackBar.showSuccess('Document uploaded successfully');
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        CustomSnackBar.showError(
          'Please completely stop and restart the app to enable PDF picking.',
        );
      } else {
        CustomSnackBar.showError('Failed to upload document: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourcePicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Select Document Source',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Supported: Camera, Gallery, or PDF (Max 5 MB)',
              style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SourceTile(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () {
                      Get.back();
                      _pickAndUpload(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceTile(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: () {
                      Get.back();
                      _pickAndUpload(ImageSource.gallery);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceTile(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF File',
                    onTap: () {
                      Get.back();
                      _pickPdfAndUpload();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    if (PatientDocumentsSheet.isPdfUrl(imageUrl)) {
      PatientDocumentsSheet.openDocument(imageUrl);
      return;
    }
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 300,
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined, size: 48, color: AppColors.errorRed),
                        SizedBox(height: 12),
                        Text('Unable to load document image'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _patient.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;
    final resolvedUrl = hasPhoto ? PatientDocumentsSheet.resolvePhotoUrl(photoUrl) : null;
    final isPdf = hasPhoto && PatientDocumentsSheet.isPdfUrl(photoUrl);

    final findings = _patient.pathologicalRadiological;
    final hasFindings = findings != null && findings.trim().isNotEmpty;

    final treatment = _patient.treatmentGiven;
    final hasTreatment = treatment != null && treatment.trim().isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _patient.name,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_patient.age} yrs • ${_patient.sex} • Diagnosis: ${_patient.diagnosis.isNotEmpty ? _patient.diagnosis : "General"}',
                        style: AppTextStyles.captionText,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.darkGrey),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Attached Photo / Document
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PATIENT DOCUMENT / PHOTO',
                        style: AppTextStyles.sectionHeading.copyWith(
                          fontSize: 12,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      if (_isUploading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (hasPhoto && resolvedUrl != null) ...[
                    if (isPdf)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFF4F9F5)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryGreen.withValues(alpha: 0.2),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Top Tag / Status Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F7F2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'CLINICAL DOCUMENT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.6,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'PDF',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Document Sheet Visual Graphic
                              GestureDetector(
                                onTap: () => PatientDocumentsSheet.openDocument(resolvedUrl),
                                child: Container(
                                  width: 84,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.primaryGreen.withValues(alpha: 0.2),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Top banner on sheet
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Container(
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryGreen,
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFF0F7F2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.picture_as_pdf_rounded,
                                                color: AppColors.primaryGreen,
                                                size: 30,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            // Skeleton lines for paper look
                                            Container(
                                              width: 36,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Container(
                                              width: 24,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Document Name
                              Text(
                                PatientDocumentsSheet.getDocumentFileName(photoUrl),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C3E50),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap button below to view in full resolution',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkGrey,
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Main Action: Open PDF
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: () => PatientDocumentsSheet.openDocument(resolvedUrl),
                                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                  label: const Text(
                                    'View PDF Document',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    shadowColor: AppColors.primaryGreen.withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => _showFullScreenImage(resolvedUrl),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryGreen.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  resolvedUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryGreen,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.description_outlined,
                                          size: 48,
                                          color: AppColors.primaryGreen,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Document Attached',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDarkGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'View',
                                        style: TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _showImageSourcePicker,
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: const Text('Replace Document / Photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: const BorderSide(color: AppColors.primaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.darkGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            size: 40,
                            color: AppColors.darkGrey,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No document or photo uploaded yet.',
                            style: AppTextStyles.captionText,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _showImageSourcePicker,
                            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                            label: const Text('Upload Document / Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 2. Pathological & Radiological Findings
                  Text(
                    'PATHOLOGICAL & RADIOLOGICAL FINDINGS',
                    style: AppTextStyles.sectionHeading.copyWith(
                      fontSize: 12,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hasFindings ? findings : 'No pathological or radiological findings recorded.',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasFindings ? AppColors.textDarkGreen : AppColors.darkGrey,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Treatment Given
                  Text(
                    'TREATMENT GIVEN',
                    style: AppTextStyles.sectionHeading.copyWith(
                      fontSize: 12,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hasTreatment ? treatment : 'No prior treatment recorded.',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasTreatment ? AppColors.textDarkGreen : AppColors.darkGrey,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2E7D4F).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: const Color(0xFF2E7D4F)),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2E7D4F),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
