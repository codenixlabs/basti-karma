import 'package:get/get.dart';

import '../../../app/data/models/patient/patient_model.dart';
import '../../../app/data/services/auth_service.dart';
import '../../patients/controller/patient_controller.dart';

class DashboardStat {
  final String label;
  final int value;
  final String iconType;

  DashboardStat({
    required this.label,
    required this.value,
    required this.iconType,
  });
}

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxString doctorName = 'Doctor'.obs;

  final RxList<DashboardStat> stats = <DashboardStat>[
    DashboardStat(label: 'Total Patients', value: 0, iconType: 'patients'),
    DashboardStat(label: 'OPD Patients', value: 0, iconType: 'opd'),
    DashboardStat(label: 'IPD Patients', value: 0, iconType: 'ipd'),
  ].obs;

  PatientController? get _patientController =>
      Get.isRegistered<PatientController>() ? Get.find<PatientController>() : null;

  List<PatientModel> get recentPatients {
    final _ = stats.length;
    final list = _patientController?.patients ?? <PatientModel>[];
    return list.take(3).toList();
  }

  bool get hasPatients {
    final _ = stats.length;
    return (_patientController?.patients.isNotEmpty ?? false);
  }

  int get totalPatientsCount => _patientController?.patients.length ?? 0;

  int get opdPatientsCount =>
      _patientController?.patients
          .where((p) => p.admissionType.toUpperCase().contains('OPD'))
          .length ??
      0;

  int get ipdPatientsCount =>
      _patientController?.patients
          .where((p) => p.admissionType.toUpperCase().contains('IPD'))
          .length ??
      0;

  final RxBool isRefreshing = false.obs;

  void changeTab(int index) => currentIndex.value = index;

  @override
  void onInit() {
    super.onInit();
    currentIndex.value = 0;
    _loadData();
    _initPatientWatcher();
  }

  /// Resets the controller state to clean initial defaults.
  void resetState() {
    currentIndex.value = 0;
    doctorName.value = 'Doctor';
    stats.value = [
      DashboardStat(label: 'Total Patients', value: 0, iconType: 'patients'),
      DashboardStat(label: 'OPD Patients', value: 0, iconType: 'opd'),
      DashboardStat(label: 'IPD Patients', value: 0, iconType: 'ipd'),
    ];
  }

  void _initPatientWatcher() {
    if (Get.isRegistered<PatientController>()) {
      final pCtrl = Get.find<PatientController>();
      ever(pCtrl.patients, (_) => _updateStats());
      _updateStats();
    }
  }

  void _updateStats() {
    final total = totalPatientsCount;
    final opd = opdPatientsCount;
    final ipd = ipdPatientsCount;
    stats.value = [
      DashboardStat(label: 'Total Patients', value: total, iconType: 'patients'),
      DashboardStat(label: 'OPD Patients', value: opd, iconType: 'opd'),
      DashboardStat(label: 'IPD Patients', value: ipd, iconType: 'ipd'),
    ];
  }

  void _loadData() {
    if (Get.isRegistered<AuthService>()) {
      final authService = Get.find<AuthService>();
      final name = authService.currentUser.value?.name;
      if (name != null && name.trim().isNotEmpty) {
        doctorName.value = name;
      }
    }
    if (Get.isRegistered<PatientController>()) {
      final pCtrl = Get.find<PatientController>();
      if (!pCtrl.isLoading.value && pCtrl.patients.isEmpty) {
        pCtrl.loadPatients();
      }
    }
    _updateStats();
  }

  Future<void> refreshDashboard() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      _loadData();
      if (Get.isRegistered<PatientController>()) {
        await Get.find<PatientController>().loadPatients(isRefresh: true);
        _updateStats();
      }
    } finally {
      isRefreshing.value = false;
    }
  }
}
