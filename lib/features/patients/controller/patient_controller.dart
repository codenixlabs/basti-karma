import 'dart:io';
import 'package:get/get.dart';

import '../../../app/data/models/patient/patient_model.dart';
import '../../../app/data/repositories/api_patient_repository.dart';
import '../../../app/data/repositories/patient_repository.dart';

/// GetX controller managing the patient list and the currently selected patient.
///
/// Registered as a permanent singleton at app startup so the patient list
/// persists across tab/navigation changes.
///
/// Relationship:
///   PatientController.currentPatient.id
///       ↓
///   AssessmentController.patientId
///       ↓
///   TreatmentPlanController.currentPlan.patientId
class PatientController extends GetxController {
  final PatientRepository _repository;

  PatientController({PatientRepository? repository})
      : _repository = repository ??
            (Get.isRegistered<PatientRepository>()
                ? Get.find<PatientRepository>()
                : ApiPatientRepository());

  PatientRepository get repository => _repository;

  // ── Observable state ───────────────────────────────────────────────────────

  final patients = <PatientModel>[].obs;
  final currentPatient = Rxn<PatientModel>();
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isDownloadingPdf = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadPatients();
  }

  // ── Patient CRUD ───────────────────────────────────────────────────────────

  /// Loads patients from the repository.
  /// Uses [isRefresh] for pull-to-refresh without clearing existing content.
  Future<void> loadPatients({bool isRefresh = false}) async {
    if (isRefresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    hasError.value = false;
    errorMessage.value = '';

    try {
      final fetched = await _repository.getAllPatients();
      patients.value = fetched;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Adds a new patient to the repository and refreshes the list.
  /// Optionally uploads [photoFile]. Returns the new patient's id.
  Future<String> addPatient(PatientModel patient, {File? photoFile}) async {
    isLoading.value = true;
    try {
      final id = await _repository.addPatient(patient, photoFile: photoFile);
      await loadPatients(isRefresh: true);
      return id;
    } finally {
      isLoading.value = false;
    }
  }

  /// Updates an existing patient and refreshes the list.
  Future<void> updatePatient(PatientModel patient, {File? photoFile}) async {
    await _repository.updatePatient(patient, photoFile: photoFile);
    if (currentPatient.value?.id == patient.id) {
      currentPatient.value = patient;
    }
    await loadPatients(isRefresh: true);
  }

  /// Uploads or replaces the document/photo for [patientId] and updates UI state.
  Future<String?> uploadPatientPhoto(String patientId, File photoFile) async {
    final photoUrl = await _repository.uploadPatientPhoto(patientId, photoFile);
    await getPatient(patientId);
    return photoUrl;
  }

  /// Sets [patient] as the currently selected patient.
  /// Should be called before navigating to the assessment.
  void selectPatient(PatientModel patient) {
    currentPatient.value = patient;
  }

  /// Deletes the patient with [id] and refreshes the list.
  /// If the deleted patient was current, clears [currentPatient].
  Future<void> deletePatient(String id) async {
    await _repository.deletePatient(id);
    if (currentPatient.value?.id == id) {
      currentPatient.value = null;
    }
    await loadPatients(isRefresh: true);
  }

  /// Fetches the PatientModel for [id] from the backend API,
  /// updates [currentPatient] and the corresponding item in [patients]
  /// if found, and returns the patient.
  Future<PatientModel?> getPatient(String id) async {
    final patient = await _repository.getPatient(id);
    if (patient != null) {
      currentPatient.value = patient;
      final idx = patients.indexWhere((p) => p.id == id);
      if (idx != -1) {
        patients[idx] = patient;
      }
    }
    return patient;
  }

  /// Downloads the complete patient PDF report and saves it to local device storage.
  Future<File> downloadPatientPdfReport(
    String patientId, {
    String? defaultFileName,
    Duration? timeout,
  }) async {
    isDownloadingPdf.value = true;
    try {
      final file = await _repository.downloadPatientPdfReport(
        patientId,
        defaultFileName: defaultFileName,
        timeout: timeout,
      );
      return file;
    } finally {
      isDownloadingPdf.value = false;
    }
  }

  /// Clears all in-memory patient data. Used during logout and session resets
  /// to ensure no patient data leaks across user accounts.
  void clearData() {
    patients.clear();
    currentPatient.value = null;
    isLoading.value = false;
    isRefreshing.value = false;
    hasError.value = false;
    errorMessage.value = '';
  }
}
