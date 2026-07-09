import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/home/controller/home_controller.dart';
import '../../../features/calculator/screen/calculators_screen.dart';
import '../../../features/home/screen/home_screen.dart';
import '../../../features/patients/screen/patients_screen.dart';
import '../../../features/profile/screen/profile_screen.dart';
import '../../../features/resource/screen/resources_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    final List<Widget> screens = const [
      DashboardTab(),
      PatientsScreen(),
      CalculatorsScreen(),
      ResourcesScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: screens,
      )),
      bottomNavigationBar: _BottomNavBar(controller: controller),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final HomeController controller;

  const _BottomNavBar({required this.controller});

  static const List<_NavItemData> _items = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Dashboard',
    ),
    _NavItemData(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Patients',
    ),
    _NavItemData(
      icon: Icons.calculate_outlined,
      activeIcon: Icons.calculate,
      label: 'Calculators',
    ),
    _NavItemData(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: 'Resources',
    ),
    _NavItemData(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _items.length,
                (i) => _NavItem(
                  data: _items[i],
                  isActive: controller.currentIndex.value == i,
                  onTap: () => controller.changeTab(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? data.activeIcon : data.icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.primaryGreen : AppColors.darkGrey,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: AppTextStyles.navLabel.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primaryGreen : AppColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
