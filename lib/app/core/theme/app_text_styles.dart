import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── On green gradient headers (white text) ─────────────────────────────
  static const TextStyle pageTitle = TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle pageSubtitle = TextStyle(
    color: Colors.white70,
    fontSize: 13,
  );

  static const TextStyle pageHeaderTitle = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle pageHeaderSubtitle = TextStyle(
    color: Colors.white70,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle greetingText = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.2,
  );

  static const TextStyle profileName = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle profileRole = TextStyle(
    color: Colors.white70,
    fontSize: 12.5,
  );

  static const TextStyle profileQual = TextStyle(
    color: Colors.white60,
    fontSize: 12,
  );

  static const TextStyle stepLabel = TextStyle(
    color: Colors.white70,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle stepPercent = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // ── Headings ───────────────────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headlineMedium = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle sectionHeading = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  // ── Body text ──────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 14,
  );

  static const TextStyle bodySmall = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 13,
  );

  static const TextStyle captionText = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 12,
  );

  // ── Profile rows ───────────────────────────────────────────────────────
  static const TextStyle profileSectionTitle = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle contactLabel = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 11,
  );

  static const TextStyle contactValue = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle navRowLabel = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 13.5,
  );

  // ── Form fields ────────────────────────────────────────────────────────
  static const TextStyle fieldLabel = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle fieldInput = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 14,
  );

  static const TextStyle fieldHint = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 14,
  );

  // ── Dashboard stat cards ───────────────────────────────────────────────
  static const TextStyle statValue = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle statLabel = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 11,
    height: 1.3,
  );

  // ── List / card items ──────────────────────────────────────────────────
  static const TextStyle patientName = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle patientMeta = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 12.5,
  );

  static const TextStyle cardTitle = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cardSubtitle = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 11,
  );

  static const TextStyle actionCardTitle = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle actionCardSubtitle = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 10,
  );

  // ── Buttons / labels ───────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle bottomButton = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle logoutText = TextStyle(
    color: AppColors.errorRed,
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
  );

  // ── Badges / chips / nav ───────────────────────────────────────────────
  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle chipLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle navLabel = TextStyle(fontSize: 10);

  // ── Link ──────────────────────────────────────────────────────────────
  static const TextStyle link = TextStyle(
    color: AppColors.primaryGreen,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primaryGreen,
  );

  // ── Assessment ────────────────────────────────────────────────────────
  static const TextStyle assessmentSectionTitle = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  static const TextStyle questionText = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const TextStyle optionText = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle hintText = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle resultLabel = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle resultValue = TextStyle(
    color: AppColors.textDarkGreen,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle bannerText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle noteText = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    height: 1.4,
  );

  static const TextStyle prescriptionTitle = TextStyle(
    color: AppColors.primaryGreen,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  // ── Misc ──────────────────────────────────────────────────────────────
  static const TextStyle version = TextStyle(
    color: AppColors.darkGrey,
    fontSize: 11.5,
  );
}