import 'dart:convert';
import 'package:get/get.dart';

import '../models/master/basti_formulation_model.dart';
import '../models/master/basti_option_model.dart';
import '../models/master/basti_pattern_model.dart';
import '../models/master/disease_model.dart';
import '../models/master/dose_rule_model.dart';
import '../services/api_service.dart';

/// Repository for Clinical Master Data API integration.
///
/// Communicates with:
/// - `GET /master/diseases`
/// - `GET /master/formulations/:disease_id` (Passing disease string `id`, e.g. `'dis_arsha'`)
/// - `GET /master/dose-rules`
/// - `GET /master/patterns`
///
/// Features:
/// - In-memory caching for master data across sessions
/// - Graceful empty response handling
/// - Zero local JSON fallback, keeping backend as sole persistent truth
class ApiMasterRepository {
  final ApiService _apiService;

  // ── In-Memory Caches ────────────────────────────────────────────────────────
  static List<DiseaseModel>? _cachedDiseases;
  static final Map<String, List<DiseaseModel>> _cachedDiseasesByPatient = {};
  static final Map<String, List<BastiFormulationModel>> _cachedFormulationsByDisease = {};
  static List<DoseRuleModel>? _cachedDoseRules;
  static List<BastiPatternModel>? _cachedPatterns;

  static Future<List<DiseaseModel>>? _inFlightDiseases;
  static final Map<String, Future<List<DiseaseModel>>> _inFlightDiseasesByPatient = {};
  static final Map<String, Future<List<BastiFormulationModel>>> _inFlightFormulations = {};
  static Future<List<DoseRuleModel>>? _inFlightDoseRules;
  static Future<List<BastiPatternModel>>? _inFlightPatterns;

  ApiMasterRepository({ApiService? apiService})
      : _apiService = apiService ??
            (Get.isRegistered<ApiService>()
                ? Get.find<ApiService>()
                : ApiService());

  /// Clears in-memory cache.
  void clearCache([String? patientId]) {
    if (patientId != null && patientId.trim().isNotEmpty) {
      final pKey = patientId.trim();
      _cachedDiseasesByPatient.remove(pKey);
      _cachedFormulationsByDisease.removeWhere((k, _) => k.endsWith(':$pKey'));
    } else {
      _cachedDiseases = null;
      _cachedDiseasesByPatient.clear();
      _cachedFormulationsByDisease.clear();
      _cachedDoseRules = null;
      _cachedPatterns = null;
      _inFlightDiseases = null;
      _inFlightDiseasesByPatient.clear();
      _inFlightFormulations.clear();
      _inFlightDoseRules = null;
      _inFlightPatterns = null;
    }
  }

  List<DiseaseModel>? get cachedDiseases => _cachedDiseases;

  // ── JSON Normalization Helpers ──────────────────────────────────────────────
  static List<dynamic> _extractDataList(dynamic responseBody) {
    dynamic raw = responseBody;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }
    if (raw is Map) {
      final data = raw['data'];
      if (data is List) {
        return data;
      }
      return const [];
    } else if (raw is List) {
      return raw;
    }
    return const [];
  }

  static Map<String, dynamic> _toMap(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item;
    } else if (item is Map) {
      return Map<String, dynamic>.from(item);
    }
    return <String, dynamic>{};
  }

  // ── Diseases ───────────────────────────────────────────────────────────────

  /// Fetches all diseases from `GET /master/diseases`.
  /// Passing optional [patientId] returns standard diseases plus custom diseases for this patient (§8.2).
  Future<List<DiseaseModel>> getDiseases({
    String? patientId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = (patientId != null && patientId.trim().isNotEmpty)
        ? patientId.trim()
        : 'global';

    if (!forceRefresh && _cachedDiseasesByPatient.containsKey(cacheKey)) {
      ApiService.log('📦 [ApiMasterRepository] Using ${_cachedDiseasesByPatient[cacheKey]!.length} cached diseases for key: $cacheKey');
      return _cachedDiseasesByPatient[cacheKey]!;
    }

    if (!forceRefresh && _cachedDiseases != null && cacheKey == 'global') {
      ApiService.log('📦 [ApiMasterRepository] Using ${_cachedDiseases!.length} cached diseases');
      return _cachedDiseases!;
    }

    if (!forceRefresh && _inFlightDiseasesByPatient.containsKey(cacheKey)) {
      return _inFlightDiseasesByPatient[cacheKey]!;
    }

    if (!forceRefresh && _inFlightDiseases != null && cacheKey == 'global') {
      return _inFlightDiseases!;
    }

    final future = _fetchDiseases(patientId: patientId);
    _inFlightDiseasesByPatient[cacheKey] = future;
    if (cacheKey == 'global') {
      _inFlightDiseases = future;
    }
    try {
      return await future;
    } finally {
      _inFlightDiseasesByPatient.remove(cacheKey);
      if (cacheKey == 'global') {
        _inFlightDiseases = null;
      }
    }
  }

  Future<List<DiseaseModel>> _fetchDiseases({String? patientId}) async {
    final query = <String, dynamic>{};
    if (patientId != null && patientId.trim().isNotEmpty) {
      query['patientId'] = patientId.trim();
    }

    final response = await _apiService.get(
      '/master/diseases',
      query: query.isNotEmpty ? query : null,
    );
    if (!response.isOk) {
      final msg = ApiService.extractErrorMessage(response);
      throw Exception(msg.isNotEmpty ? msg : 'Failed to load diseases (${response.statusCode})');
    }

    final list = _extractDataList(response.body);
    final diseases = list
        .map((e) => DiseaseModel.fromJson(_toMap(e)))
        .toList();

    diseases.sort(
      (a, b) => a.displayLabel.trim().toLowerCase().compareTo(b.displayLabel.trim().toLowerCase()),
    );

    final unmod = List<DiseaseModel>.unmodifiable(diseases);
    final cacheKey = (patientId != null && patientId.trim().isNotEmpty)
        ? patientId.trim()
        : 'global';
    _cachedDiseasesByPatient[cacheKey] = unmod;
    _cachedDiseases = unmod;
    ApiService.log('📥 [ApiMasterRepository] Parsed and cached ${diseases.length} diseases (key: $cacheKey)');
    return unmod;
  }

  /// Adds a custom disease for a patient (§8.1).
  /// Endpoint: `POST /master/custom-disease`.
  Future<DiseaseModel> addCustomDisease({
    required String name,
    required String patientId,
  }) async {
    final trimmedName = name.trim();
    final trimmedPatientId = patientId.trim();

    final response = await _apiService.post(
      '/master/custom-disease',
      {
        'name': trimmedName,
        'patientId': trimmedPatientId,
      },
    );

    if (!response.isOk) {
      final msg = ApiService.extractErrorMessage(response);
      throw Exception(
        msg.isNotEmpty ? msg : 'Failed to add custom disease (${response.statusCode})',
      );
    }

    final resBody = response.body;
    Map<String, dynamic> dataMap;
    if (resBody is Map && resBody['data'] is Map) {
      dataMap = _toMap(resBody['data']);
    } else if (resBody is Map<String, dynamic>) {
      dataMap = resBody;
    } else {
      throw Exception('Invalid response format for custom disease');
    }

    final created = DiseaseModel.fromJson(dataMap);

    // Update patient cache
    final cacheKey = trimmedPatientId;
    final currentList = _cachedDiseasesByPatient[cacheKey] ?? _cachedDiseases ?? [];
    final updatedList = List<DiseaseModel>.from(currentList)
      ..removeWhere((d) => d.id == created.id)
      ..add(created)
      ..sort((a, b) => a.displayLabel.trim().toLowerCase().compareTo(b.displayLabel.trim().toLowerCase()));

    final unmod = List<DiseaseModel>.unmodifiable(updatedList);
    _cachedDiseasesByPatient[cacheKey] = unmod;
    _cachedDiseases = unmod;

    return created;
  }

  /// Finds a disease by its string `id` or MongoDB `_id` or name.
  Future<DiseaseModel?> getDiseaseById(
    String id, {
    String? patientId,
    bool forceRefresh = false,
  }) async {
    final diseases = await getDiseases(patientId: patientId, forceRefresh: forceRefresh);
    try {
      final target = id.trim().toLowerCase();
      return diseases.firstWhere(
        (d) =>
            d.id.toLowerCase() == target ||
            (d.mongoId != null && d.mongoId!.toLowerCase() == target) ||
            d.name.toLowerCase() == target,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Formulations ───────────────────────────────────────────────────────────

  /// Resolves a disease identifier into its backend query slug (e.g. `'dis_ajirna'`).
  String resolveDiseaseSlug(String diseaseId, {String? diseaseName}) {
    final trimmedId = diseaseId.trim();
    if (trimmedId.startsWith('dis_')) {
      return trimmedId;
    }
    // If diseaseName is provided, slugify it
    if (diseaseName != null && diseaseName.trim().isNotEmpty) {
      return DiseaseModel.slugify(diseaseName);
    }
    // Check in _cachedDiseases
    if (_cachedDiseases != null) {
      final target = trimmedId.toLowerCase();
      final match = _cachedDiseases!.firstWhereOrNull(
        (d) =>
            d.id.toLowerCase() == target ||
            (d.mongoId != null && d.mongoId!.toLowerCase() == target) ||
            d.name.toLowerCase() == target,
      );
      if (match != null) {
        return match.id.startsWith('dis_') ? match.id : DiseaseModel.slugify(match.name);
      }
    }
    // If it's a custom ID with custom_ prefix, check if it contains a name
    if (trimmedId.startsWith('custom_')) {
      return trimmedId;
    }
    // If it's not 24-hex, slugify it directly
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(trimmedId)) {
      return DiseaseModel.slugify(trimmedId);
    }
    return trimmedId;
  }

  /// Fetches formulations for [diseaseId] (e.g. `'dis_arsha'` or `'dis_ajirna'`).
  ///
  /// CRITICAL: [diseaseId] MUST be the disease string `id`, NOT MongoDB `_id`.
  /// Automatically resolves MongoDB `_id` or custom IDs to proper slug if [diseaseName] is supplied.
  /// Passing [patientId] includes any custom formulations created for that disease and patient (§8.3).
  Future<List<BastiFormulationModel>> getFormulationsByDisease(
    String diseaseId, {
    String? diseaseName,
    String? patientId,
    bool forceRefresh = false,
  }) async {
    final slug = resolveDiseaseSlug(diseaseId, diseaseName: diseaseName);
    final pKey = patientId != null && patientId.trim().isNotEmpty ? patientId.trim() : '';
    final slugKey = pKey.isNotEmpty ? '$slug:$pKey' : slug;
    final diseaseKey = pKey.isNotEmpty ? '$diseaseId:$pKey' : diseaseId;

    if (!forceRefresh) {
      if (_cachedFormulationsByDisease.containsKey(slugKey)) {
        return _cachedFormulationsByDisease[slugKey]!;
      }
      if (_cachedFormulationsByDisease.containsKey(diseaseKey)) {
        return _cachedFormulationsByDisease[diseaseKey]!;
      }
      if (_inFlightFormulations.containsKey(slugKey)) {
        return _inFlightFormulations[slugKey]!;
      }
      if (_inFlightFormulations.containsKey(diseaseKey)) {
        return _inFlightFormulations[diseaseKey]!;
      }
    }

    final future = _fetchFormulationsByDisease(slug, diseaseId, diseaseName, patientId: patientId);
    _inFlightFormulations[slugKey] = future;
    _inFlightFormulations[diseaseKey] = future;
    try {
      return await future;
    } finally {
      _inFlightFormulations.remove(slugKey);
      _inFlightFormulations.remove(diseaseKey);
    }
  }

  Future<List<BastiFormulationModel>> _fetchFormulationsByDisease(
    String slug,
    String diseaseId,
    String? diseaseName, {
    String? patientId,
  }) async {
    final query = <String, dynamic>{};
    if (patientId != null && patientId.trim().isNotEmpty) {
      query['patientId'] = patientId.trim();
    }
    final queryMap = query.isNotEmpty ? query : null;

    // Try primary query with resolved slug
    var response = await _apiService.get('/master/formulations/$slug', query: queryMap);

    // If 404 and slug differs from original diseaseId, try fallback with diseaseId
    if (response.statusCode == 404 && slug != diseaseId && !diseaseId.startsWith('custom_')) {
      response = await _apiService.get('/master/formulations/$diseaseId', query: queryMap);
    }

    // If still 404 and diseaseName is available and different, try slugifying diseaseName
    if (response.statusCode == 404 && diseaseName != null && diseaseName.trim().isNotEmpty) {
      final nameSlug = DiseaseModel.slugify(diseaseName);
      if (nameSlug != slug && nameSlug != diseaseId) {
        response = await _apiService.get('/master/formulations/$nameSlug', query: queryMap);
      }
    }

    final pKey = patientId != null && patientId.trim().isNotEmpty ? patientId.trim() : '';
    final slugKey = pKey.isNotEmpty ? '$slug:$pKey' : slug;
    final diseaseKey = pKey.isNotEmpty ? '$diseaseId:$pKey' : diseaseId;

    if (response.statusCode == 404) {
      // Gracefully return empty list when no formulations exist (e.g. newly created custom disease)
      _cachedFormulationsByDisease[slugKey] = const [];
      _cachedFormulationsByDisease[diseaseKey] = const [];
      return const [];
    }

    if (!response.isOk) {
      final msg = ApiService.extractErrorMessage(response);
      throw Exception(
        msg.isNotEmpty
            ? msg
            : 'Failed to load formulations for $diseaseId (${response.statusCode})',
      );
    }

    final list = _extractDataList(response.body);
    final formulations = list
        .map((e) => BastiFormulationModel.fromJson(_toMap(e)))
        .toList();

    final unmod = List<BastiFormulationModel>.unmodifiable(formulations);
    _cachedFormulationsByDisease[slugKey] = unmod;
    _cachedFormulationsByDisease[diseaseKey] = unmod;
    return unmod;
  }

  /// Adds a custom formulation directly under the selected disease and patient (§8.4).
  /// Endpoint: `POST /master/custom-formulation`.
  Future<BastiFormulationModel> addCustomFormulation({
    required String name,
    required String diseaseId,
    required String patientId,
    String? rawName,
    String? bastiType,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'diseaseId': diseaseId.trim(),
      'patientId': patientId.trim(),
    };
    if (rawName != null && rawName.trim().isNotEmpty) {
      body['rawName'] = rawName.trim();
    }
    if (bastiType != null && bastiType.trim().isNotEmpty) {
      body['bastiType'] = bastiType.trim();
    }

    final response = await _apiService.post(
      '/master/custom-formulation',
      body,
    );

    if (!response.isOk) {
      final msg = ApiService.extractErrorMessage(response);
      throw Exception(
        msg.isNotEmpty ? msg : 'Failed to add custom formulation (${response.statusCode})',
      );
    }

    final resBody = response.body;
    Map<String, dynamic> dataMap;
    if (resBody is Map && resBody['data'] is Map) {
      dataMap = _toMap(resBody['data']);
    } else if (resBody is Map<String, dynamic>) {
      dataMap = resBody;
    } else {
      throw Exception('Invalid response format for custom formulation');
    }

    final created = BastiFormulationModel.fromJson(dataMap);

    // Invalidate caches
    final slug = resolveDiseaseSlug(diseaseId);
    final pKey = patientId.trim();
    _cachedFormulationsByDisease.remove(slug);
    _cachedFormulationsByDisease.remove(diseaseId);
    _cachedFormulationsByDisease.remove('$slug:$pKey');
    _cachedFormulationsByDisease.remove('$diseaseId:$pKey');

    return created;
  }

  /// Fetches custom formulations created by the doctor (§8.5).
  /// Endpoint: `GET /master/custom-formulations?diseaseId=<diseaseId>&patientId=<patientId>`.
  Future<List<BastiFormulationModel>> getCustomFormulations({
    String? diseaseId,
    String? patientId,
  }) async {
    final query = <String, dynamic>{};
    if (diseaseId != null && diseaseId.trim().isNotEmpty) {
      query['diseaseId'] = diseaseId.trim();
    }
    if (patientId != null && patientId.trim().isNotEmpty) {
      query['patientId'] = patientId.trim();
    }

    final response = await _apiService.get(
      '/master/custom-formulations',
      query: query.isNotEmpty ? query : null,
    );

    if (!response.isOk) {
      final msg = ApiService.extractErrorMessage(response);
      throw Exception(
        msg.isNotEmpty ? msg : 'Failed to load custom formulations (${response.statusCode})',
      );
    }

    final list = _extractDataList(response.body);
    return list.map((e) => BastiFormulationModel.fromJson(_toMap(e))).toList();
  }

  /// Fetches formulations for [diseaseId] transformed into [BastiOptionModel] list,
  /// preserving formulation details, ingredients, recipes, and classical references.
  Future<List<BastiOptionModel>> getBastiOptionsForDisease(
    String diseaseId, {
    String? diseaseName,
    String? patientId,
    bool forceRefresh = false,
  }) async {
    final formulations = await getFormulationsByDisease(
      diseaseId,
      diseaseName: diseaseName,
      patientId: patientId,
      forceRefresh: forceRefresh,
    );

    final options = formulations
        .map((f) => BastiOptionModel.fromFormulation(f, diseaseId: diseaseId))
        .toList();

    return options;
  }

  // ── Dose Rules ─────────────────────────────────────────────────────────────

  /// Fetches dose rules from `GET /master/dose-rules`.
  /// Supports optional targeted query `?bastiType={type}&bala={bala}`.
  Future<List<DoseRuleModel>> getDoseRules({
    String? bastiType,
    String? bala,
    bool forceRefresh = false,
  }) async {
    final hasFilter = (bastiType != null && bastiType.trim().isNotEmpty) ||
        (bala != null && bala.trim().isNotEmpty);

    // If no filter requested, use global cached list
    if (!hasFilter) {
      if (!forceRefresh && _cachedDoseRules != null) {
        return _cachedDoseRules!;
      }

      if (!forceRefresh && _inFlightDoseRules != null) {
        return _inFlightDoseRules!;
      }

      final future = _fetchDoseRules();
      _inFlightDoseRules = future;
      try {
        return await future;
      } finally {
        _inFlightDoseRules = null;
      }
    }

    // If filter requested and full rules are already cached, check if matching rule is already here
    if (!forceRefresh && _cachedDoseRules != null) {
      final filtered = _cachedDoseRules!.where((rule) {
        final matchesType = bastiType == null ||
            bastiType.trim().isEmpty ||
            rule.bastiType.toLowerCase() == bastiType.trim().toLowerCase();
        final matchesBala = bala == null ||
            bala.trim().isEmpty ||
            rule.bala.toLowerCase() == bala.trim().toLowerCase();
        return matchesType && matchesBala;
      }).toList();
      if (filtered.isNotEmpty) {
        return filtered;
      }
    }

    // Otherwise query targeted GET /master/dose-rules?bastiType={type}&bala={bala}
    return _fetchDoseRules(bastiType: bastiType, bala: bala);
  }

  Future<List<DoseRuleModel>> _fetchDoseRules({
    String? bastiType,
    String? bala,
  }) async {
    final query = <String, dynamic>{};
    if (bastiType != null && bastiType.trim().isNotEmpty) {
      query['bastiType'] = bastiType.trim();
    }
    if (bala != null && bala.trim().isNotEmpty) {
      query['bala'] = bala.trim();
    }

    final response = await _apiService.get(
      '/master/dose-rules',
      query: query.isNotEmpty ? query : null,
    );
    if (!response.isOk) {
      final msg = ApiService.extractErrorMessage(response);
      throw Exception(
        msg.isNotEmpty ? msg : 'Failed to load dose rules (${response.statusCode})',
      );
    }

    final list = _extractDataList(response.body);
    final rules = list
        .map((e) => DoseRuleModel.fromJson(_toMap(e)))
        .toList();

    if (query.isEmpty) {
      _cachedDoseRules = List.unmodifiable(rules);
    }
    return rules;
  }

  /// Resolves the specific dose rule for [bastiType] and [bala].
  /// Calls GET /master/dose-rules?bastiType={type}&bala={bala}
  Future<DoseRuleModel?> getDoseRule(
    String bastiType,
    String bala, {
    bool forceRefresh = false,
  }) async {
    final targetType = bastiType.trim();
    final targetBala = bala.trim();

    // 1. Check in cached global rules first if available
    if (!forceRefresh && _cachedDoseRules != null) {
      try {
        return _cachedDoseRules!.firstWhere(
          (rule) =>
              rule.bastiType.toLowerCase() == targetType.toLowerCase() &&
              rule.bala.toLowerCase() == targetBala.toLowerCase(),
        );
      } catch (_) {}
    }

    // 2. Fetch via targeted query GET /master/dose-rules?bastiType={type}&bala={bala}
    try {
      final rules = await getDoseRules(
        bastiType: targetType,
        bala: targetBala,
        forceRefresh: forceRefresh,
      );
      if (rules.isNotEmpty) {
        return rules.firstWhere(
          (rule) =>
              rule.bastiType.toLowerCase() == targetType.toLowerCase() &&
              rule.bala.toLowerCase() == targetBala.toLowerCase(),
          orElse: () => rules.first,
        );
      }
    } catch (_) {}

    // 3. Fallback to all rules if targeted query returned empty
    final allRules = await getDoseRules(forceRefresh: forceRefresh);
    try {
      return allRules.firstWhere(
        (rule) =>
            rule.bastiType.toLowerCase() == targetType.toLowerCase() &&
            rule.bala.toLowerCase() == targetBala.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Patterns ───────────────────────────────────────────────────────────────

  /// Fetches all Basti patterns from `GET /master/patterns`.
  Future<List<BastiPatternModel>> getPatterns({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPatterns != null) {
      return _cachedPatterns!;
    }

    if (!forceRefresh && _inFlightPatterns != null) {
      return _inFlightPatterns!;
    }

    final future = _fetchPatterns();
    _inFlightPatterns = future;
    try {
      return await future;
    } finally {
      _inFlightPatterns = null;
    }
  }

  Future<List<BastiPatternModel>> _fetchPatterns() async {
    final response = await _apiService.get('/master/patterns');
    if (!response.isOk) {
      final msg = ApiService.extractErrorMessage(response);
      throw Exception(
        msg.isNotEmpty ? msg : 'Failed to load Basti patterns (${response.statusCode})',
      );
    }

    final list = _extractDataList(response.body);
    final patterns = list
        .map((e) => BastiPatternModel.fromJson(_toMap(e)))
        .toList();

    _cachedPatterns = List.unmodifiable(patterns);
    return _cachedPatterns!;
  }

  /// Resolves a Basti pattern by its [code] (e.g. `'karma'`, `'kala'`, `'yoga'`).
  Future<BastiPatternModel?> getPatternByCode(
    String code, {
    bool forceRefresh = false,
  }) async {
    final patterns = await getPatterns(forceRefresh: forceRefresh);
    try {
      return patterns.firstWhere(
        (p) => p.code.toLowerCase() == code.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
