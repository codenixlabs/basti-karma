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
  static final Map<String, List<BastiFormulationModel>> _cachedFormulationsByDisease = {};
  static List<DoseRuleModel>? _cachedDoseRules;
  static List<BastiPatternModel>? _cachedPatterns;

  static Future<List<DiseaseModel>>? _inFlightDiseases;
  static final Map<String, Future<List<BastiFormulationModel>>> _inFlightFormulations = {};
  static Future<List<DoseRuleModel>>? _inFlightDoseRules;
  static Future<List<BastiPatternModel>>? _inFlightPatterns;

  ApiMasterRepository({ApiService? apiService})
      : _apiService = apiService ??
            (Get.isRegistered<ApiService>()
                ? Get.find<ApiService>()
                : ApiService());

  /// Clears in-memory cache.
  void clearCache() {
    _cachedDiseases = null;
    _cachedFormulationsByDisease.clear();
    _cachedDoseRules = null;
    _cachedPatterns = null;
    _inFlightDiseases = null;
    _inFlightFormulations.clear();
    _inFlightDoseRules = null;
    _inFlightPatterns = null;
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
  Future<List<DiseaseModel>> getDiseases({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedDiseases != null) {
      ApiService.log('📦 [ApiMasterRepository] Using ${_cachedDiseases!.length} cached diseases');
      return _cachedDiseases!;
    }

    if (!forceRefresh && _inFlightDiseases != null) {
      return _inFlightDiseases!;
    }

    final future = _fetchDiseases();
    _inFlightDiseases = future;
    try {
      return await future;
    } finally {
      _inFlightDiseases = null;
    }
  }

  Future<List<DiseaseModel>> _fetchDiseases() async {
    final response = await _apiService.get('/master/diseases');
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

    _cachedDiseases = List.unmodifiable(diseases);
    ApiService.log('📥 [ApiMasterRepository] Parsed and cached ${diseases.length} diseases from API response');
    return _cachedDiseases!;
  }

  /// Finds a disease by its string `id` or MongoDB `_id` or name.
  Future<DiseaseModel?> getDiseaseById(String id, {bool forceRefresh = false}) async {
    final diseases = await getDiseases(forceRefresh: forceRefresh);
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
  Future<List<BastiFormulationModel>> getFormulationsByDisease(
    String diseaseId, {
    String? diseaseName,
    bool forceRefresh = false,
  }) async {
    final slug = resolveDiseaseSlug(diseaseId, diseaseName: diseaseName);

    if (!forceRefresh) {
      if (_cachedFormulationsByDisease.containsKey(slug)) {
        return _cachedFormulationsByDisease[slug]!;
      }
      if (_cachedFormulationsByDisease.containsKey(diseaseId)) {
        return _cachedFormulationsByDisease[diseaseId]!;
      }
      if (_inFlightFormulations.containsKey(slug)) {
        return _inFlightFormulations[slug]!;
      }
      if (_inFlightFormulations.containsKey(diseaseId)) {
        return _inFlightFormulations[diseaseId]!;
      }
    }

    final future = _fetchFormulationsByDisease(slug, diseaseId, diseaseName);
    _inFlightFormulations[slug] = future;
    _inFlightFormulations[diseaseId] = future;
    try {
      return await future;
    } finally {
      _inFlightFormulations.remove(slug);
      _inFlightFormulations.remove(diseaseId);
    }
  }

  Future<List<BastiFormulationModel>> _fetchFormulationsByDisease(
    String slug,
    String diseaseId,
    String? diseaseName,
  ) async {
    // Try primary query with resolved slug
    var response = await _apiService.get('/master/formulations/$slug');

    // If 404 and slug differs from original diseaseId, try fallback with diseaseId
    if (response.statusCode == 404 && slug != diseaseId && !diseaseId.startsWith('custom_')) {
      response = await _apiService.get('/master/formulations/$diseaseId');
    }

    // If still 404 and diseaseName is available and different, try slugifying diseaseName
    if (response.statusCode == 404 && diseaseName != null && diseaseName.trim().isNotEmpty) {
      final nameSlug = DiseaseModel.slugify(diseaseName);
      if (nameSlug != slug && nameSlug != diseaseId) {
        response = await _apiService.get('/master/formulations/$nameSlug');
      }
    }

    if (response.statusCode == 404) {
      // Gracefully return empty list when no formulations exist
      _cachedFormulationsByDisease[slug] = const [];
      _cachedFormulationsByDisease[diseaseId] = const [];
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
    _cachedFormulationsByDisease[slug] = unmod;
    _cachedFormulationsByDisease[diseaseId] = unmod;
    return unmod;
  }

  /// Fetches formulations for [diseaseId] transformed into [BastiOptionModel] list,
  /// preserving formulation details, ingredients, recipes, and classical references.
  Future<List<BastiOptionModel>> getBastiOptionsForDisease(
    String diseaseId, {
    String? diseaseName,
    bool forceRefresh = false,
  }) async {
    final formulations = await getFormulationsByDisease(
      diseaseId,
      diseaseName: diseaseName,
      forceRefresh: forceRefresh,
    );

    final options = formulations
        .map((f) => BastiOptionModel.fromFormulation(f, diseaseId: diseaseId))
        .toList();

    return List.unmodifiable(options);
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
