import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/routes/app_pages.dart';
import '../../../app/core/theme/app_text_styles.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/data/models/patient/patient_model.dart';
import '../../../app/shared/utils/app_navigation.dart';
import '../../../app/shared/widgets/physician_yukti_banner.dart';
import '../../patients/screen/patient_detail_screen.dart';
import '../controller/home_controller.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return SafeArea(
      child: Column(
        children: [
          // ── Pinned Top Header (Green Container with overlapping stat cards) ──
          _DashboardHeader(controller: controller),

          // ── Scrollable Body with Pull-to-Refresh ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshDashboard,
              color: AppColors.primaryGreen,
              backgroundColor: AppColors.white,
              displacement: 32.0,
              edgeOffset: 0.0,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(top: 8, bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Quick Actions ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Quick Actions',
                        style: AppTextStyles.sectionHeading,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _QuickActionsGrid(controller: controller),
                    ),

                    const SizedBox(height: 22),

                    // ── 2. Recent Patients ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _RecentPatientsSection(controller: controller),
                    ),

                    const SizedBox(height: 22),

                    // ── 3. Ayurvedic Wisdom Card ──
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _ClinicalWisdomCard(),
                    ),
                    const SizedBox(height: 16),
                    const PhysicianYuktiBanner(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 1. Header Widget ────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final HomeController controller;

  const _DashboardHeader({required this.controller});

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final date = '${_months[now.month - 1]} ${now.day}, ${now.year}';
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 198 + topPadding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Green Background Container ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, Color(0xFF1F3D2B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, 16 + topPadding, 20, 72),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(
                          () => Text(
                            '$greeting, ${controller.doctorName.value}',
                            style: AppTextStyles.greetingText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(date, style: AppTextStyles.pageSubtitle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Doctor Avatar Pill / Profile Shortcut
                  GestureDetector(
                    onTap: () => controller.changeTab(3),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Overlapping Stat Cards ──
          Positioned(
            top: 80 + topPadding,
            left: 16,
            right: 16,
            child: Obx(
              () => Row(
                children: controller.stats
                    .map(
                      (stat) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
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
    );
  }
}

// ── 2. Stat Card Widget ─────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final DashboardStat stat;

  const _StatCard({required this.stat});

  IconData get _icon {
    switch (stat.iconType) {
      case 'patients':
        return Icons.people_outline;
      case 'opd':
        return Icons.medical_services_outlined;
      case 'ipd':
        return Icons.hotel_outlined;
      case 'treatments':
        return Icons.monitor_heart_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color get _iconBg {
    return AppColors.primaryGreen.withValues(alpha: 0.1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: _iconBg, shape: BoxShape.circle),
            child: Icon(_icon, color: AppColors.primaryGreen, size: 18),
          ),
          const SizedBox(height: 8),
          Text(stat.value.toString(), style: AppTextStyles.statValue),
          const SizedBox(height: 2),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.statLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── 3. Quick Actions ────────────────────────────────────────────────────────
class _QuickActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback? onTap;

  const _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.onTap,
  });
}

class _QuickActionsGrid extends StatelessWidget {
  final HomeController controller;

  const _QuickActionsGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    final List<_QuickActionData> actions = [
      _QuickActionData(
        title: 'Add Patient',
        subtitle: 'New CRF Entry',
        icon: Icons.person_add_alt_1_outlined,
        iconBg: AppColors.primaryGreen,
        iconColor: AppColors.white,
        onTap: () => AppNavigation.toNamed(AppRoutes.addPatient),
      ),
      _QuickActionData(
        title: 'Patient Records',
        subtitle: 'Search & Manage',
        icon: Icons.format_list_bulleted_rounded,
        iconBg: const Color(0xFFE8F5E9),
        iconColor: AppColors.primaryGreen,
        onTap: () => controller.changeTab(1),
      ),
      _QuickActionData(
        title: 'Clinical Docs',
        subtitle: 'SOPs & Protocols',
        icon: Icons.menu_book_outlined,
        iconBg: const Color(0xFFE0F2F1),
        iconColor: const Color(0xFF00695C),
        onTap: () => controller.changeTab(2),
      ),
      _QuickActionData(
        title: 'Doctor Profile',
        subtitle: 'Clinic & Settings',
        icon: Icons.account_circle_outlined,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFE65100),
        onTap: () => controller.changeTab(3),
      ),
    ];

    return Column(
      children: actions
          .map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _QuickActionCard(data: action),
            ),
          )
          .toList(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: AppTextStyles.actionCardTitle.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: AppTextStyles.actionCardSubtitle.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.darkGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 4. Recent Patients Section ──────────────────────────────────────────────
class _RecentPatientsSection extends StatelessWidget {
  final HomeController controller;

  const _RecentPatientsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Patients',
                style: AppTextStyles.sectionHeading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => controller.changeTab(1),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.primaryGreen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Obx(() {
          final patients = controller.recentPatients;
          if (patients.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 40,
                    color: AppColors.primaryGreen.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No Patients Registered Yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap "Add Patient" above to register your first clinical record.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: patients
                .map((patient) => _RecentPatientTile(patient: patient))
                .toList(),
          );
        }),
      ],
    );
  }
}

class _RecentPatientTile extends StatelessWidget {
  final PatientModel patient;

  const _RecentPatientTile({required this.patient});

  @override
  Widget build(BuildContext context) {
    final isIpd = patient.admissionType.toUpperCase().contains('IPD');
    final initial = patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.to(() => PatientDetailScreen(patient: patient)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              patient.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDarkGreen,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isIpd
                                  ? const Color(0xFFFFF3E0)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: isIpd
                                    ? const Color(0xFFFFB74D)
                                    : const Color(0xFFA5D6A7),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              patient.admissionType.isNotEmpty ? patient.admissionType : 'OPD',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isIpd
                                    ? const Color(0xFFE65100)
                                    : AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${patient.age} yrs • ${patient.sex}${patient.diagnosis.isNotEmpty ? " • ${patient.diagnosis}" : ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.darkGrey,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 5. Clinical Wisdom Card ─────────────────────────────────────────────────
class _ClinicalWisdomCard extends StatelessWidget {
  const _ClinicalWisdomCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2DDD5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFE9DC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              size: 20,
              color: Color(0xFF6D5D4B),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"बस्तिः वाते च पित्ते च कफे च... सर्वकर्म प्रधानम्"',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A3E31),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Basti is considered Ardha Chikitsa (half of all treatments) in Ayurveda, eradicating vitiated Vata from its primary seat in the Pakwashaya.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6D5D4B),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '— Acharya Charaka, Siddhi Sthana',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8D7B68),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
