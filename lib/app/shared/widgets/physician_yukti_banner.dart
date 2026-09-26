import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Clinical disclaimer banner displayed at the bottom of non-auth screens.
class PhysicianYuktiBanner extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const PhysicianYuktiBanner({
    super.key,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: backgroundColor ?? Colors.transparent,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text(
        '“The final selection of Basti should be decided by the physician according to Yukti and individual patient assessment.”',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.errorRed,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
