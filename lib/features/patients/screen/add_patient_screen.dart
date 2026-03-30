import 'package:bastikarma/features/patients/screen/rogi_pariksha7.dart';
import 'package:bastikarma/features/patients/screen/treatment9.dart';
import 'package:flutter/material.dart';

import '../../../app/core/theme/app_theme.dart';
import '../widgets/form_widget.dart';
import 'basic_info1.dart';
import 'clinic_info3.dart';
import 'female_history5.dart';
import 'general_exam6.dart';
import 'hospital_info2.dart';
import 'investigations8.dart';
import 'life_style4.dart';

/// Complete multi-step form for adding a new patient.
///
/// Steps:
///   1  Basic Patient Info
///   2  Hospital Info
///   3  Clinical Info
///   4  Lifestyle & Habits
///   5  Menstrual / Obstetric History  ← only if sex == 'Female'
///   6  General Examination
///   7  Rogi Pariksha
///   8  Investigations
///   9  Treatment
///
/// The screen uses a PageView with physics disabled so navigation is
/// controlled programmatically.  A shared [_formData] map accumulates
/// values from every step.
class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final PageController _pageController = PageController();

  /// Shared data bag filled by each step.
  final Map<String, dynamic> _formData = {};

  /// Current logical step index (0-based).
  int _currentStep = 0;

  /// Whether the female-history step should be included.
  bool get _isFemale => _formData['sex'] == 'Female';

  /// Total number of steps shown (9 or 8 depending on sex).
  int get _totalSteps => _isFemale ? 9 : 8;

  /// Returns the title + subtitle for each step header.
  ({String title, String emoji}) get _stepMeta {
    final always = [
      (title: 'Basic Patient Info', emoji: '👤'),
      (title: 'Hospital Information', emoji: '🏥'),
      (title: 'Clinical Information', emoji: '🩺'),
      (title: 'Lifestyle & Habits', emoji: '🍽️'),
      // Female history inserted here if applicable (index 4)
      (title: 'General Examination', emoji: '🧪'),
      (title: 'Rogi Pariksha', emoji: '🌿'),
      (title: 'Investigations', emoji: '🔬'),
      (title: 'Treatment', emoji: '🧾'),
    ];

    // Build the ordered list dynamically
    final steps = <(String, String)>[
      (always[0].title, always[0].emoji), // 0 - Basic
      (always[1].title, always[1].emoji), // 1 - Hospital
      (always[2].title, always[2].emoji), // 2 - Clinical
      (always[3].title, always[3].emoji), // 3 - Lifestyle
    ];
    if (_isFemale) {
      steps.add(('Menstrual & Obstetric', '👩‍⚕️')); // 4 (female only)
    }
    steps.add((always[4].title, always[4].emoji)); // General Exam
    steps.add((always[5].title, always[5].emoji)); // Rogi Pariksha
    steps.add((always[6].title, always[6].emoji)); // Investigations
    steps.add((always[7].title, always[7].emoji)); // Treatment

    if (_currentStep < steps.length) {
      final s = steps[_currentStep];
      return (title: s.$1, emoji: s.$2);
    }
    return (title: 'Add New Patient', emoji: '➕');
  }

  void _next() {
    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _prev() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _submit() {
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.primaryGreen,
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Patient Added!',
              style: TextStyle(
                color: AppColors.textDarkGreen,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formData['name'] ?? 'Patient'} has been successfully registered.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.darkGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to patients list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the list of page widgets dynamically (female step conditional)
  List<Widget> get _pages {
    final pages = <Widget>[
      // Step 1
      Step1BasicInfo(data: _formData, onNext: _next),
      // Step 2
      Step2HospitalInfo(data: _formData, onNext: _next, onPrev: _prev),
      // Step 3
      Step3ClinicalInfo(data: _formData, onNext: _next, onPrev: _prev),
      // Step 4
      Step4Lifestyle(
        data: _formData,
        onNext: () {
          // After saving, check if we need to add/remove female step
          // Then navigate
          _next();
        },
        onPrev: _prev,
      ),
    ];

    if (_isFemale) {
      pages.add(
        Step5FemaleHistory(data: _formData, onNext: _next, onPrev: _prev),
      );
    }

    pages.addAll([
      Step6GeneralExam(data: _formData, onNext: _next, onPrev: _prev),
      Step7RogiPariksha(data: _formData, onNext: _next, onPrev: _prev),
      Step8Investigations(data: _formData, onNext: _next, onPrev: _prev),
      Step9Treatment(data: _formData, onSubmit: _submit, onPrev: _prev),
    ]);

    return pages;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = _stepMeta;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Gradient Header ──────────────────────────────────
            FormStepHeader(
              title: 'Add New Patient',
              subtitle: '${meta.emoji}  ${meta.title}',
              currentStep: _currentStep + 1,
              totalSteps: _totalSteps,
              onBack: _prev,
            ),

            // ── Scrollable Step Content ──────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pages.length,
                itemBuilder: (_, index) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: _pages[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
