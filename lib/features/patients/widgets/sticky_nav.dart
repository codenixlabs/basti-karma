import 'package:flutter/material.dart';

import '../../../app/core/theme/app_theme.dart';
import '../../../app/core/theme/app_text_styles.dart';

class StickyNav extends StatelessWidget {
  final bool showPrev;
  final bool isLastStep;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  const StickyNav({
    super.key,
    this.showPrev = true,
    this.isLastStep = false,
    this.onPrev,
    this.onNext,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showPrev) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onPrev,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  foregroundColor: AppColors.primaryGreen,
                ),
                child: const Text(
                  'Previous',
                  style: AppTextStyles.button,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: showPrev ? 1 : 2,
            child: ElevatedButton(
              onPressed: isLastStep ? onSubmit : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 3,
                shadowColor: AppColors.primaryGreen.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isLastStep ? 'Submit' : 'Next',
                style: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
