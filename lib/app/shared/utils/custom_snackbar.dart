import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';

class CustomSnackBar {
  static void showSuccess(String message, {String? title}) => _show(
        title: title ?? 'Success',
        message: message,
        accent: AppColors.successGreen,
        icon: Icons.check_circle_rounded,
        visible: const Duration(seconds: 3),
      );

  static void showError(String message, {String? title}) => _show(
        title: title ?? 'Error',
        message: message,
        accent: AppColors.errorRed,
        icon: Icons.error_rounded,
        visible: const Duration(seconds: 4),
      );

  static void showInfo(String message, {String? title}) => _show(
        title: title ?? 'Info',
        message: message,
        accent: AppColors.primaryGreen,
        icon: Icons.info_rounded,
        visible: const Duration(seconds: 3),
      );

  static void showWarning(String message, {String? title}) => _show(
        title: title ?? 'Warning',
        message: message,
        accent: AppColors.warningOrange,
        icon: Icons.warning_amber_rounded,
        visible: const Duration(seconds: 3),
      );

  static void _show({
    required String title,
    required String message,
    required Color accent,
    required IconData icon,
    required Duration visible,
  }) {
    final context = Get.context;
    if (context == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: _SnackBarCard(
          title: title,
          message: message,
          icon: icon,
          accent: accent,
          visible: visible,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        // Long safety net — the card dismisses itself well before this fires.
        duration: visible + const Duration(seconds: 5),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}

class _SnackBarCard extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color accent;
  final Duration visible;

  const _SnackBarCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
    required this.visible,
  });

  @override
  State<_SnackBarCard> createState() => _SnackBarCardState();
}

class _SnackBarCardState extends State<_SnackBarCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _ctrl.forward();
    _timer = Timer(widget.visible, _dismiss);
  }

  void _dismiss() {
    if (_leaving || !mounted) return;
    _leaving = true;
    _ctrl.reverse().whenComplete(() {
      if (mounted) ScaffoldMessenger.of(context).removeCurrentSnackBar();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _CardBody(
          title: widget.title,
          message: widget.message,
          icon: widget.icon,
          accent: widget.accent,
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color accent;

  const _CardBody({
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDarkGreen.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status accent strip
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Row(
                  children: [
                    // Tinted icon chip
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textDarkGreen,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            message,
                            style: const TextStyle(
                              color: AppColors.darkGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
