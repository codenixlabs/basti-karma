import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../controller/profile_controller.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

// ── Static Legal Pages ────────────────────────────────────────────────────────

class _LegalPage extends StatelessWidget {
  final String title;
  final List<_LegalSection> sections;

  const _LegalPage({
    required this.title,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 20),
          itemBuilder: (_, i) {
            final section = sections[i];
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.heading,
                    style: const TextStyle(
                      color: AppColors.textDarkGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    section.body,
                    style: const TextStyle(
                      color: AppColors.darkGrey,
                      fontSize: 13.5,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LegalSection {
  final String heading;
  final String body;

  const _LegalSection({required this.heading, required this.body});
}

const _kPrivacySections = [
  _LegalSection(
    heading: 'Clinical Data Protection',
    body:
        'BastiKarma collects patient and clinical observation data entered by authorized Ayurvedic practitioners solely for protocol adherence and patient management. All data transmissions are encrypted.',
  ),
  _LegalSection(
    heading: 'Server-Side Storage',
    body:
        'Patient records, assessment scores, and daily observation logs are securely maintained on dedicated backend servers. Access is strictly limited to authenticated healthcare providers.',
  ),
  _LegalSection(
    heading: 'Data Integrity & Retention',
    body:
        'Clinical logs are retained in compliance with healthcare documentation standards. No medical or personal identifiers are sold, leased, or shared with unauthorized third parties.',
  ),
  _LegalSection(
    heading: 'Practitioner Inquiries',
    body:
        'For security, auditing, or institutional compliance questions, contact your clinical administrator or the designated security officer.',
  ),
];

const _kTermsSections = [
  _LegalSection(
    heading: 'Intended Clinical Use',
    body:
        'BastiKarma serves as an Ayurvedic clinical decision-support and therapy tracking system. It is designed to assist qualified practitioners and does not substitute independent clinical diagnosis.',
  ),
  _LegalSection(
    heading: 'Practitioner Accountability',
    body:
        'Healthcare practitioners are responsible for verifying patient contraindications, dosha assessments, and tailored formulation dosages prior to treatment administration.',
  ),
  _LegalSection(
    heading: 'Security & Credentials',
    body:
        'Authorized users must maintain confidential login credentials and ensure prompt logout after completing clinical sessions on shared clinical hardware.',
  ),
];

// ── Profile Main Screen ───────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static void _openPrivacyPolicy() {
    Get.to<void>(
      () => const _LegalPage(
        title: 'Privacy Policy',
        sections: _kPrivacySections,
      ),
      transition: Transition.rightToLeft,
    );
  }

  static void _openTermsOfService() {
    Get.to<void>(
      () => const _LegalPage(
        title: 'Terms of Service',
        sections: _kTermsSections,
      ),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Header Card ──
          _ProfileHeaderCard(controller: controller),

          const SizedBox(height: 24),

          // ── Account Section ──
          _SectionTitle(title: 'Account'),
          const SizedBox(height: 10),
          _ProfileCard(
            children: [
              _ProfileRow(
                icon: Icons.person_outline_rounded,
                title: 'Personal Information',
                subtitle: 'Name & registered email address',
                onTap: () => Get.to<void>(
                  () => const EditProfileScreen(),
                  transition: Transition.rightToLeft,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Security Section ──
          _SectionTitle(title: 'Security'),
          const SizedBox(height: 10),
          _ProfileCard(
            children: [
              _ProfileRow(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update your account access password',
                onTap: () => Get.to<void>(
                  () => const ChangePasswordScreen(),
                  transition: Transition.rightToLeft,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── About & Legal Section ──
          _SectionTitle(title: 'About & Legal'),
          const SizedBox(height: 10),
          _ProfileCard(
            children: [
              _ProfileRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Clinical data handling & storage',
                onTap: _openPrivacyPolicy,
              ),
              const _Divider(),
              _ProfileRow(
                icon: Icons.gavel_outlined,
                title: 'Terms of Service',
                subtitle: 'Clinical system terms & guidelines',
                onTap: _openTermsOfService,
              ),
              const _Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'App Version',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDarkGreen,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.darkGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Logout Action ──
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => controller.confirmLogout(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.errorRed.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AppColors.errorRed,
                      size: 19,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              'BastiKarma — Ayurvedic Clinical Management System',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGrey,
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Profile Header Card ───────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final ProfileController controller;

  const _ProfileHeaderCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final user = controller.currentUser.value;
        final name = user?.name.trim() ?? '';
        final email = user?.email.trim() ?? '';
        final initials = controller.getInitials(name);
        final role = (user?.role.isNotEmpty ?? false)
            ? '${user!.role[0].toUpperCase()}${user.role.substring(1)} Account'
            : 'Doctor Account';

        return Row(
          children: [
            // Initials Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Name, Email, Status Badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'Practitioner',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDarkGreen,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email.isNotEmpty ? email : 'No email associated',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.darkGrey.withValues(alpha: 0.9),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Professional Status Badge
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  role,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGreen,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Reusable Component Pieces ─────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textDarkGreen,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfileCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.darkGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.primaryGreen.withValues(alpha: 0.07),
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
