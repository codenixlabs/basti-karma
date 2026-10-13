import 'package:flutter/material.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/core/theme/app_text_styles.dart';
import '../../../app/data/models/patient/patient_model.dart';
import '../../../app/data/repositories/api_follow_up_repository.dart';
import '../../../app/shared/utils/custom_snackbar.dart';

class FollowUpTab extends StatefulWidget {
  final PatientModel patient;

  const FollowUpTab({super.key, required this.patient});

  @override
  State<FollowUpTab> createState() => _FollowUpTabState();
}

class _FollowUpTabState extends State<FollowUpTab> with SingleTickerProviderStateMixin {
  final _notesController = TextEditingController();
  final _repo = ApiFollowUpRepository();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _lastSavedNotes;
  String? _updatedAt;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getFollowUp(widget.patient.id);
      if (data != null && data.notes.isNotEmpty) {
        _notesController.text = data.notes;
        _lastSavedNotes = data.notes;
        _updatedAt = data.updatedAt;
      }
    } catch (e) {
      CustomSnackBar.showError('Failed to load follow-up notes: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.forward();
      }
    }
  }

  Future<void> _saveNotes() async {
    FocusScope.of(context).unfocus();
    if (_notesController.text.trim().isEmpty) {
      CustomSnackBar.showInfo('Please enter some notes before saving.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await _repo.saveFollowUp(
        widget.patient.id,
        _notesController.text.trim(),
      );
      _lastSavedNotes = updated.notes;
      _updatedAt = updated.updatedAt;
      CustomSnackBar.showSuccess('Follow-up notes saved successfully.');
    } catch (e) {
      CustomSnackBar.showError('Failed to save follow-up notes: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      // Returns e.g. "2026-10-08 12:30"
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    final hasChanges = _notesController.text.trim() != (_lastSavedNotes ?? '');

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standard Section Header
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_edu_rounded, size: 18, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'CLINICAL FOLLOW UP',
                    style: AppTextStyles.sectionHeading.copyWith(
                      fontSize: 14,
                      letterSpacing: 1.1,
                      color: AppColors.primaryGreen,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Editor Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Editor Header Ribbon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Notes Editor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDarkGreen,
                          ),
                        ),
                        const Spacer(),
                        if (_updatedAt != null) ...[
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(_updatedAt),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Text Area
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 15,
                      minLines: 8,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.transparent,
                        hintText: 'Type follow-up instructions, observations, or next visit details here...',
                        hintStyle: TextStyle(
                          color: AppColors.darkGrey.withValues(alpha: 0.4),
                          fontSize: 14,
                          height: 1.6,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textDarkGreen,
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving || !hasChanges ? null : _saveNotes,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        hasChanges ? Icons.save_rounded : Icons.check_circle_rounded,
                        size: 20,
                      ),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : hasChanges
                          ? 'Save Follow Up'
                          : 'Up to Date',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: hasChanges ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
