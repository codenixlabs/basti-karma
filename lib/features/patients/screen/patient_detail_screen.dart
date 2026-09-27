import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/core/routes/app_pages.dart';
import '../../../app/core/theme/app_text_styles.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/data/models/patient/basti_treatment_plan_model.dart';
import '../../../app/data/models/patient/patient_model.dart';
import '../../../app/data/models/patient/treatment_status.dart';
import '../../../app/data/repositories/api_paschata_karma_repository.dart';
import '../../../app/shared/utils/custom_snackbar.dart';
import '../../../app/shared/widgets/physician_yukti_banner.dart';
import '../../assessment/controller/assessment_controller.dart';
import '../../assessment/controller/treatment_plan_controller.dart';
import '../../assessment/screens/paschatkarma_screen.dart';
import '../../assessment/screens/pradhankarma_screen.dart';
import '../controller/patient_controller.dart';
import '../widgets/patient_case_sheet_sheet.dart';
import '../widgets/patient_documents_sheet.dart';
import '../widgets/patient_pdf_report_dialog.dart';
import 'add_patient_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final PatientModel patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TreatmentPlanController _tpc;
  late PatientModel _patient;
  late TabController _tabController;
  bool _isLoading = true;
  BastiTreatmentPlanModel? _activePlan;
  List<BastiTreatmentPlanModel> _historyPlans = [];
  int _completedSessionsCount = 0;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _tabController = TabController(length: 3, vsync: this);
    if (Get.isRegistered<TreatmentPlanController>()) {
      _tpc = Get.find<TreatmentPlanController>();
    } else {
      _tpc = Get.put(TreatmentPlanController());
    }
    _loadData(isInitial: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openDocumentSheet() async {
    final oldPhoto = _patient.photoUrl;
    await Get.bottomSheet(
      PatientDocumentsSheet(patient: _patient),
      isScrollControlled: true,
    );
    if (Get.isRegistered<PatientController>()) {
      final curr = Get.find<PatientController>().currentPatient.value;
      if (curr != null && curr.id == _patient.id && curr.photoUrl != oldPhoto) {
        if (mounted) {
          setState(() {
            _patient = curr;
          });
        }
      }
    }
  }

  Future<void> _loadData({bool isInitial = false}) async {
    if (isInitial && mounted) {
      setState(() => _isLoading = true);
    }

    // Fetch fresh patient record from backend GET /patients/:id
    try {
      if (Get.isRegistered<PatientController>()) {
        final fresh = await Get.find<PatientController>().getPatient(
          widget.patient.id,
        );
        if (fresh != null && mounted) {
          _patient = fresh;
        }
      }
    } catch (_) {
      // Retain existing _patient on error/offline
    }

    // 1. Check if Pradhana Karma is completed
    bool isPradhanaCompleted = _patient.pradhanaKarmaCompleted;
    if (!isPradhanaCompleted && Get.isRegistered<AssessmentController>()) {
      final ac = Get.find<AssessmentController>();
      if (ac.patientId == _patient.id && ac.pradhankarmaComplete.value) {
        isPradhanaCompleted = true;
      }
    }

    // 2. Check if Paschata Karma is completed (only query backend if Pradhana Karma is completed)
    bool isPaschataCompleted = _patient.paschataKarmaCompleted;
    if (!isPaschataCompleted) {
      if (Get.isRegistered<AssessmentController>()) {
        final ac = Get.find<AssessmentController>();
        if (ac.patientId == _patient.id && ac.paschatkarmaComplete.value) {
          isPaschataCompleted = true;
        }
      }
      if (!isPaschataCompleted && isPradhanaCompleted) {
        try {
          final paschataRepo = ApiPaschataKarmaRepository();
          final existing = await paschataRepo.getPaschataKarma(_patient.id);
          if (existing != null) {
            isPaschataCompleted = true;
          }
        } catch (_) {}
      }
    }

    final allPlans = await _tpc.getPlansForPatient(_patient.id);

    BastiTreatmentPlanModel? active;
    final history = <BastiTreatmentPlanModel>[];

    for (final plan in allPlans) {
      final bool isPlanDone =
          plan.status == TreatmentStatus.completed ||
          (plan.scheduleDays.isNotEmpty &&
              plan.scheduleDays.every((d) => d.isCompleted)) ||
          isPradhanaCompleted;

      if (isPlanDone) {
        history.add(
          plan.status == TreatmentStatus.completed
              ? plan
              : plan.copyWith(status: TreatmentStatus.completed),
        );
        isPradhanaCompleted = true;
      } else if (plan.status == TreatmentStatus.active ||
          plan.status == TreatmentStatus.draft) {
        active ??= plan;
      } else {
        history.add(plan);
      }
    }

    if (isPaschataCompleted || history.isNotEmpty) {
      isPradhanaCompleted = true;
    }

    int completedSessions = 0;
    if (active != null) {
      final sessions = await _tpc.getSessions(active.id);
      completedSessions = sessions.where((s) => s.isCompleted).length;

      final totalDays = active.scheduleDays.isNotEmpty
          ? active.scheduleDays.length
          : (active.selectedPatternCode.toLowerCase().contains('karma')
                ? 30
                : (active.selectedPatternCode.toLowerCase().contains('kala')
                      ? 16
                      : 8));

      if (totalDays > 0 && completedSessions >= totalDays) {
        history.add(active.copyWith(status: TreatmentStatus.completed));
        active = null;
        isPradhanaCompleted = true;
      }
    }

    if (isPradhanaCompleted != _patient.pradhanaKarmaCompleted ||
        isPaschataCompleted != _patient.paschataKarmaCompleted) {
      _patient = _patient.copyWith(
        pradhanaKarmaCompleted: isPradhanaCompleted,
        paschataKarmaCompleted: isPaschataCompleted,
      );
      if (Get.isRegistered<PatientController>()) {
        final pc = Get.find<PatientController>();
        final curr = pc.currentPatient.value;
        if (curr != null && curr.id == _patient.id) {
          pc.currentPatient.value = _patient;
        }
      }
    }

    if (mounted) {
      setState(() {
        _activePlan = active;
        _historyPlans = history;
        _completedSessionsCount = completedSessions;
        _isLoading = false;
      });
    }
  }

  Future<void> _callPatient(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      CustomSnackBar.showInfo('No phone number recorded for this patient.');
      return;
    }
    final cleanPhone = phone.trim().replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        CustomSnackBar.showError('Could not launch phone dialer.');
      }
    } catch (e) {
      CustomSnackBar.showError('Unable to place call: $e');
    }
  }

  void _continueTreatment(BastiTreatmentPlanModel plan) {
    final patientCtrl = Get.find<PatientController>();
    patientCtrl.selectPatient(_patient);

    _tpc.currentPlan.value = plan;
    _tpc.getSessions(plan.id).then((sessions) {
      _tpc.persistedSessions.assignAll(sessions);
    }).catchError((_) {});

    if (Get.isRegistered<AssessmentController>()) {
      Get.delete<AssessmentController>();
    }
    Get.put(
      AssessmentController(
        patientId: _patient.id,
        patientName: _patient.name,
        patientAge: _patient.age,
        prakriti: _patient.prakriti,
        sarataha: _patient.sarataha,
        sanhanan: _patient.sanhanan,
        pramana: _patient.pramana,
        satva: _patient.satva,
        satmya: _patient.satmya,
        aharaShakti: _patient.aharaShakti,
        vyayamaShakti: _patient.vyayamaShakti,
        vaya: _patient.vaya,
        jihwa: _patient.jihwa,
        initialPlan: plan,
        initialPoorvaKarmaCompleted: _patient.poorvaKarmaCompleted,
        initialPradhanaKarmaCompleted: _patient.pradhanaKarmaCompleted,
        initialPaschataKarmaCompleted: _patient.paschataKarmaCompleted,
      ),
    );

    if (!_patient.poorvaKarmaCompleted) {
      Get.toNamed(AppRoutes.assessment)?.then((_) => _loadData());
      return;
    }

    final initialStep = _completedSessionsCount > 0 ? 3 : 0;
    Get.to(
      () => PradhanKarmaScreen(initialStep: initialStep),
    )?.then((_) => _loadData());
  }

  void _startPradhanKarma() {
    final patientCtrl = Get.find<PatientController>();
    patientCtrl.selectPatient(_patient);

    final plan = _activePlan;
    if (plan != null) {
      _tpc.currentPlan.value = plan;
      _tpc.getSessions(plan.id).then((sessions) {
        _tpc.persistedSessions.assignAll(sessions);
      }).catchError((_) {});
    } else {
      _tpc.currentPlan.value = null;
      _tpc.persistedSessions.clear();
    }

    if (Get.isRegistered<AssessmentController>()) {
      Get.delete<AssessmentController>();
    }
    Get.put(
      AssessmentController(
        patientId: _patient.id,
        patientName: _patient.name,
        patientAge: _patient.age,
        prakriti: _patient.prakriti,
        sarataha: _patient.sarataha,
        sanhanan: _patient.sanhanan,
        pramana: _patient.pramana,
        satva: _patient.satva,
        satmya: _patient.satmya,
        aharaShakti: _patient.aharaShakti,
        vyayamaShakti: _patient.vyayamaShakti,
        vaya: _patient.vaya,
        jihwa: _patient.jihwa,
        initialPlan: plan,
        initialPoorvaKarmaCompleted: _patient.poorvaKarmaCompleted,
        initialPradhanaKarmaCompleted: _patient.pradhanaKarmaCompleted,
        initialPaschataKarmaCompleted: _patient.paschataKarmaCompleted,
      ),
    );

    Get.to(
      () => const PradhanKarmaScreen(initialStep: 0),
    )?.then((_) => _loadData());
  }

  void _openAssessment() {
    final patientCtrl = Get.find<PatientController>();
    patientCtrl.selectPatient(_patient);

    final plan = _activePlan;
    _tpc.currentPlan.value = plan;
    if (plan == null) {
      _tpc.persistedSessions.clear();
    }

    if (Get.isRegistered<AssessmentController>()) {
      Get.delete<AssessmentController>();
    }
    Get.put(
      AssessmentController(
        patientId: _patient.id,
        patientName: _patient.name,
        patientAge: _patient.age,
        prakriti: _patient.prakriti,
        sarataha: _patient.sarataha,
        sanhanan: _patient.sanhanan,
        pramana: _patient.pramana,
        satva: _patient.satva,
        satmya: _patient.satmya,
        aharaShakti: _patient.aharaShakti,
        vyayamaShakti: _patient.vyayamaShakti,
        vaya: _patient.vaya,
        jihwa: _patient.jihwa,
        initialPlan: plan,
        initialPoorvaKarmaCompleted: _patient.poorvaKarmaCompleted,
        initialPradhanaKarmaCompleted: _patient.pradhanaKarmaCompleted,
        initialPaschataKarmaCompleted: _patient.paschataKarmaCompleted,
      ),
    );

    Get.toNamed(AppRoutes.assessment)?.then((_) => _loadData());
  }

  Future<void> _openEditPatient({int initialStep = 0}) async {
    final updated = await Get.to<PatientModel?>(
      () => AddPatientScreen(
        patientToEdit: _patient,
        initialStep: initialStep,
      ),
      transition: Transition.rightToLeft,
    );

    if (updated != null && mounted) {
      setState(() {
        _patient = updated;
      });
    }
    await _loadData();
  }

  Future<void> _downloadPdfReport() async {
    await PatientPdfReportDialog.show(context, _patient);
  }

  @override
  Widget build(BuildContext context) {
    final p = _patient;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(p.name, style: AppTextStyles.pageTitle),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            onPressed: _downloadPdfReport,
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Download Patient PDF Report',
          ),
          TextButton.icon(
            onPressed: _openAssessment,
            icon: const Icon(
              Icons.assignment_outlined,
              color: Colors.white,
              size: 16,
            ),
            label: const Text(
              'Assessment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primaryGreen,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(child: _buildHeroHeader(p)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primaryGreen,
                        unselectedLabelColor: AppColors.darkGrey,
                        indicatorColor: AppColors.primaryGreen,
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.description_outlined, size: 20),
                            text: 'Medical Record',
                          ),
                          Tab(
                            icon: Icon(Icons.spa_outlined, size: 20),
                            text: 'Basti Therapy',
                          ),
                          Tab(
                            icon: Icon(Icons.biotech_outlined, size: 20),
                            text: 'Reports & Media',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildClinicalRecordTab(p),
                    _buildBastiTherapyTab(),
                    _buildReportsTab(p),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Hero Header ────────────────────────────────────────────────────────────

  Widget _buildHeroHeader(PatientModel p) {
    final initials = p.name.trim().isNotEmpty
        ? p.name
              .trim()
              .split(RegExp(r'\s+'))
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'PT';
    final hasPhone = p.phone != null && p.phone!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar circle with initials & ring
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name, age, sex, admission badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: AppTextStyles.patientName.copyWith(
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.25,
                              ),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            p.admissionType,
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${p.age} yrs • ${p.sex}',
                          style: AppTextStyles.patientMeta.copyWith(
                            fontSize: 12.5,
                          ),
                        ),
                        if (p.bloodGroup != null &&
                            p.bloodGroup!.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE53935,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Blood: ${p.bloodGroup}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFC62828),
                              ),
                            ),
                          ),
                        if (p.opdNumber != null && p.opdNumber!.isNotEmpty)
                          Text(
                            'OPD: ${p.opdNumber}',
                            style: AppTextStyles.captionText.copyWith(
                              fontSize: 11.5,
                            ),
                          )
                        else if (p.ipdNumber != null && p.ipdNumber!.isNotEmpty)
                          Text(
                            'IPD: ${p.ipdNumber}',
                            style: AppTextStyles.captionText.copyWith(
                              fontSize: 11.5,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Diagnosis & Prakriti tags
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 48,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      size: 13,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        p.diagnosis.isNotEmpty
                            ? p.diagnosis
                            : 'Ayurvedic Treatment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDarkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (p.prakriti.isNotEmpty)
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 48,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.psychology_outlined,
                        size: 13,
                        color: Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Prakriti: ${p.prakriti}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (p.desha.isNotEmpty)
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 48,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Color(0xFF6A1B9A),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          p.desha,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Action Buttons Bar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callPatient(p.phone),
                  icon: Icon(
                    Icons.phone_outlined,
                    size: 15,
                    color: hasPhone
                        ? AppColors.primaryGreen
                        : AppColors.darkGrey,
                  ),
                  label: Text(
                    'Call',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: hasPhone
                          ? AppColors.primaryGreen
                          : AppColors.darkGrey,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    side: BorderSide(
                      color: hasPhone
                          ? AppColors.primaryGreen.withValues(alpha: 0.4)
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEditPatient(),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: AppColors.primaryGreen,
                  ),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    side: BorderSide(
                      color: AppColors.primaryGreen.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => PatientCaseSheetSheet.show(context, p),
                  icon: const Icon(
                    Icons.assignment_ind_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Full CRF Sheet',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Medical Record (CRF) ────────────────────────────────────────────

  Widget _buildClinicalRecordTab(PatientModel p) {
    final isFemale = p.sex.trim().toLowerCase() == 'female';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Vitals & General Physical Exam
          _buildCard(
            title: 'VITALS & PHYSICAL EXAMINATION',
            icon: Icons.monitor_heart_outlined,
            onEdit: () => _openEditPatient(initialStep: isFemale ? 5 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVitalsGrid(p),
                const SizedBox(height: 14),
                Divider(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  height: 1,
                ),
                const SizedBox(height: 12),
                Text(
                  'Physiological Functions',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDarkGreen,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTwoColRow(
                  'Appetite (Kshudha)',
                  p.ahara ?? '—',
                  'Sleep (Nidra)',
                  p.nidra ?? '—',
                ),
                const SizedBox(height: 8),
                _buildTwoColRow(
                  'Bowel (Kostha)',
                  p.bowelHabits ?? '—',
                  'Micturition (Mutra)',
                  p.urineFrequency ?? '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Clinical Presentation & History
          _buildCard(
            title: 'CLINICAL PRESENTATION & HISTORY',
            icon: Icons.medical_information_outlined,
            onEdit: () => _openEditPatient(initialStep: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClinicalItem(
                  'Chief Complaints',
                  p.chiefComplaints,
                  icon: Icons.chat_bubble_outline_rounded,
                ),
                const SizedBox(height: 12),
                _buildClinicalItem(
                  'History of Present Illness (HPI)',
                  p.historyOfPresentIllness,
                  icon: Icons.history_edu_rounded,
                ),
                const SizedBox(height: 12),
                _buildClinicalItem(
                  'Past Medical / Surgical History',
                  p.historyOfPastIllness,
                  icon: Icons.healing_outlined,
                ),
                const SizedBox(height: 12),
                _buildClinicalItem(
                  'Family History',
                  p.familyHistory,
                  icon: Icons.people_outline_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Ayurvedic Rogi Pariksha
          _buildCard(
            title: 'AYURVEDIC ROGI PARIKSHA (11 METRICS)',
            icon: Icons.psychology_outlined,
            onEdit: () => _openEditPatient(initialStep: isFemale ? 6 : 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTwoColRow(
                  'Prakriti',
                  p.prakriti.isNotEmpty ? p.prakriti : '—',
                  'Sarataha',
                  p.sarataha.isNotEmpty ? p.sarataha : '—',
                ),
                const SizedBox(height: 8),
                _buildTwoColRow(
                  'Sanhanan',
                  p.sanhanan.isNotEmpty ? p.sanhanan : '—',
                  'Pramana',
                  p.pramana.isNotEmpty ? p.pramana : '—',
                ),
                const SizedBox(height: 8),
                _buildTwoColRow(
                  'Satva',
                  p.satva.isNotEmpty ? p.satva : '—',
                  'Satmya',
                  p.satmya.isNotEmpty ? p.satmya : '—',
                ),
                const SizedBox(height: 8),
                _buildTwoColRow(
                  'Ahara Shakti',
                  p.aharaShakti.isNotEmpty ? p.aharaShakti : '—',
                  'Vyayama Shakti',
                  p.vyayamaShakti.isNotEmpty ? p.vyayamaShakti : '—',
                ),
                const SizedBox(height: 8),
                _buildTwoColRow(
                  'Vaya (Age Stage)',
                  p.vaya.isNotEmpty ? p.vaya : '—',
                  'Jihwa (Tongue)',
                  p.jihwa.isNotEmpty ? p.jihwa : '—',
                ),
                const SizedBox(height: 8),
                _buildFieldRow(
                  'Desha (Habitat)',
                  p.desha.isNotEmpty ? p.desha : '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Lifestyle, Habits & Demographics
          _buildCard(
            title: 'LIFESTYLE, HABITS & DEMOGRAPHICS',
            icon: Icons.person_outline_rounded,
            onEdit: () => _openEditPatient(initialStep: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTwoColRow(
                  'Dietary Pattern',
                  p.ahara ?? '—',
                  'Addiction / Habits',
                  p.addiction ?? 'None',
                ),
                const SizedBox(height: 8),
                _buildTwoColRow(
                  'Occupation',
                  p.occupation ?? '—',
                  'Marital Status',
                  p.maritalStatus ?? '—',
                ),
                const SizedBox(height: 8),
                _buildTwoColRow(
                  'Religion',
                  p.religion ?? '—',
                  'Contact Phone',
                  p.phone ?? '—',
                ),
                const SizedBox(height: 8),
                _buildFieldRow('Residential Address', p.address ?? '—'),
                const SizedBox(height: 8),
                _buildTwoColRow(
                  'OPD Number',
                  p.opdNumber ?? '—',
                  'IPD Number',
                  p.ipdNumber ?? '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Female Obstetric History (Conditional)
          if (isFemale) ...[
            _buildCard(
              title: 'FEMALE OBSTETRIC & GYNECOLOGICAL HISTORY',
              icon: Icons.pregnant_woman_rounded,
              onEdit: () => _openEditPatient(initialStep: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldRow(
                    'Menstrual History',
                    p.menstrualHistory ?? '—',
                  ),
                  const SizedBox(height: 8),
                  _buildTwoColRow(
                    'Number of Deliveries',
                    p.numberOfDeliveries?.toString() ?? '—',
                    'Abortions',
                    p.abortion?.toString() ?? '—',
                  ),
                  const SizedBox(height: 8),
                  _buildFieldRow(
                    'Surgical Interventions',
                    p.surgicalIntervention ?? 'None',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 6. Intake Treatment Given
          _buildCard(
            title: 'INTAKE TREATMENT & PRIOR MEDICATIONS',
            icon: Icons.medication_outlined,
            onEdit: () => _openEditPatient(initialStep: isFemale ? 8 : 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.treatmentGiven != null &&
                          p.treatmentGiven!.trim().isNotEmpty
                      ? p.treatmentGiven!
                      : 'No prior treatment recorded.',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        p.treatmentGiven != null &&
                            p.treatmentGiven!.trim().isNotEmpty
                        ? AppColors.textDarkGreen
                        : AppColors.darkGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Tab 2: Basti Therapy ───────────────────────────────────────────────────

  Widget _buildBastiTherapyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active treatment card
          _buildSectionHeader(
            'ACTIVE TREATMENT',
            Icons.medical_services_outlined,
          ),
          const SizedBox(height: 8),
          _buildActiveTreatmentCard(),
          const SizedBox(height: 24),

          // Treatment history list
          _buildSectionHeader('TREATMENT HISTORY', Icons.history_rounded),
          const SizedBox(height: 8),
          _buildTreatmentHistoryList(),
          const SizedBox(height: 16),

          // Yukti guidance banner
          const PhysicianYuktiBanner(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Tab 3: Reports & Media ─────────────────────────────────────────────────

  Widget _buildReportsTab(PatientModel p) {
    final isFemale = p.sex.trim().toLowerCase() == 'female';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionHeader(
                  'INVESTIGATIONS & DOCUMENTS',
                  Icons.biotech_outlined,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _openEditPatient(initialStep: isFemale ? 7 : 6),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInvestigationsCard(p),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'PATIENT FULL PDF REPORT',
            Icons.picture_as_pdf_outlined,
          ),
          const SizedBox(height: 8),
          _buildPdfReportDownloadCard(p),
        ],
      ),
    );
  }

  Widget _buildPdfReportDownloadCard(PatientModel p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.primaryGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'OFFICIAL MEDICAL DOSSIER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Comprehensive Patient Report',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDarkGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Generates and downloads a complete compiled PDF report containing all patient demographic details, hospital records, and daily treatment (Karma) assessment evaluations.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.darkGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloadPdfReport,
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text(
                'Download Full PDF Report',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets for Clinical Record ─────────────────────────────────────

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.sectionHeading.copyWith(
                    fontSize: 12,
                    color: AppColors.primaryGreen,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onEdit != null)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 13,
                          color: AppColors.primaryGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildVitalsGrid(PatientModel p) {
    final bmi = p.bmi;
    String bmiCategory = '';
    Color bmiColor = AppColors.successGreen;
    if (bmi != null) {
      if (bmi < 18.5) {
        bmiCategory = 'Underweight';
        bmiColor = const Color(0xFFF57C00);
      } else if (bmi <= 24.9) {
        bmiCategory = 'Normal';
        bmiColor = AppColors.successGreen;
      } else if (bmi <= 29.9) {
        bmiCategory = 'Overweight';
        bmiColor = const Color(0xFFE65100);
      } else {
        bmiCategory = 'Obese';
        bmiColor = const Color(0xFFC62828);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        final crossAxisCount = isNarrow ? 2 : 3;
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _buildVitalTile(
              width: itemWidth,
              label: 'Blood Pressure',
              value: p.bp ?? '—',
              unit: 'mmHg',
              icon: Icons.favorite_outline,
              color: const Color(0xFFC62828),
            ),
            _buildVitalTile(
              width: itemWidth,
              label: 'Heart Rate',
              value: p.hr != null ? p.hr.toString() : '—',
              unit: 'bpm',
              icon: Icons.monitor_heart_outlined,
              color: const Color(0xFFE53935),
            ),
            _buildVitalTile(
              width: itemWidth,
              label: 'Resp Rate',
              value: p.rr != null ? p.rr.toString() : '—',
              unit: '/min',
              icon: Icons.air_rounded,
              color: const Color(0xFF1E88E5),
            ),
            _buildVitalTile(
              width: itemWidth,
              label: 'Temperature',
              value: p.temperature != null ? p.temperature.toString() : '—',
              unit: '°F',
              icon: Icons.thermostat_outlined,
              color: const Color(0xFFF57C00),
            ),
            _buildVitalTile(
              width: itemWidth,
              label: 'Weight',
              value: p.weight != null ? p.weight.toString() : '—',
              unit: 'kg',
              icon: Icons.scale_outlined,
              color: const Color(0xFF43A047),
            ),
            _buildVitalTile(
              width: itemWidth,
              label: 'Height',
              value: p.height != null ? p.height.toString() : '—',
              unit: 'cm',
              icon: Icons.straighten_outlined,
              color: const Color(0xFF00897B),
            ),
            _buildVitalTile(
              width: constraints.maxWidth,
              label: 'Body Mass Index (BMI)',
              value: bmi != null ? bmi.toStringAsFixed(1) : '—',
              unit: 'kg/m²',
              icon: Icons.accessibility_new_outlined,
              color: bmiColor,
              extra: bmiCategory.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: bmiColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bmiCategory,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: bmiColor,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildVitalTile({
    required double width,
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    Widget? extra,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?extra,
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (value != '—') ...[
                  const SizedBox(width: 3),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalItem(String label, String? value, {IconData? icon}) {
    final hasVal = value != null && value.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: AppColors.primaryGreen),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDarkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasVal ? value.trim() : '—',
            style: TextStyle(
              fontSize: 12.5,
              color: hasVal ? AppColors.textDarkGreen : AppColors.darkGrey,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColRow(
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return Row(
      children: [
        Expanded(child: _buildFieldCell(label1, value1)),
        const SizedBox(width: 10),
        Expanded(child: _buildFieldCell(label2, value2)),
      ],
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return _buildFieldCell(label, value);
  }

  Widget _buildFieldCell(String label, String value) {
    final isNone = value == '—' || value.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGrey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            isNone ? '—' : value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isNone ? FontWeight.w400 : FontWeight.w600,
              color: isNone ? AppColors.darkGrey : AppColors.textDarkGreen,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Existing Treatment & Investigation Components ──────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: AppTextStyles.sectionHeading.copyWith(
              fontSize: 14,
              letterSpacing: 1.1,
              color: AppColors.primaryGreen,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInvestigationsCard(PatientModel p) {
    final photoUrl = p.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;
    final resolvedUrl = hasPhoto
        ? PatientDocumentsSheet.resolvePhotoUrl(photoUrl)
        : null;
    final isPdf = hasPhoto && PatientDocumentsSheet.isPdfUrl(photoUrl);
    final findings = p.pathologicalRadiological;
    final hasFindings = findings != null && findings.trim().isNotEmpty;
    final treatment = p.treatmentGiven;
    final hasTreatment = treatment != null && treatment.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pathological & Radiological Findings',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textDarkGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasFindings ? findings : 'No findings recorded.',
            style: TextStyle(
              fontSize: 13,
              color: hasFindings ? AppColors.textDarkGreen : AppColors.darkGrey,
              height: 1.4,
            ),
          ),
          if (hasTreatment) ...[
            const SizedBox(height: 12),
            Text(
              'Treatment Given',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDarkGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              treatment,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textDarkGreen,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Divider(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            height: 1,
          ),
          const SizedBox(height: 12),
          if (hasPhoto && resolvedUrl != null && isPdf) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF6FAF7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => PatientDocumentsSheet.openDocument(resolvedUrl),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE8F5E9),
                                    Color(0xFFC8E6C9),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGreen.withValues(
                                      alpha: 0.12,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: AppColors.primaryGreen,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          PatientDocumentsSheet.getDocumentFileName(
                                            photoUrl,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDarkGreen,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primaryGreen
                                                .withValues(alpha: 0.3),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: const Text(
                                          'PDF',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryGreen,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Investigation Document • Tap to view',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.darkGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(
                          color: AppColors.primaryGreen.withValues(alpha: 0.12),
                          height: 1,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    PatientDocumentsSheet.openDocument(
                                      resolvedUrl,
                                    ),
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Open PDF',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openDocumentSheet,
                                icon: const Icon(Icons.edit_document, size: 15),
                                label: const Text(
                                  'Manage',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryGreen,
                                  side: BorderSide(
                                    color: AppColors.primaryGreen.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                if (hasPhoto && resolvedUrl != null) ...[
                  GestureDetector(
                    onTap: _openDocumentSheet,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        resolvedUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.description_outlined,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Document Attached',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDarkGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to view or replace',
                          style: AppTextStyles.captionText,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.file_present_outlined,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No document attached',
                      style: AppTextStyles.captionText,
                    ),
                  ),
                ],
                TextButton.icon(
                  onPressed: _openDocumentSheet,
                  icon: Icon(
                    hasPhoto
                        ? Icons.visibility_outlined
                        : Icons.upload_file_outlined,
                    size: 16,
                    color: AppColors.primaryGreen,
                  ),
                  label: Text(
                    hasPhoto ? 'Manage' : 'Upload',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveTreatmentCard() {
    // ── Phase 1: Poorva Karma ────────────────────────────────────────────────
    if (!_patient.poorvaKarmaCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Poorva Karma Assessment',
                    style: AppTextStyles.sectionHeading.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF39C12).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'IN PROGRESS',
                    style: TextStyle(
                      color: Color(0xFFD35400),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Pre-procedure assessment • Pariksha, Agni, Kostha & Bala',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textDarkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.darkGrey,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Complete Poorva Karma to proceed to Pradhan Karma',
                    style: AppTextStyles.captionText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openAssessment,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Continue Poorva Karma'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Phase 2: Pradhan Karma ───────────────────────────────────────────────
    final isPradhanaDone =
        _patient.pradhanaKarmaCompleted ||
        _patient.paschataKarmaCompleted ||
        _historyPlans.isNotEmpty;

    if (!isPradhanaDone) {
      final hasActivePlanConfigured =
          _activePlan != null &&
          (_activePlan!.bastiName.isNotEmpty ||
              _completedSessionsCount > 0 ||
              _activePlan!.status == TreatmentStatus.active ||
              _activePlan!.scheduleDays.any((d) => d.isCompleted));

      if (hasActivePlanConfigured) {
        final plan = _activePlan!;
        int totalDays = plan.scheduleDays.length;
        if (totalDays == 0) {
          final code = plan.selectedPatternCode.toLowerCase();
          if (code.contains('karma')) {
            totalDays = 30;
          } else if (code.contains('kala')) {
            totalDays = 16;
          } else {
            totalDays = 8;
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1565C0).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      plan.diseaseName.isNotEmpty
                          ? plan.diseaseName
                          : 'Pradhan Karma Treatment',
                      style: AppTextStyles.sectionHeading.copyWith(
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      plan.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${plan.bastiName} • ${plan.selectedPatternName}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textDarkGreen,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.darkGrey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_completedSessionsCount / $totalDays sessions completed',
                    style: AppTextStyles.captionText.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _continueTreatment(plan),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Continue Treatment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Poorva Karma completed, but Pradhan Karma plan not yet created
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Pradhan Karma Planning',
                    style: AppTextStyles.sectionHeading.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'READY TO START',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Purvakarma completed • Ready for Basti selection and scheduling',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textDarkGreen,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startPradhanKarma,
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Start Pradhan Karma'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Phase 3: Paschatkarma ────────────────────────────────────────────────
    if (!_patient.paschataKarmaCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Paschatkarma Assessment',
                    style: AppTextStyles.sectionHeading.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'IN PROGRESS',
                    style: TextStyle(
                      color: Color(0xFF6A1B9A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Post-procedure care • Complication management (Vyapad & Chikitsa)',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textDarkGreen,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.to(
                    () => const PaschatkarmaScreen(),
                  )?.then((_) => _loadData());
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Continue Paschatkarma'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Phase 4: All Completed ───────────────────────────────────────────────
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.successGreen,
            size: 36,
          ),
          SizedBox(height: 8),
          Text(
            'All treatments completed for this patient.',
            style: AppTextStyles.sectionHeading,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Poorva Karma, Pradhan Karma & Paschatkarma are all completed.',
            style: AppTextStyles.captionText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentHistoryList() {
    final items = <Widget>[];

    // 1. Poorva Karma in History if completed
    if (_patient.poorvaKarmaCompleted) {
      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.successGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poorva Karma Assessment',
                      style: AppTextStyles.sectionHeading.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Pariksha, Agni & Kostha Assessment',
                      style: AppTextStyles.captionText,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Completed',
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
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

    // 2. Pradhan Karma completed plans in History
    if (_historyPlans.isNotEmpty) {
      for (final plan in _historyPlans) {
        final totalPlanDays = plan.scheduleDays.isNotEmpty
            ? plan.scheduleDays.length
            : (plan.selectedPatternCode.toLowerCase().contains('karma')
                  ? 30
                  : (plan.selectedPatternCode.toLowerCase().contains('kala')
                        ? 16
                        : 8));
        items.add(
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.successGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.diseaseName.isNotEmpty
                            ? plan.diseaseName
                            : 'Basti Treatment',
                        style: AppTextStyles.sectionHeading.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${plan.bastiName} • ${plan.selectedPatternName}',
                        style: AppTextStyles.captionText,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalPlanDays Days • Completed',
                        style: AppTextStyles.captionText.copyWith(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w600,
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
    } else if (_patient.pradhanaKarmaCompleted) {
      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.successGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patient.diagnosis.isNotEmpty
                          ? _patient.diagnosis
                          : 'Pradhan Karma Treatment',
                      style: AppTextStyles.sectionHeading.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Basti Administration & Daily Observation',
                      style: AppTextStyles.captionText,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Completed',
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
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

    // 3. Paschatkarma in History if completed
    if (_patient.paschataKarmaCompleted) {
      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.successGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paschatkarma Assessment',
                      style: AppTextStyles.sectionHeading.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Post-procedure Complication Management',
                      style: AppTextStyles.captionText,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Completed',
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
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

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'No treatment history yet.',
            style: AppTextStyles.captionText,
          ),
        ),
      );
    }

    return Column(children: items);
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryGreen.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
