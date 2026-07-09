import 'package:flutter/material.dart';

import '../../../app/core/theme/app_theme.dart';
import '../../../app/core/theme/app_text_styles.dart';

class PatientCard extends StatelessWidget {
  final String name;
  final int age;
  final String diagnosis;
  final bool isActive;
  final VoidCallback? onView;
  final VoidCallback? onAssess;
  final VoidCallback? onDocs;
  final VoidCallback? onDelete;

  const PatientCard({
    super.key,
    required this.name,
    required this.age,
    required this.diagnosis,
    this.isActive = true,
    this.onView,
    this.onAssess,
    this.onDocs,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + Active badge
            Row(
              children: [
                Text(
                  name,
                  style: AppTextStyles.patientName,
                ),
                const SizedBox(width: 8),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Active',
                      style: AppTextStyles.badge.copyWith(color: AppColors.successGreen),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Age: $age years',
              style: AppTextStyles.patientMeta,
            ),
            const SizedBox(height: 2),
            Text(
              'Diagnosis: $diagnosis',
              style: AppTextStyles.patientMeta,
            ),
            const SizedBox(height: 12),
            // Divider
            Divider(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              height: 1,
            ),
            const SizedBox(height: 10),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: Icons.remove_red_eye_outlined,
                  label: 'View',
                  onTap: onView,
                ),
                _ActionButton(
                  icon: Icons.assessment_outlined,
                  label: 'Assess',
                  color: Colors.green,
                  onTap: onAssess,
                ),
                _ActionButton(
                  icon: Icons.description_outlined,
                  label: 'Docs',
                  color: Colors.blueGrey,
                  onTap: onDocs,
                ),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppColors.errorRed,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = AppColors.primaryGreen,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}