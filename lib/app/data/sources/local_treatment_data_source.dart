import '../models/patient/basti_session_model.dart';
import '../models/patient/basti_treatment_plan_model.dart';
import '../models/patient/treatment_status.dart';

/// In-memory transient data store for treatment plans and sessions.
///
/// Used for ephemeral in-memory caching and tests. Does not write to local disk
/// or SharedPreferences; all persistent data is sourced from the backend API.
///
/// Keys:
///   _plans          :  planId -> plan JSON
///   _sessions       :  planId -> { dayNumber -> session JSON }
///   _patientPlans   :  patientId -> List of planIds  (patient-to-plans index)
class LocalTreatmentDataSource {
  // Singleton so the same store is shared across repository instances
  // within a single app session.
  static final LocalTreatmentDataSource _instance =
      LocalTreatmentDataSource._internal();
  factory LocalTreatmentDataSource() => _instance;
  LocalTreatmentDataSource._internal();

  final Map<String, Map<String, dynamic>> _plans = {};
  final Map<String, Map<int, Map<String, dynamic>>> _sessions = {};

  /// patientId → ordered list of planIds (insertion order = oldest first).
  final Map<String, List<String>> _patientPlans = {};

  // ── Plans ──────────────────────────────────────────────────────────────────

  Future<void> savePlan(BastiTreatmentPlanModel plan) async {
    _plans[plan.id] = plan.toJson();
    // Index by patientId if provided
    if (plan.patientId != null) {
      _patientPlans.putIfAbsent(plan.patientId!, () => []);
      final list = _patientPlans[plan.patientId!]!;
      if (!list.contains(plan.id)) list.add(plan.id);
    }
  }

  Future<Map<String, dynamic>?> fetchPlan(String id) async {
    return _plans[id];
  }

  Future<void> updatePlan(BastiTreatmentPlanModel plan) async {
    _plans[plan.id] = plan.toJson();
    // Ensure index is updated (patientId may have been set after creation)
    if (plan.patientId != null) {
      _patientPlans.putIfAbsent(plan.patientId!, () => []);
      final list = _patientPlans[plan.patientId!]!;
      if (!list.contains(plan.id)) list.add(plan.id);
    }
  }

  /// Returns all plan JSONs for [patientId], newest first.
  Future<List<Map<String, dynamic>>> fetchPlansForPatient(
    String patientId,
  ) async {
    final ids = _patientPlans[patientId] ?? [];
    final result = <Map<String, dynamic>>[];
    for (final id in ids) {
      final json = _plans[id];
      if (json != null) result.add(json);
    }
    // Newest first (reverse insertion order)
    return result.reversed.toList();
  }

  /// Returns the ACTIVE plan JSON for [patientId], or null.
  Future<Map<String, dynamic>?> fetchActivePlanForPatient(
    String patientId,
  ) async {
    final all = await fetchPlansForPatient(patientId);
    for (final json in all) {
      final statusStr = json['status'] as String?;
      if (statusStr == TreatmentStatus.active.name) {
        return json;
      }
    }
    return null;
  }

  /// Returns the DRAFT plan JSON for [patientId], or null.
  Future<Map<String, dynamic>?> fetchDraftPlanForPatient(
    String patientId,
  ) async {
    final all = await fetchPlansForPatient(patientId);
    for (final json in all) {
      final statusStr = json['status'] as String?;
      if (statusStr == TreatmentStatus.draft.name) {
        return json;
      }
    }
    return null;
  }

  // ── Sessions ───────────────────────────────────────────────────────────────

  Future<void> saveSession(BastiSessionModel session) async {
    _sessions.putIfAbsent(session.treatmentPlanId, () => {});
    _sessions[session.treatmentPlanId]![session.dayNumber] = session.toJson();
  }

  Future<Map<String, dynamic>?> fetchSession(
    String treatmentPlanId,
    int dayNumber,
  ) async {
    return _sessions[treatmentPlanId]?[dayNumber];
  }

  Future<List<Map<String, dynamic>>> fetchAllSessions(
    String treatmentPlanId,
  ) async {
    final bucket = _sessions[treatmentPlanId];
    if (bucket == null) return [];
    final sorted = bucket.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => e.value).toList();
  }

  Future<void> deleteSession(String treatmentPlanId, int dayNumber) async {
    _sessions[treatmentPlanId]?.remove(dayNumber);
  }

  /// Clears all data — used in tests and cleanup.
  void clearAll() {
    _plans.clear();
    _sessions.clear();
    _patientPlans.clear();
  }
}
