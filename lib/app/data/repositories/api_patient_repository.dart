import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/patient/patient_model.dart';
import '../services/api_service.dart';
import 'patient_repository.dart';

/// Concrete implementation of [PatientRepository] backed by the live backend API.
///
/// Communicates with:
/// - `GET /patients`
/// - `GET /patients/:id`
/// - `POST /patients`
/// - `PUT /patients/:id`
/// - `DELETE /patients/:id`
///
/// Automatically sends `Authorization: Bearer <token>` through [ApiService].
class ApiPatientRepository implements PatientRepository {
  final ApiService _apiService;

  ApiPatientRepository({ApiService? apiService})
    : _apiService =
          apiService ??
          (Get.isRegistered<ApiService>()
              ? Get.find<ApiService>()
              : ApiService());

  @visibleForTesting
  Map<String, dynamic> patientToBackendPayload(PatientModel patient) =>
      _patientToBackendPayload(patient);

  /// Maps [PatientModel] to the backend's expected JSON payload according to README §2.1
  /// and ensures all CRF sections (demographics, hospitalInfo, ClinicalInformation,
  /// personalHistory, generalExamination, rogiPariksha, femaleHistory, investigations, treatment)
  /// are included and sent to the backend.
  Map<String, dynamic> _patientToBackendPayload(PatientModel patient) {
    final demographics = <String, dynamic>{
      'fullName': patient.name,
      'age': patient.age,
      'sex': patient.sex,
    };
    final phoneVal = patient.phoneNo ?? patient.phone;
    if (phoneVal != null && phoneVal.isNotEmpty) {
      demographics['phoneNo'] = phoneVal;
    }
    if (patient.religion != null && patient.religion!.isNotEmpty) {
      demographics['religion'] = patient.religion;
    }
    if (patient.occupation != null && patient.occupation!.isNotEmpty) {
      demographics['occupation'] = patient.occupation;
    }
    if (patient.maritalStatus != null && patient.maritalStatus!.isNotEmpty) {
      demographics['maritalStatus'] = patient.maritalStatus;
    }
    if (patient.address != null && patient.address!.isNotEmpty) {
      demographics['address'] = patient.address;
    }

    final hospitalInfo = <String, dynamic>{
      'admissionType': patient.admissionType.isNotEmpty
          ? patient.admissionType
          : 'OPD',
    };
    final opdVal = patient.opdNumber ?? patient.opdNo;
    if (opdVal != null && opdVal.isNotEmpty) {
      hospitalInfo['opdNumber'] = opdVal;
    }
    final ipdVal = patient.ipdNumber ?? patient.ipdNo;
    if (ipdVal != null && ipdVal.isNotEmpty) {
      hospitalInfo['ipdNumber'] = ipdVal;
    }
    final diseaseSel =
        patient.clinicalDiseaseSelection ??
        (patient.diagnosis.isNotEmpty ? patient.diagnosis : null);
    if (diseaseSel != null && diseaseSel.isNotEmpty) {
      hospitalInfo['clinicalDiseaseSelection'] = diseaseSel;
    }
    final customDiag =
        patient.customDiagnosis ??
        (patient.diagnosis.isNotEmpty ? patient.diagnosis : null);
    if (customDiag != null && customDiag.isNotEmpty) {
      hospitalInfo['customDiagnosis'] = customDiag;
    }

    final clinicalInformation = <String, dynamic>{};
    final chiefComp =
        patient.chiefComplaints ??
        (patient.diagnosis.isNotEmpty ? patient.diagnosis : null);
    if (chiefComp != null && chiefComp.isNotEmpty) {
      clinicalInformation['chiefComplaints'] = chiefComp;
    }
    if (patient.historyOfPresentIllness != null &&
        patient.historyOfPresentIllness!.isNotEmpty) {
      clinicalInformation['historyOfPresentIllness'] =
          patient.historyOfPresentIllness;
    }
    if (patient.historyOfPastIllness != null &&
        patient.historyOfPastIllness!.isNotEmpty) {
      clinicalInformation['historyOfPastIllness'] =
          patient.historyOfPastIllness;
    }
    if (patient.familyHistory != null && patient.familyHistory!.isNotEmpty) {
      clinicalInformation['familyHistory'] = patient.familyHistory;
    }

    final personalHistory = <String, dynamic>{};
    if (patient.ahara != null && patient.ahara!.isNotEmpty) {
      final normAhara = PatientModel.normalizeAharaToBackend(patient.ahara);
      personalHistory['ahara'] = normAhara;
    }
    if (patient.vihara != null && patient.vihara!.isNotEmpty) {
      personalHistory['vihara'] = patient.vihara;
    }
    if (patient.addiction != null &&
        patient.addiction!.isNotEmpty &&
        patient.addiction != 'No / NA' &&
        patient.addiction != 'NA' &&
        patient.addiction != 'No') {
      personalHistory['addiction'] = patient.addiction;
    } else {
      personalHistory['addiction'] = 'None';
    }
    if (patient.bowelHabits != null && patient.bowelHabits!.isNotEmpty) {
      personalHistory['bowelHabits'] = patient.bowelHabits;
    }
    if (patient.nidra != null && patient.nidra!.isNotEmpty) {
      personalHistory['nidra'] = patient.nidra;
    }
    if (patient.urineFrequency != null && patient.urineFrequency!.isNotEmpty) {
      personalHistory['urineFrequency'] = patient.urineFrequency;
    }
    if (patient.bloodGroup != null && patient.bloodGroup!.isNotEmpty) {
      personalHistory['bloodGroup'] = patient.bloodGroup;
    }

    final generalExamination = <String, dynamic>{};
    if (patient.bp != null && patient.bp!.isNotEmpty) {
      generalExamination['bp'] = patient.bp;
    }
    if (patient.rr != null && patient.rr!.isNotEmpty) {
      generalExamination['rr'] = patient.rr;
    }
    if (patient.hr != null && patient.hr!.isNotEmpty) {
      generalExamination['hr'] = patient.hr;
    }
    if (patient.temperature != null && patient.temperature!.isNotEmpty) {
      generalExamination['temperature'] = patient.temperature;
    }
    if (patient.weight != null) {
      generalExamination['weight'] = patient.weight;
    }
    if (patient.height != null) {
      generalExamination['height'] = patient.height;
    }
    if (patient.bmi != null) {
      generalExamination['bmi'] = patient.bmi;
    }

    // Female History (CRF Step 5)
    final femaleHistory = <String, dynamic>{};
    if (patient.menstrualHistory != null &&
        patient.menstrualHistory!.trim().isNotEmpty) {
      femaleHistory['menstrualHistory'] = patient.menstrualHistory!.trim();
    }
    if (patient.numberOfDeliveries != null) {
      femaleHistory['numberOfDeliveries'] = patient.numberOfDeliveries;
    }
    if (patient.abortion != null) {
      femaleHistory['abortion'] = patient.abortion;
    }
    if (patient.surgicalIntervention != null &&
        patient.surgicalIntervention!.trim().isNotEmpty) {
      femaleHistory['surgicalIntervention'] = patient.surgicalIntervention!
          .trim();
    }

    // Rogi Pariksha (CRF Step 7) - normalized to match backend Mongoose enums
    final rogiPariksha = <String, dynamic>{};
    if (patient.prakriti.trim().isNotEmpty) {
      rogiPariksha['prakriti'] = normalizePrakriti(patient.prakriti);
    }
    if (patient.sarataha.trim().isNotEmpty) {
      rogiPariksha['sarataha'] = normalizePma(patient.sarataha);
    }
    if (patient.sanhanan.trim().isNotEmpty) {
      rogiPariksha['sanhanan'] = normalizePma(patient.sanhanan);
    }
    if (patient.pramana.trim().isNotEmpty) {
      rogiPariksha['pramana'] = normalizePma(patient.pramana);
    }
    if (patient.satva.trim().isNotEmpty) {
      rogiPariksha['satva'] = normalizePma(patient.satva);
    }
    if (patient.satmya.trim().isNotEmpty) {
      rogiPariksha['satmya'] = normalizePma(patient.satmya);
    }
    if (patient.aharaShakti.trim().isNotEmpty) {
      rogiPariksha['aharaShakti'] = normalizePma(patient.aharaShakti);
    }
    if (patient.vyayamaShakti.trim().isNotEmpty) {
      rogiPariksha['vyayamaShakti'] = normalizePma(patient.vyayamaShakti);
    }
    if (patient.vaya.trim().isNotEmpty) {
      rogiPariksha['vaya'] = normalizeVaya(patient.vaya);
    }
    if (patient.jihwa.trim().isNotEmpty) {
      rogiPariksha['jihwa'] = normalizeJihwa(patient.jihwa);
    }
    if (patient.desha.trim().isNotEmpty) {
      rogiPariksha['desha'] = normalizeDesha(patient.desha);
    }

    // Investigations (CRF Step 8)
    final investigations = <String, dynamic>{};
    if (patient.pathologicalRadiological != null &&
        patient.pathologicalRadiological!.trim().isNotEmpty) {
      investigations['pathologicalRadiological'] = patient
          .pathologicalRadiological!
          .trim();
    }
    if (patient.photoUrl != null && patient.photoUrl!.isNotEmpty) {
      investigations['photoUrl'] = patient.photoUrl!;
    }
    if (patient.treatmentGiven != null &&
        patient.treatmentGiven!.trim().isNotEmpty) {
      investigations['treatmentGiven'] = patient.treatmentGiven!.trim();
    }

    final treatment =
        (patient.treatmentGiven != null &&
            patient.treatmentGiven!.trim().isNotEmpty)
        ? patient.treatmentGiven!.trim()
        : 'Basti';

    final payload = <String, dynamic>{
      'demographics': demographics,
      'hospitalInfo': hospitalInfo,
      if (clinicalInformation.isNotEmpty)
        'ClinicalInformation': clinicalInformation,
      if (personalHistory.isNotEmpty) 'personalHistory': personalHistory,
      if (generalExamination.isNotEmpty)
        'generalExamination': generalExamination,
      if (femaleHistory.isNotEmpty) 'femaleHistory': femaleHistory,
      if (rogiPariksha.isNotEmpty) 'rogiPariksha': rogiPariksha,
      if (investigations.isNotEmpty) 'investigations': investigations,
      'treatment': treatment,
    };

    return payload;
  }

  // ── Rogi Pariksha Normalizers for Backend Mongoose Schema ─────────────
  static String normalizeVaya(String value) {
    final v = value.toLowerCase().trim();
    if (v.contains('bala') || v.contains('child')) return 'Bala';
    if (v.contains('vriddha') || v.contains('old')) return 'Vriddha';
    if (v.contains('madhyam') || v.contains('adult')) return 'Madhyam';
    return value.isNotEmpty ? value : 'Madhyam';
  }

  static String normalizePma(String value) {
    final v = value.toLowerCase().trim();
    if (v.contains('pravar') ||
        v.contains('sarvarasa') ||
        v.contains('excellent')) {
      return 'Pravara';
    }
    if (v.contains('avar') || v.contains('ekarasa') || v.contains('poor')) {
      return 'Avara';
    }
    if (v.contains('madhyam') || v.contains('moderate')) return 'Madhyam';
    return value.isNotEmpty ? value : 'Madhyam';
  }

  static String normalizePrakriti(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Vata';
    final cleaned = v
        .replaceAll(RegExp(r'\s+Pradhana', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+Prakriti', caseSensitive: false), '')
        .trim();
    return cleaned.isNotEmpty ? cleaned : 'Vata';
  }

  static String normalizeJihwa(String value) {
    final v = value.toLowerCase().trim();
    if (v.contains('ishat')) return 'Ishat Lipta';
    if (v.contains('nirlipta') || v.contains('clean') || v.contains('moist')) {
      return 'Nirlipta';
    }
    if (v.contains('lipta') ||
        v.contains('coated') ||
        v.contains('dry') ||
        v.contains('trembling')) {
      return 'Lipta';
    }
    return value.isNotEmpty ? value : 'Nirlipta';
  }

  static String normalizeDesha(String value) {
    final v = value.toLowerCase().trim();
    if (v.contains('anupa') || v.contains('marshy')) return 'Anupa';
    if (v.contains('jangala') || v.contains('desert') || v.contains('dry')) {
      return 'Jangala';
    }
    if (v.contains('sadharan') || v.contains('normal')) return 'Sadharan';
    return value.isNotEmpty ? value : 'Sadharan';
  }

  @override
  Future<String?> uploadPatientPhoto(String patientId, File photoFile) async {
    final fileName = photoFile.path.split(RegExp(r'[/\\]')).last;
    final form = FormData({
      'photo': MultipartFile(photoFile, filename: fileName),
    });

    final response = await _apiService.put('/patients/$patientId', form);
    if (response.isOk && response.body is Map) {
      final data = response.body['data'];
      if (data is Map) {
        final photoUrl =
            data['investigations']?['photoUrl'] ??
            data['photoUrl'] ??
            data['photo'];
        return photoUrl?.toString();
      }
      return null;
    }

    final errorMsg = ApiService.extractErrorMessage(response);
    throw Exception(errorMsg);
  }

  @override
  Future<String> addPatient(PatientModel patient, {File? photoFile}) async {
    final payload = _patientToBackendPayload(patient);
    final response = await _apiService.post('/patients', payload);

    if (response.isOk && response.body is Map) {
      final data = response.body['data'];
      if (data is Map && data['_id'] != null) {
        final id = data['_id'].toString();
        if (photoFile != null) {
          try {
            await uploadPatientPhoto(id, photoFile);
          } catch (_) {
            // Patient was created; photo upload can be retried
          }
        }
        return id;
      }
    }

    final errorMsg = ApiService.extractErrorMessage(response);
    throw Exception(errorMsg);
  }

  @override
  Future<List<PatientModel>> getAllPatients() async {
    final response = await _apiService.get('/patients');

    if (response.isOk && response.body is Map) {
      final data = response.body['data'];
      if (data is List) {
        final list = data
            .whereType<Map>()
            .map(
              (item) => PatientModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
        // Sort newest first by creation date
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }
    }

    final errorMsg = ApiService.extractErrorMessage(response);
    throw Exception(errorMsg);
  }

  @override
  Future<PatientModel?> getPatient(String id) async {
    final response = await _apiService.get('/patients/$id');

    if (response.isOk && response.body is Map) {
      final data = response.body['data'];
      if (data is Map) {
        return PatientModel.fromJson(Map<String, dynamic>.from(data));
      }
    }

    if (response.statusCode == 404) {
      return null;
    }

    final errorMsg = ApiService.extractErrorMessage(response);
    throw Exception(errorMsg);
  }

  @override
  Future<void> updatePatient(PatientModel patient, {File? photoFile}) async {
    final payload = _patientToBackendPayload(patient);
    final response = await _apiService.put('/patients/${patient.id}', payload);

    if (!response.isOk) {
      final errorMsg = ApiService.extractErrorMessage(response);
      throw Exception(errorMsg);
    }

    if (photoFile != null) {
      await uploadPatientPhoto(patient.id, photoFile);
    }
  }

  @override
  Future<void> deletePatient(String id) async {
    final response = await _apiService.delete('/patients/$id');

    if (!response.isOk && response.statusCode != 404) {
      final errorMsg = ApiService.extractErrorMessage(response);
      throw Exception(errorMsg);
    }
  }

  @override
  Future<File> downloadPatientPdfReport(
    String patientId, {
    String? defaultFileName,
    Duration? timeout,
  }) async {
    return _apiService.downloadPatientPdf(
      patientId,
      defaultFileName: defaultFileName,
      timeout: timeout ?? ApiService.defaultPdfTimeout,
    );
  }
}
