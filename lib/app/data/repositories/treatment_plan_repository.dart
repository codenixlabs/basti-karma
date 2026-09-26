import '../models/patient/basti_session_model.dart';
import '../models/patient/basti_treatment_plan_model.dart';

/// Abstract contract for treatment plan persistence.
///
/// The UI and controllers depend only on this interface.
/// Swap [LocalTreatmentRepository] for an [ApiTreatmentRepository]
/// without touching any controller or screen.
abstract class TreatmentPlanRepository {
  /// Persists a new treatment plan and returns its assigned [id].
  Future<String> createTreatmentPlan(BastiTreatmentPlanModel plan);

  /// Retrieves a plan by [id]. Returns null if not found.
  Future<BastiTreatmentPlanModel?> getTreatmentPlan(String id);

  /// Replaces the stored plan with an updated copy (uses [plan.id] as key).
  Future<void> updateTreatmentPlan(BastiTreatmentPlanModel plan);

  /// Returns all treatment plans for a given [patientId], newest first.
  Future<List<BastiTreatmentPlanModel>> getPlansForPatient(String patientId);

  /// Returns the single ACTIVE treatment plan for [patientId],
  /// or null if none exists.
  Future<BastiTreatmentPlanModel?> getActivePlanForPatient(String patientId);

  /// Returns the single DRAFT treatment plan for [patientId],
  /// or null if none exists.
  Future<BastiTreatmentPlanModel?> getDraftPlanForPatient(String patientId);

  /// Returns all sessions for a given treatment plan, ordered by [dayNumber].
  Future<List<BastiSessionModel>> getSessions(String treatmentPlanId);

  /// Returns the session for a specific [dayNumber] within a plan.
  /// Returns null if the session has not yet been saved.
  Future<BastiSessionModel?> getSession(String treatmentPlanId, int dayNumber);

  /// Inserts a new session record (must not already exist for that day).
  Future<void> saveSession(BastiSessionModel session);

  /// Replaces an existing session record (keyed by [treatmentPlanId] + [dayNumber]).
  Future<void> updateSession(BastiSessionModel session);

  /// Deletes or resets the session for a specific [dayNumber].
  Future<void> deleteSession(String treatmentPlanId, int dayNumber);
}

