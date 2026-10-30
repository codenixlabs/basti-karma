import '../models/master/basti_formulation_model.dart';
import '../models/master/basti_option_model.dart';
import '../models/master/basti_pattern_model.dart';
import '../models/master/disease_model.dart';
import '../models/master/dose_rule_model.dart';
import 'api_master_repository.dart';

/// Clinical Master Data Repository.
///
/// Pure delegator to [ApiMasterRepository] ensuring the backend API
/// is the single source of truth with zero local JSON fallback.
class BastiClinicalRepository {
  final ApiMasterRepository _apiMasterRepo;

  BastiClinicalRepository({
    ApiMasterRepository? apiMasterRepo,
  }) : _apiMasterRepo = apiMasterRepo ?? ApiMasterRepository();

  // ── Diseases ───────────────────────────────────────────────────────────────
  Future<List<DiseaseModel>> getDiseases({
    String? patientId,
    bool forceRefresh = false,
  }) {
    return _apiMasterRepo.getDiseases(
      patientId: patientId,
      forceRefresh: forceRefresh,
    );
  }

  Future<DiseaseModel?> getDiseaseById(
    String id, {
    String? patientId,
    bool forceRefresh = false,
  }) {
    return _apiMasterRepo.getDiseaseById(
      id,
      patientId: patientId,
      forceRefresh: forceRefresh,
    );
  }

  Future<DiseaseModel> addCustomDisease({
    required String name,
    required String patientId,
  }) {
    return _apiMasterRepo.addCustomDisease(
      name: name,
      patientId: patientId,
    );
  }

  // ── Formulations ───────────────────────────────────────────────────────────
  Future<List<BastiFormulationModel>> getAvailableFormulationsForDisease(
    String diseaseId, {
    String? diseaseName,
    String? patientId,
    bool forceRefresh = false,
  }) {
    return _apiMasterRepo.getFormulationsByDisease(
      diseaseId,
      diseaseName: diseaseName,
      patientId: patientId,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<BastiOptionModel>> getBastiOptionsForDisease(
    String diseaseId, {
    String? diseaseName,
    String? patientId,
    bool forceRefresh = false,
  }) {
    return _apiMasterRepo.getBastiOptionsForDisease(
      diseaseId,
      diseaseName: diseaseName,
      patientId: patientId,
      forceRefresh: forceRefresh,
    );
  }

  Future<BastiFormulationModel> addCustomFormulation({
    required String name,
    required String diseaseId,
    required String patientId,
    String? rawName,
    String? bastiType,
  }) {
    return _apiMasterRepo.addCustomFormulation(
      name: name,
      diseaseId: diseaseId,
      patientId: patientId,
      rawName: rawName,
      bastiType: bastiType,
    );
  }

  Future<List<BastiFormulationModel>> getCustomFormulations({
    String? diseaseId,
    String? patientId,
  }) {
    return _apiMasterRepo.getCustomFormulations(
      diseaseId: diseaseId,
      patientId: patientId,
    );
  }

  // ── Dose Rules ─────────────────────────────────────────────────────────────
  Future<List<DoseRuleModel>> getDoseRules({
    String? bastiType,
    String? bala,
    bool forceRefresh = false,
  }) {
    return _apiMasterRepo.getDoseRules(
      bastiType: bastiType,
      bala: bala,
      forceRefresh: forceRefresh,
    );
  }

  Future<DoseRuleModel?> getDoseRule(String bastiType, String bala,
      {bool forceRefresh = false}) {
    return _apiMasterRepo.getDoseRule(bastiType, bala,
        forceRefresh: forceRefresh);
  }

  // ── Patterns ───────────────────────────────────────────────────────────────
  Future<List<BastiPatternModel>> getBastiPatterns({bool forceRefresh = false}) {
    return _apiMasterRepo.getPatterns(forceRefresh: forceRefresh);
  }

  Future<BastiPatternModel?> getPatternByCode(String code,
      {bool forceRefresh = false}) {
    return _apiMasterRepo.getPatternByCode(code, forceRefresh: forceRefresh);
  }
}
