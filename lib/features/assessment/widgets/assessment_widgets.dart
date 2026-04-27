import 'package:flutter/material.dart';

import '../../../app/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Assessment Text Styles  (common across all assessment screens)
// ─────────────────────────────────────────────────────────────────────────────

class AssessmentTextStyles {
  AssessmentTextStyles._();

  static const sectionTitle = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  static const questionText = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const optionText = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const chipLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const hintText = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const resultLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGrey,
  );

  static const resultValue = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textDarkGreen,
  );

  static const bannerText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const noteText = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    height: 1.4,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Section card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class AssessmentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const AssessmentCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: AssessmentTextStyles.sectionTitle),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yes / No chip row
// ─────────────────────────────────────────────────────────────────────────────

class YesNoChipRow extends StatelessWidget {
  final String question;
  final bool? value;      // null = unanswered
  final ValueChanged<bool> onChanged;

  const YesNoChipRow({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(question, style: AssessmentTextStyles.questionText),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Chip(
                label: 'Yes',
                isSelected: value == true,
                activeColor: AppColors.errorRed,
                onTap: () => onChanged(true),
              ),
              const SizedBox(width: 6),
              _Chip(
                label: 'No',
                isSelected: value == false,
                activeColor: AppColors.successGreen,
                onTap: () => onChanged(false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AssessmentTextStyles.chipLabel.copyWith(
            color: isSelected ? activeColor : AppColors.darkGrey,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result banner (eligible / contraindicated / result category)
// ─────────────────────────────────────────────────────────────────────────────

enum BannerType { success, danger, warning, info }

class ResultBanner extends StatelessWidget {
  final String message;
  final BannerType type;
  final IconData? icon;

  const ResultBanner({
    super.key,
    required this.message,
    required this.type,
    this.icon,
  });

  Color get _bg => switch (type) {
    BannerType.success => const Color(0xFFE8F5E9),
    BannerType.danger  => const Color(0xFFFFEBEE),
    BannerType.warning => const Color(0xFFFFF8E1),
    BannerType.info    => const Color(0xFFE3F2FD),
  };

  Color get _fg => switch (type) {
    BannerType.success => AppColors.successGreen,
    BannerType.danger  => AppColors.errorRed,
    BannerType.warning => const Color(0xFFF9A825),
    BannerType.info    => const Color(0xFF1565C0),
  };

  IconData get _icon => icon ?? switch (type) {
    BannerType.success => Icons.check_circle_outline_rounded,
    BannerType.danger  => Icons.cancel_outlined,
    BannerType.warning => Icons.warning_amber_rounded,
    BannerType.info    => Icons.info_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 18, color: _fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AssessmentTextStyles.bannerText.copyWith(color: _fg),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selectable option row (single select radio style, no radio widget shown)
// ─────────────────────────────────────────────────────────────────────────────

class SelectableOptionRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableOptionRow({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.08)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: isSelected ? AppColors.primaryGreen : AppColors.darkGrey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AssessmentTextStyles.optionText.copyWith(
                  color: isSelected
                      ? AppColors.textDarkGreen
                      : AppColors.darkGrey,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checkable symptom row (multi-select)
// ─────────────────────────────────────────────────────────────────────────────

class CheckableSymptomRow extends StatelessWidget {
  final String label;
  final bool isChecked;
  final VoidCallback onTap;

  const CheckableSymptomRow({
    super.key,
    required this.label,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isChecked
              ? AppColors.primaryGreen.withValues(alpha: 0.08)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked ? AppColors.primaryGreen : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isChecked
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 20,
              color: isChecked ? AppColors.primaryGreen : AppColors.darkGrey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AssessmentTextStyles.optionText.copyWith(
                  color: isChecked ? AppColors.textDarkGreen : AppColors.darkGrey,
                  fontWeight: isChecked ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Divider with label
// ─────────────────────────────────────────────────────────────────────────────

class LabeledDivider extends StatelessWidget {
  final String label;
  const LabeledDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFDDD8D0), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: AssessmentTextStyles.hintText),
          ),
          const Expanded(child: Divider(color: Color(0xFFDDD8D0), thickness: 1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assessment page header (shared AppBar-like header)
// ─────────────────────────────────────────────────────────────────────────────

class AssessmentPageHeader extends StatelessWidget {
  final String phase;       // e.g. "Purvakarma"
  final String subTitle;    // e.g. "Step 2 of 5"
  final VoidCallback onBack;

  const AssessmentPageHeader({
    super.key,
    required this.phase,
    required this.subTitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, Color(0xFF3D7A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            phase,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subTitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom action button (shared)
// ─────────────────────────────────────────────────────────────────────────────

class AssessmentBottomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AssessmentBottomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed == null
                ? AppColors.darkGrey.withValues(alpha: 0.3)
                : AppColors.primaryGreen,
            foregroundColor: Colors.white,
            elevation: onPressed == null ? 0 : 4,
            shadowColor: AppColors.primaryGreen.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: isLoading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info prescription box (for Deepan Pachana etc.)
// ─────────────────────────────────────────────────────────────────────────────

class PrescriptionBox extends StatelessWidget {
  final String title;
  final String content;

  const PrescriptionBox({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_pharmacy_outlined,
                  size: 16, color: AppColors.primaryGreen),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: AssessmentTextStyles.optionText),
        ],
      ),
    );
  }
}