import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';

import '../../../app/core/theme/app_text_styles.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/data/models/patient/patient_model.dart';
import '../../../app/data/repositories/api_patient_repository.dart';
import '../../../app/data/repositories/patient_repository.dart';
import '../../../app/shared/utils/custom_snackbar.dart';

enum _DownloadPhase { generating, success, error }

/// An engaging, high-fidelity dialog displayed while the backend generates and
/// downloads the patient's comprehensive PDF report.
///
/// Features:
/// - Real-time elapsed duration counter.
/// - Dynamic rotating clinical milestones to keep the doctor engaged.
/// - Seamless transition to success with immediate "Open PDF" action.
/// - Graceful error handling with retry capability.
class PatientPdfReportDialog extends StatefulWidget {
  final PatientModel patient;

  const PatientPdfReportDialog({super.key, required this.patient});

  /// Opens the dialog, kicks off the download, and returns the downloaded [File] on success.
  static Future<File?> show(BuildContext context, PatientModel patient) {
    return showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PatientPdfReportDialog(patient: patient),
    );
  }

  @override
  State<PatientPdfReportDialog> createState() => _PatientPdfReportDialogState();
}

class _PatientPdfReportDialogState extends State<PatientPdfReportDialog>
    with SingleTickerProviderStateMixin {
  _DownloadPhase _phase = _DownloadPhase.generating;
  int _currentStepIndex = 0;
  Timer? _stepTimer;
  File? _downloadedFile;
  String _errorMessage = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const List<Map<String, dynamic>> _steps = [
    {
      'title': 'Compiling Demographics & Hospital Records',
      'detail':
          'Aggregating patient identity, admission type, and contact records...',
      'icon': Icons.badge_outlined,
    },
    {
      'title': 'Synthesizing Rogi & Doshik Pariksha',
      'detail':
          'Formatting Prakriti, Sarataha, Sanhanan, Vaya, Desha, and Agni...',
      'icon': Icons.spa_outlined,
    },
    {
      'title': 'Compiling Treatment & Daily Karma Logs',
      'detail':
          'Collecting Poorva Karma, daily Pradhana Basti sessions, and retention times...',
      'icon': Icons.medical_services_outlined,
    },
    {
      'title': 'Evaluating Paschata Karma & Regimen',
      'detail':
          'Incorporating Parihara Kala rules, dietary instructions, and observations...',
      'icon': Icons.assignment_turned_in_outlined,
    },
    {
      'title': 'Rendering Vector Clinical Dossier',
      'detail':
          'Formatting official headers, charts, and institutional verification...',
      'icon': Icons.picture_as_pdf_outlined,
    },
    {
      'title': 'Downloading PDF to Device Storage',
      'detail': 'Saving file securely to local device documents...',
      'icon': Icons.download_done_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startDownload();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimers() {
    _currentStepIndex = 0;
    _stepTimer?.cancel();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 3200), (timer) {
      if (mounted && _phase == _DownloadPhase.generating) {
        setState(() {
          _currentStepIndex = (_currentStepIndex + 1) % _steps.length;
        });
      }
    });
  }

  Future<void> _startDownload() async {
    setState(() {
      _phase = _DownloadPhase.generating;
      _errorMessage = '';
    });
    _startTimers();

    try {
      final repo = Get.isRegistered<PatientRepository>()
          ? Get.find<PatientRepository>()
          : ApiPatientRepository();

      final defaultName =
          '${widget.patient.name.replaceAll(RegExp(r'\s+'), '_')}_Report.pdf';

      final file = await repo.downloadPatientPdfReport(
        widget.patient.id,
        defaultFileName: defaultName,
        timeout: const Duration(minutes: 2),
      );

      _stepTimer?.cancel();

      if (!mounted) return;
      setState(() {
        _phase = _DownloadPhase.success;
        _downloadedFile = file;
      });

      // Automatically launch PDF viewer on device
      try {
        await OpenFilex.open(file.path);
      } catch (_) {}
    } catch (e) {
      _stepTimer?.cancel();

      if (!mounted) return;
      setState(() {
        _phase = _DownloadPhase.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openFile() async {
    final file = _downloadedFile;
    if (file == null) return;
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      CustomSnackBar.showInfo(
        'File saved at: ${file.path}',
        title: 'PDF File Saved',
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: switch (_phase) {
            _DownloadPhase.generating => _buildGeneratingContent(),
            _DownloadPhase.success => _buildSuccessContent(),
            _DownloadPhase.error => _buildErrorContent(),
          },
        ),
      ),
    );
  }

  // ── Generating State (Rich & Engaging) ──────────────────────────────────────

  Widget _buildGeneratingContent() {
    final step = _steps[_currentStepIndex];

    return Column(
      key: const ValueKey('generating'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing animated PDF document icon with surrounding glow ring
        Stack(
          alignment: Alignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                ),
              ),
            ),
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Title and Patient name
        Text(
          'Generating Medical Report',
          style: AppTextStyles.sectionHeading.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDarkGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          widget.patient.name,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Animated Smooth Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        const SizedBox(height: 16),

        // Rotating Step Card with smooth animated transition
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey<int>(_currentStepIndex),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  step['icon'] as IconData,
                  size: 20,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'] as String,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDarkGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step['detail'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.darkGrey,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Informational reassurance
        const Text(
          'Please hold on while the server renders all daily karma logs into vector PDF format.',
          style: TextStyle(fontSize: 11, color: AppColors.darkGrey, height: 1.3),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Dismiss / Background option
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.darkGrey,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            'Keep Working in Background',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ── Success State ──────────────────────────────────────────────────────────

  Widget _buildSuccessContent() {
    final file = _downloadedFile;
    final fileName = file != null
        ? file.path.split(RegExp(r'[/\\]')).last
        : 'Patient_Report.pdf';
    final fileSize = file != null ? _formatFileSize(file.lengthSync()) : '';

    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success checkmark badge
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE8F5E9),
            border: Border.all(color: const Color(0xFF81C784), width: 1.5),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF2E7D32),
            size: 42,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Report Ready!',
          style: AppTextStyles.sectionHeading.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDarkGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Complete clinical evaluation and daily karma assessments compiled successfully.',
          style: TextStyle(fontSize: 12, color: AppColors.darkGrey, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // File Details Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDarkGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (fileSize.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Size: $fileSize • Saved to Device Storage',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(file),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDarkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _openFile,
                icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                label: const Text('Open PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────

  Widget _buildErrorContent() {
    return Column(
      key: const ValueKey('error'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFEBEE),
            border: Border.all(color: const Color(0xFFEF9A9A), width: 1.5),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFC62828),
            size: 38,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Generation Unsuccessful',
          style: AppTextStyles.sectionHeading.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFC62828),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFCDD2)),
          ),
          child: Text(
            _errorMessage.isNotEmpty
                ? _errorMessage
                : 'Failed to generate PDF. The server is still compiling records or an assessment log is incomplete.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF424242),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkGrey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Dismiss'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startDownload,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
