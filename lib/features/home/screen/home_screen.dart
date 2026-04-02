import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bastikarma/features/home/controller/home_controller.dart';
import '../../../app/core/theme/app_theme.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header + overlapping stat cards ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                _DashboardHeader(controller: controller),
                Positioned(
                  top: 90,
                  left: 16,
                  right: 16,
                  child: Obx(
                        () => Row(
                      children: controller.stats
                          .map(
                            (stat) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            child: _StatCard(stat: stat),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),

            // ── Space to compensate for overlapping cards ──
            const SizedBox(height: 100),

            // ── Quick Actions ──
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDarkGreen,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _QuickActionsGrid(),
            ),

            // ── Reminders ──
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Reminders',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDarkGreen,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
                  () => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: controller.reminders
                      .map(
                        (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReminderCard(reminder: r),
                    ),
                  )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final HomeController controller;
  const _DashboardHeader({required this.controller});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _formattedDate {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

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
      // Extra bottom padding so the curved edge shows behind the cards
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 72),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                    () => Text(
                  '$_greeting, ${controller.doctorName.value}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formattedDate,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final DashboardStat stat;
  const _StatCard({required this.stat});

  IconData get _icon {
    switch (stat.iconType) {
      case 'patients':
        return Icons.people_outline;
      case 'treatments':
        return Icons.monitor_heart_outlined;
      // case 'doses':
      //   return Icons.notifications_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color get _iconBg {
    switch (stat.iconType) {
      case 'patients':
        return AppColors.primaryGreen.withValues(alpha: 0.12);
      case 'treatments':
        return AppColors.primaryGreen.withValues(alpha: 0.12);
      // case 'doses':
      //   return const Color(0xFFE8EAF6);
      default:
        return AppColors.lightGrey;
    }
  }

  Color get _iconColor {
    switch (stat.iconType) {
      case 'doses':
        return const Color(0xFF5C6BC0);
      default:
        return AppColors.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tinted circular icon background — matches Figma
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            '${stat.value}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDarkGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.darkGrey,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const List<_QuickActionData> _actions = [
    _QuickActionData(
      title: 'Add Patient',
      subtitle: 'New CRF',
      icon: Icons.add,
      iconBg: AppColors.primaryGreen,
      iconColor: AppColors.white,
    ),
    _QuickActionData(
      title: 'Patient List',
      subtitle: 'View all',
      icon: Icons.format_list_bulleted,
      iconBg: Color(0xFFE8F5E9),
      iconColor: AppColors.primaryGreen,
    ),
    _QuickActionData(
      title: 'Dose Calculator',
      subtitle: 'Calculate',
      icon: Icons.calculate,
      iconBg: AppColors.textDarkGreen,
      iconColor: AppColors.white,
    ),
    _QuickActionData(
      title: 'Treatment Guide',
      subtitle: 'Resources',
      icon: Icons.menu_book_outlined,
      iconBg: Color(0xFF757575),
      iconColor: AppColors.white,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.6,
      ),
      itemCount: _actions.length,
      itemBuilder: (_, i) => _QuickActionCard(data: _actions[i]),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;
  const _QuickActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        //wire to routes e.g. Get.toNamed(AppRoutes.addPatient)
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: data.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDarkGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              reminder.iconType == 'bell'
                  ? Icons.notifications_outlined
                  : Icons.monitor_heart_outlined,
              color: AppColors.primaryGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDarkGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reminder.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: reminder.isUrgent
                  ? AppColors.errorRed.withValues(alpha: 0.12)
                  : AppColors.successGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              reminder.badge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: reminder.isUrgent
                    ? AppColors.errorRed
                    : AppColors.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}