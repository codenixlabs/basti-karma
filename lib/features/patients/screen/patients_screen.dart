import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/routes/app_pages.dart';
import '../../../app/core/theme/app_text_styles.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/data/models/patient/patient_model.dart';
import '../../../app/shared/utils/app_navigation.dart';
import '../../../app/shared/widgets/custom_button.dart';
import '../../../app/shared/utils/custom_snackbar.dart';
import '../../../app/shared/widgets/app_dialog.dart';
import '../../../app/shared/widgets/custom_text_field.dart';
import '../../assessment/controller/assessment_controller.dart';
import '../../assessment/controller/treatment_plan_controller.dart';
import '../controller/patient_controller.dart';
import '../widgets/patient_card.dart';
import '../widgets/patient_documents_sheet.dart';
import 'add_patient_screen.dart';
import 'patient_detail_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final PatientController _patientCtrl;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PatientController>()) {
      _patientCtrl = Get.find<PatientController>();
    } else {
      _patientCtrl = Get.put(PatientController(), permanent: true);
    }
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PatientModel> _getFilteredPatients(List<PatientModel> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.diagnosis.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _onAssess(PatientModel p) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      if (!Get.isRegistered<TreatmentPlanController>()) {
        Get.put(TreatmentPlanController());
      }

      _patientCtrl.selectPatient(p);

      if (Get.isRegistered<AssessmentController>()) {
        Get.delete<AssessmentController>();
      }
      Get.put(
        AssessmentController(
          patientId: p.id,
          patientName: p.name,
          patientAge: p.age,
          prakriti: p.prakriti,
          sarataha: p.sarataha,
          sanhanan: p.sanhanan,
          pramana: p.pramana,
          satva: p.satva,
          satmya: p.satmya,
          aharaShakti: p.aharaShakti,
          vyayamaShakti: p.vyayamaShakti,
          vaya: p.vaya,
          jihwa: p.jihwa,
          initialPoorvaKarmaCompleted: p.poorvaKarmaCompleted,
          initialPradhanaKarmaCompleted: p.pradhanaKarmaCompleted,
          initialPaschataKarmaCompleted: p.paschataKarmaCompleted,
        ),
      );

      await AppNavigation.toNamed(AppRoutes.assessment);
    } finally {
      _isNavigating = false;
    }
  }

  void _confirmDelete(PatientModel p) async {
    final confirmed = await AppDialog.showConfirmation(
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.errorRed,
      title: 'Delete Patient Record?',
      content:
          'Are you sure you want to delete ${p.name}? This clinical record will be permanently removed. This action cannot be undone.',
      cancelText: 'Cancel',
      confirmText: 'Delete',
      confirmColor: AppColors.errorRed,
    );

    if (confirmed == true) {
      try {
        await _patientCtrl.deletePatient(p.id);
        CustomSnackBar.showInfo('Patient record deleted');
      } catch (e) {
        CustomSnackBar.showError('Failed to delete patient: $e');
      }
    }
  }

  void _onEdit(PatientModel p) async {
    await Get.to<PatientModel?>(
      () => AddPatientScreen(patientToEdit: p),
      transition: Transition.rightToLeft,
    );
    _patientCtrl.loadPatients(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [_buildHeader(), _buildAddButton(), _buildPatientList()],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Patients", style: AppTextStyles.pageTitle),
          CustomTextField(
            controller: _searchController,
            label: '',
            hintText: 'Search patients...',
            icon: Icons.search,
            fillColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // ── Add-patient button ────────────────────────────────────────────────────
  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: CustomButton(
        text: 'Add New Patient',
        onPressed: () => AppNavigation.toNamed(AppRoutes.addPatient),
      ),
    );
  }

  // ── Patient list ──────────────────────────────────────────────────────────
  Widget _buildPatientList() {
    return Expanded(
      child: Obx(() {
        if (_patientCtrl.isLoading.value && _patientCtrl.patients.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          );
        }

        if (_patientCtrl.hasError.value && _patientCtrl.patients.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 54,
                    color: AppColors.errorRed,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to Load Patients',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.textDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _patientCtrl.errorMessage.value,
                    style: AppTextStyles.captionText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _patientCtrl.loadPatients(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final patients = _getFilteredPatients(_patientCtrl.patients);
        if (patients.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _patientCtrl.loadPatients(isRefresh: true),
            color: AppColors.primaryGreen,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchQuery.isNotEmpty) ...[
                            Icon(
                              Icons.search_off_rounded,
                              size: 54,
                              color: AppColors.darkGrey.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No patients matching "$_searchQuery"',
                              style: AppTextStyles.cardTitle.copyWith(
                                color: AppColors.textDarkGreen,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Check for typos or try searching by diagnosis.',
                              style: AppTextStyles.captionText,
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            Icon(
                              Icons.people_outline,
                              size: 54,
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No Patients Registered',
                              style: AppTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap "Add New Patient" above to register your first patient.',
                              style: AppTextStyles.captionText,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _patientCtrl.loadPatients(isRefresh: true),
          color: AppColors.primaryGreen,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final p = patients[index];
              return PatientCard(
                name: p.name,
                age: p.age,
                diagnosis: p.diagnosis,
                isActive: true,
                onView: () => Get.to(() => PatientDetailScreen(patient: p)),
                onEdit: () => _onEdit(p),
                onAssess: () => _onAssess(p),
                onDocs: () {
                  Get.bottomSheet(
                    PatientDocumentsSheet(patient: p),
                    isScrollControlled: true,
                  );
                },
                onDelete: () => _confirmDelete(p),
              );
            },
          ),
        );
      }),
    );
  }
}
