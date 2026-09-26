import 'package:get/get.dart';

import '../models/assessment/pradhana_karma_model.dart';
import '../services/api_service.dart';

/// Repository for Pradhana Karma API integration.
///
/// Endpoints:
/// - `GET /pradhana-karma/:patientId` (§5.1)
/// - `PUT /pradhana-karma/:patientId` (§5.2)
/// - `POST /pradhana-karma/:patientId/observations` (§5.3)
/// - `PUT /pradhana-karma/:patientId/observations/:day` (§5.4)
/// - `PUT /pradhana-karma/:patientId/complete` (§5.5)
class ApiPradhanaKarmaRepository {
  final ApiService _apiService;

  ApiPradhanaKarmaRepository({ApiService? apiService})
      : _apiService = apiService ??
            (Get.isRegistered<ApiService>()
                ? Get.find<ApiService>()
                : ApiService());

  static final Map<String, PradhanaKarmaModel?> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static final Map<String, Future<PradhanaKarmaModel?>> _inFlight = {};
  static const Duration _cacheDuration = Duration(seconds: 15);

  void clearCache([String? patientId]) {
    if (patientId != null) {
      _cache.remove(patientId);
      _cacheTime.remove(patientId);
      _inFlight.remove(patientId);
    } else {
      _cache.clear();
      _cacheTime.clear();
      _inFlight.clear();
    }
  }

  /// Helper for PUT requests
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

  /// Helper for POST requests
  Future<Response> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _apiService.post(path, body);
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

  /// 5.1 Fetches existing Pradhana Karma assessment for [patientId].
  ///
  /// Returns `null` if no record exists yet (HTTP 404).
  /// Throws [Exception] on server (5xx) or network errors.
  Future<PradhanaKarmaModel?> getPradhanaKarma(
    String patientId, {
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cache.containsKey(patientId) &&
        _cacheTime.containsKey(patientId) &&
        now.difference(_cacheTime[patientId]!) < _cacheDuration) {
      return _cache[patientId];
    }

    if (!forceRefresh && _inFlight.containsKey(patientId)) {
      return _inFlight[patientId]!;
    }

    final future = _fetchPradhanaKarma(patientId);
    _inFlight[patientId] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(patientId);
    }
  }

  Future<PradhanaKarmaModel?> _fetchPradhanaKarma(String patientId) async {
    final now = DateTime.now();
    final response = await _apiService.get('/pradhana-karma/$patientId');

    if (response.statusCode == 404) {
      _cache[patientId] = null;
      _cacheTime[patientId] = now;
      return null;
    }

    if (!response.isOk) {
      final msg = ApiService.extractErrorMessage(response);
      // If backend has a CastError or 500 for a corrupted document, return null gracefully
      if (response.statusCode == 500 && msg.contains('Cast to ObjectId failed')) {
        return null;
      }
      throw Exception(msg);
    }

    final body = response.body;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'];
      PradhanaKarmaModel? result;
      if (data is Map) {
        result = PradhanaKarmaModel.fromJson(Map<String, dynamic>.from(data));
      } else {
        result = PradhanaKarmaModel.fromJson(map);
      }
      _cache[patientId] = result;
      _cacheTime[patientId] = now;
      return result;
    }

    return null;
  }

  /// 5.2 Sets or updates the selected disease, basti pattern, formulation, and start date.
  /// Method & Endpoint: `PUT /api/pradhana-karma/:patientId`
  Future<Map<String, dynamic>?> initializeOrUpdatePradhanaKarma(
    String patientId, {
    required String diseaseId,
    required String bastiPatternCode,
    required String bastiFormulationId,
    String? customNotesOnDose,
    DateTime? startDate,
    String? treatmentStatus,
  }) async {
    final payload = <String, dynamic>{
      'diseaseId': diseaseId,
      'bastiPatternCode': bastiPatternCode.toUpperCase(),
      'bastiFormulationId': bastiFormulationId,
      if (customNotesOnDose != null && customNotesOnDose.isNotEmpty)
        'customNotesOnDose': customNotesOnDose,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (treatmentStatus != null && treatmentStatus.isNotEmpty)
        'treatmentStatus': treatmentStatus.toUpperCase(),
    };

    clearCache(patientId);
    final response = await _put('/pradhana-karma/$patientId', payload);
    final body = response.body;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    return null;
  }

  /// 5.3 Adds or updates an observation for a specific day of the treatment.
  /// Method & Endpoint: `POST /api/pradhana-karma/:patientId/observations`
  Future<List<dynamic>?> addDailyObservation(
    String patientId, {
    required int day,
    required String status,
    String? bastiType,
    String? dose,
    String? timeAdministered,
    String? pratyagamana,
    String? notes,
    Map<String, dynamic>? symptoms,
  }) async {
    clearCache(patientId);
    final payload = <String, dynamic>{
      'day': day,
      'status': status.toUpperCase(),
      if (bastiType != null && bastiType.isNotEmpty) 'bastiType': bastiType,
      if (dose != null && dose.isNotEmpty) 'dose': dose,
      if (timeAdministered != null && timeAdministered.isNotEmpty)
        'timeAdministered': timeAdministered,
      if (pratyagamana != null && pratyagamana.isNotEmpty)
        'pratyagamana': pratyagamana,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      ...?symptoms,
    };

    final response =
        await _post('/pradhana-karma/$patientId/observations', payload);
    final body = response.body;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      if (map['data'] is List) {
        return map['data'] as List<dynamic>;
      }
    }
    return null;
  }

  /// 5.4 Updates an existing observation for a specific day in the URL.
  /// Method & Endpoint: `PUT /api/pradhana-karma/:patientId/observations/:day`
  Future<Map<String, dynamic>?> updateDailyObservation(
    String patientId,
    int day,
    Map<String, dynamic> payload,
  ) async {
    clearCache(patientId);
    final response =
        await _put('/pradhana-karma/$patientId/observations/$day', payload);
    final body = response.body;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    return null;
  }

  /// 5.5 Marks the overall Pradhana Karma as completed in the patient's assessment status.
  /// Method & Endpoint: `PUT /api/pradhana-karma/:patientId/complete`
  Future<bool> completePradhanaKarma(String patientId) async {
    clearCache(patientId);
    final response = await _put('/pradhana-karma/$patientId/complete', {});
    return response.isOk;
  }
}
