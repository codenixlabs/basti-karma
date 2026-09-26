import 'package:get/get.dart';

import '../models/poorva_karma/poorva_karma_results.dart';
import '../services/api_service.dart';

/// Handles all Poorva Karma assessment API calls.
///
/// Endpoints:
/// - `PUT /poorva-karma/:id/niruha`
/// - `PUT /poorva-karma/:id/anuvasana`
/// - `PUT /poorva-karma/:id/pariksha`
/// - `PUT /poorva-karma/:id/agni`
/// - `PUT /poorva-karma/:id/kostha`
/// - `PUT /poorva-karma/:id/saama-nirama`
/// - `PUT /poorva-karma/:id/bala`
/// - `PUT /poorva-karma/:id/complete`
class ApiPoorvaKarmaRepository {
  final ApiService _apiService;

  ApiPoorvaKarmaRepository({ApiService? apiService})
      : _apiService = apiService ??
            (Get.isRegistered<ApiService>()
                ? Get.find<ApiService>()
                : ApiService());

  // ── Normalization helpers ───────────────────────────────────────────────────

  /// Normalizes Vaya UI labels or CRF values to backend enum: 'Bala' | 'Madhyam' | 'Vriddha'.
  ///
  /// Examples:
  /// - 'Madhyama (Adult 16–60)' -> 'Madhyam'
  /// - 'Madhyama' -> 'Madhyam'
  /// - 'Madhyam' -> 'Madhyam'
  /// - 'Bala (Child 0–16)' -> 'Bala'
  /// - 'Vriddha (Old 60+)' -> 'Vriddha'
  static String normalizeVaya(String value) {
    final v = value.toLowerCase().trim();
    if (v.contains('bala') || v.contains('child')) return 'Bala';
    if (v.contains('vriddha') || v.contains('old')) return 'Vriddha';
    if (v.contains('madhyam') || v.contains('adult')) return 'Madhyam';
    return value.isNotEmpty ? value : 'Madhyam';
  }

  /// Normalizes Pravara/Madhyama/Avara qualities to backend enums: 'Pravara' | 'Madhyam' | 'Avara'.
  static String normalizePma(String value) {
    final v = value.toLowerCase().trim();
    if (v.contains('pravar') || v.contains('sarvarasa')) return 'Pravara';
    if (v.contains('avar') || v.contains('ekarasa') || v.contains('poor')) return 'Avara';
    if (v.contains('madhyam') || v.contains('moderate')) return 'Madhyam';
    return value.isNotEmpty ? value : 'Madhyam';
  }

  /// Normalizes Satva UI labels or values to backend enum: 'Pravara' | 'Madhyam' | 'Avara'.
  static String normalizeSatva(String value) => normalizePma(value);

  /// Normalizes Prakriti labels to backend enum values: 'Vata', 'Pitta', 'Kapha', 'Vata-Pitta', etc.
  static String normalizePrakriti(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Vata';
    final cleaned = v
        .replaceAll(RegExp(r'\s+Pradhana', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+Prakriti', caseSensitive: false), '')
        .trim();
    return cleaned.isNotEmpty ? cleaned : 'Vata';
  }

  /// Normalizes Jihwa labels to backend enum values: 'Nirlipta', 'Ishat Lipta', 'Lipta'.
  static String normalizeJihwa(String value) {
    final v = value.toLowerCase().trim();
    if (v.contains('ishat')) return 'Ishat Lipta';
    if (v.contains('nirlipta') || v.contains('clean') || v.contains('moist')) return 'Nirlipta';
    if (v.contains('lipta') || v.contains('coated') || v.contains('dry') || v.contains('trembling')) return 'Lipta';
    return value.isNotEmpty ? value : 'Nirlipta';
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Performs a `PUT` and throws on non-OK responses.
  Future<Response> _put(String path, Map<String, dynamic> body) async {
    try {
      final response = await _apiService.put(path, body);
      if (!response.isOk) {
        final msg = ApiService.extractErrorMessage(response);
        throw Exception(msg);
      }
      return response;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  // ── Section saves ────────────────────────────────────────────────────────────

  /// Step 1 — Niruha eligibility (4 questions).
  ///
  /// Returns the backend-calculated [PoorvaEligibilityResult] containing `isEligible` and `message`.
  Future<PoorvaEligibilityResult> saveNiruha(
      String patientId, List<bool?> answers) async {
    final response = await _put('/poorva-karma/$patientId/niruha', {
      'recentInternalSnehanaEtc': answers[0] ?? false,
      'continuousVomitingEtc': answers[1] ?? false,
      'historyOfMiscarriageOrPregnant': answers[2] ?? false,
      'uncontrolledDiabetesHypertensionCkd': answers[3] ?? false,
    });
    final body = response.body is Map
        ? response.body as Map<String, dynamic>
        : <String, dynamic>{};
    return PoorvaEligibilityResult.fromJson(body);
  }

  /// Step 2 — Anuvasana eligibility (5 questions).
  ///
  /// Returns the backend-calculated [PoorvaEligibilityResult] containing `isEligible` and `message`.
  Future<PoorvaEligibilityResult> saveAnuvasana(
      String patientId, List<bool?> answers) async {
    final response = await _put('/poorva-karma/$patientId/anuvasana', {
      'hasAsthapanaContraindications': answers[0] ?? false,
      'impairedDigestion': answers[1] ?? false,
      'diarrhoeaOrHardBowel': answers[2] ?? false,
      'intestinalWormsPleehaEtc': answers[3] ?? false,
      'aruchiPoisoningCoryzaEtc': answers[4] ?? false,
    });
    final body = response.body is Map
        ? response.body as Map<String, dynamic>
        : <String, dynamic>{};
    return PoorvaEligibilityResult.fromJson(body);
  }

  /// Step 3 — Pariksha (10 dropdown fields auto-filled from CRF).
  Future<void> savePariksha(
    String patientId, {
    required String prakriti,
    required String sarataha,
    required String sanhanan,
    required String pramana,
    required String satva,
    required String satmya,
    required String aharaShakti,
    required String vyayamaShakti,
    required String vaya,
    required String jihwa,
  }) async {
    await _put('/poorva-karma/$patientId/pariksha', {
      'prakriti': normalizePrakriti(prakriti),
      'sarataha': normalizePma(sarataha),
      'sanhanan': normalizePma(sanhanan),
      'pramana': normalizePma(pramana),
      'satva': normalizeSatva(satva),
      'satmya': normalizePma(satmya),
      'aharaShakti': normalizePma(aharaShakti),
      'vyayamaShakti': normalizePma(vyayamaShakti),
      'vaya': normalizeVaya(vaya),
      'jihwa': normalizeJihwa(jihwa),
    });
  }

  /// Normalizes Bala labels or values to backend enum: 'Pravara' | 'Madhyama' | 'Avara'.
  static String normalizeBala(String value) {
    final v = value.toLowerCase().trim();
    if (v.contains('pravar')) return 'Pravara';
    if (v.contains('avar')) return 'Avara';
    return 'Madhyama';
  }

  /// Step 4 — Agni assessment (3 numeric scores, computed from hidden scoring, plus optional recommendedDrugs).
  ///
  /// Returns the backend-calculated [AgniAssessmentResult] containing `totalScore` and `agniType`.
  Future<AgniAssessmentResult> saveAgni(
    String patientId, {
    required int jaranShaktiScore,
    required int abhyavaharanaShaktiScore,
    required int ruchiScore,
    String? recommendedDrugs,
  }) async {
    final payload = <String, dynamic>{
      'jaranShaktiScore': jaranShaktiScore,
      'abhyavaharanaShaktiScore': abhyavaharanaShaktiScore,
      'ruchiScore': ruchiScore,
      if (recommendedDrugs != null && recommendedDrugs.isNotEmpty)
        'recommendedDrugs': recommendedDrugs,
    };
    final response = await _put('/poorva-karma/$patientId/agni', payload);
    final body = response.body is Map
        ? response.body as Map<String, dynamic>
        : <String, dynamic>{};
    return AgniAssessmentResult.fromJson(body);
  }

  /// Step 5 — Kostha assessment (5 questions, each answered as a score 1–3).
  ///
  /// Returns the backend-calculated [KosthaAssessmentResult] containing `totalScore` and `kosthaType`.
  Future<KosthaAssessmentResult> saveKostha(
      String patientId, List<int?> answers) async {
    final response = await _put('/poorva-karma/$patientId/kostha', {
      'bowelFrequencyScore': answers[0] ?? 1,
      'consistencyScore': answers[1] ?? 1,
      'urgencyScore': answers[2] ?? 1,
      'patientExperienceScore': answers[3] ?? 1,
      'foodHabitChangeScore': answers[4] ?? 1,
    });
    final body = response.body is Map
        ? response.body as Map<String, dynamic>
        : <String, dynamic>{};
    return KosthaAssessmentResult.fromJson(body);
  }

  /// Step 6a — Saama/Nirama lakshana (10 yes/no symptoms).
  ///
  /// Returns the backend-calculated [SaamaNiramaResult] containing `deepanPachanaRequired`.
  Future<SaamaNiramaResult> saveSaamaNirama(
      String patientId, List<bool?> answers) async {
    final response = await _put('/poorva-karma/$patientId/saama-nirama', {
      'srotorodha': answers[0] ?? false,
      'balabhransha': answers[1] ?? false,
      'gaurava': answers[2] ?? false,
      'alasya': answers[3] ?? false,
      'anilaMudhata': answers[4] ?? false,
      'apaki': answers[5] ?? false,
      'nishthivana': answers[6] ?? false,
      'malaSanga': answers[7] ?? false,
      'aruchi': answers[8] ?? false,
      'klama': answers[9] ?? false,
    });
    final body = response.body is Map
        ? response.body as Map<String, dynamic>
        : <String, dynamic>{};
    return SaamaNiramaResult.fromJson(body);
  }

  /// Step 6b — Bala assessment.
  ///
  /// [bala] must be one of `'Pravara'`, `'Madhyam'`, `'Avara'`.
  Future<String> saveBala(String patientId, String bala) async {
    final normalized = normalizeBala(bala);
    final response =
        await _put('/poorva-karma/$patientId/bala', {'bala': normalized});
    final body = response.body is Map
        ? response.body as Map<String, dynamic>
        : <String, dynamic>{};
    return body['bala'] as String? ?? normalized;
  }

  /// Marks the full Poorva Karma assessment as complete on the backend.
  Future<bool> completePoorvaKarma(String patientId) async {
    final response = await _put('/poorva-karma/$patientId/complete', {});
    return response.isOk;
  }

  /// Retrieves the entire saved Poorva Karma assessment for the specified patient.
  /// Method & Endpoint: `GET /api/poorva-karma/:patientId`
  Future<Map<String, dynamic>?> getPoorvaKarma(String patientId) async {
    try {
      final response = await _apiService.get('/poorva-karma/$patientId');
      if (response.isOk && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body as Map);
        if (body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
        return body;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
