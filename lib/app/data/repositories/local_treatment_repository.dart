import '../models/patient/basti_session_model.dart';
import '../models/patient/basti_treatment_plan_model.dart';
import '../sources/local_treatment_data_source.dart';
import 'treatment_plan_repository.dart';

/// Concrete implementation of [TreatmentPlanRepository] backed by
/// [LocalTreatmentDataSource] (in-memory, single app session).
///
/// To switch to a backend API:
///   1. Create [ApiTreatmentRepository] implementing [TreatmentPlanRepository].
///   2. Register the new class in GetX instead of this one.
///   3. Zero changes to controllers or UI.
class LocalTreatmentRepository implements TreatmentPlanRepository {
  final LocalTreatmentDataSource _dataSource;

  LocalTreatmentRepository({LocalTreatmentDataSource? dataSource})
      : _dataSource = dataSource ?? LocalTreatmentDataSource();

  @override
  Future<String> createTreatmentPlan(BastiTreatmentPlanModel plan) async {
    await _dataSource.savePlan(plan);
    return plan.id;
  }

  @override
  Future<BastiTreatmentPlanModel?> getTreatmentPlan(String id) async {
    final json = await _dataSource.fetchPlan(id);
    if (json == null) return null;
    return BastiTreatmentPlanModel.fromJson(json);
  }

  @override
  Future<void> updateTreatmentPlan(BastiTreatmentPlanModel plan) async {
    await _dataSource.updatePlan(plan);
  }

  @override
  Future<List<BastiTreatmentPlanModel>> getPlansForPatient(
    String patientId,
  ) async {
    final jsonList = await _dataSource.fetchPlansForPatient(patientId);
    return jsonList.map(BastiTreatmentPlanModel.fromJson).toList();
  }

  @override
  Future<BastiTreatmentPlanModel?> getActivePlanForPatient(
    String patientId,
  ) async {
    final json = await _dataSource.fetchActivePlanForPatient(patientId);
    if (json == null) return null;
    return BastiTreatmentPlanModel.fromJson(json);
  }

  @override
  Future<BastiTreatmentPlanModel?> getDraftPlanForPatient(
    String patientId,
  ) async {
    final json = await _dataSource.fetchDraftPlanForPatient(patientId);
    if (json == null) return null;
    return BastiTreatmentPlanModel.fromJson(json);
  }

  @override
  Future<List<BastiSessionModel>> getSessions(String treatmentPlanId) async {
    final jsonList = await _dataSource.fetchAllSessions(treatmentPlanId);
    return jsonList.map(BastiSessionModel.fromJson).toList();
  }

  @override
  Future<BastiSessionModel?> getSession(
    String treatmentPlanId,
    int dayNumber,
  ) async {
    final json = await _dataSource.fetchSession(treatmentPlanId, dayNumber);
    if (json == null) return null;
    return BastiSessionModel.fromJson(json);
  }

  @override
  Future<void> saveSession(BastiSessionModel session) async {
    await _dataSource.saveSession(session);
  }

  @override
  Future<void> updateSession(BastiSessionModel session) async {
    // Same underlying operation — upsert by planId + dayNumber.
    await _dataSource.saveSession(session);
  }

  @override
  Future<void> deleteSession(String treatmentPlanId, int dayNumber) async {
    await _dataSource.deleteSession(treatmentPlanId, dayNumber);
  }
}
