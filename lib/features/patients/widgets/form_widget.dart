import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/core/theme/app_theme.dart';
import '../../../app/core/theme/app_text_styles.dart';

// ─── Step Progress Bar ───────────────────────────────────────────────────────
class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $currentStep of $totalSteps',
              style: AppTextStyles.stepLabel,
            ),
            Text(
              '${((currentStep / totalSteps) * 100).round()}%',
              style: AppTextStyles.stepPercent,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: currentStep / totalSteps),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Form Header (Gradient) ──────────────────────────────────────────────────
class FormStepHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;

  const FormStepHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentStep,
    required this.totalSteps,
    this.onBack,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StepProgressBar(currentStep: currentStep, totalSteps: totalSteps),
        ],
      ),
    );
  }
}

// ─── Section Card ────────────────────────────────────────────────────────────
class FormSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const FormSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primaryGreen, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFEEEEEE), height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
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

// ─── Field Label ─────────────────────────────────────────────────────────────
class FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const FieldLabel({super.key, required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: AppColors.textDarkGreen,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.errorRed),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Text Input Field ────────────────────────────────────────────────────────
class FormTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool required;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction? textInputAction;
  final AutovalidateMode autovalidateMode;

  const FormTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.validator,
    this.suffix,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final action =
        textInputAction ??
        (nextFocusNode != null ? TextInputAction.next : TextInputAction.done);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // helperText adds ~16px
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label: label, required: required),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            cursorColor: AppColors.primaryGreen,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            textInputAction: action,
            autovalidateMode: autovalidateMode,
            validator: validator,
            style: const TextStyle(
              color: AppColors.textDarkGreen,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            onFieldSubmitted: (_) {
              if (nextFocusNode != null) {
                FocusScope.of(context).requestFocus(nextFocusNode);
              } else {
                FocusScope.of(context).unfocus();
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.darkGrey,
                fontSize: 13,
              ),
              helperText: ' ',
              helperStyle: const TextStyle(fontSize: 11, height: 0.8),
              errorStyle: const TextStyle(
                color: AppColors.errorRed,
                fontSize: 11,
                height: 0.8,
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primaryGreen,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.errorRed,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.errorRed,
                  width: 1.5,
                ),
              ),
              suffixIcon: suffix,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Radio Group ─────────────────────────────────────────────────────────────
class FormRadioGroup<T> extends StatelessWidget {
  final String label;
  final T? groupValue;
  final List<({T value, String label})> options;
  final ValueChanged<T?> onChanged;
  final bool required;

  const FormRadioGroup({
    super.key,
    required this.label,
    required this.groupValue,
    required this.options,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label: label, required: required),
          Row(
            children: options
                .map(
                  (o) => Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(o.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: groupValue == o.value
                              ? AppColors.primaryGreen
                              : AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: groupValue == o.value
                                ? AppColors.primaryGreen
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (groupValue == o.value)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 15,
                              ),
                            if (groupValue == o.value) const SizedBox(width: 4),
                            Text(
                              o.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: groupValue == o.value
                                    ? Colors.white
                                    : AppColors.textDarkGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
