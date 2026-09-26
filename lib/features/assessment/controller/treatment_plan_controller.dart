import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/data/models/patient/basti_session_model.dart';
import '../../../app/data/models/patient/basti_treatment_plan_model.dart';
import '../../../app/data/models/patient/treatment_status.dart';
import '../../../app/data/repositories/api_treatment_repository.dart';
import '../../../app/data/repositories/treatment_plan_repository.dart';

/// GetX controller that manages the active [BastiTreatmentPlanModel] and
/// its associated [BastiSessionModel] list.
///
/// Fully backend-dependent: delegates persistence to [TreatmentPlanRepository],
/// defaulting to [ApiTreatmentRepository] which interacts with backend APIs.
class TreatmentPlanController extends GetxController {
  final TreatmentPlanRepository _repository;

  TreatmentPlanController({TreatmentPlanRepository? repository})
      : _repository = repository ??
            (Get.isRegistered<TreatmentPlanRepository>()
                ? Get.find<TreatmentPlanRepository>()
                : ApiTreatmentRepository());

  // ── Reactive state ─────────────────────────────────────────────────────────

  /// The currently active treatment plan (null until one is created/loaded).
  final currentPlan = Rxn<BastiTreatmentPlanModel>();

  /// All persisted sessions for the current plan, ordered by dayNumber.
  final persistedSessions = <BastiSessionModel>[].obs;

  // ── Derived state ──────────────────────────────────────────────────────────

  /// Number of sessions with status COMPLETED — derived from persisted records.
  /// Never a manually incremented counter.
  int get completedSessionCount =>
      persistedSessions.where((s) => s.isCompleted).length;

  /// Total planned days (from the schedule).
  int get totalPlannedDays {
    final count = currentPlan.value?.scheduleDays.length ?? 0;
    if (count > 0) return count;
    final code = currentPlan.value?.selectedPatternCode.toLowerCase() ?? '';
    if (code.contains('karma')) return 30;
    if (code.contains('kala')) return 16;
    if (code.contains('yoga')) return 8;
    return 0;
  }

  /// True only when all planned sessions are completed.
  bool get allSessionsCompleted =>
      totalPlannedDays > 0 &&
      completedSessionCount == totalPlannedDays;

  // ── Plan lifecycle ─────────────────────────────────────────────────────────

  /// Queries all treatment plans for a given [patientId].
  Future<List<BastiTreatmentPlanModel>> getPlansForPatient(String patientId) =>
      _repository.getPlansForPatient(patientId);

  /// Queries all sessions for a given [treatmentPlanId].
  Future<List<BastiSessionModel>> getSessions(String treatmentPlanId) =>
      _repository.getSessions(treatmentPlanId);

  /// Queries the active treatment plan for a given [patientId].
  Future<BastiTreatmentPlanModel?> getActivePlanForPatient(String patientId) =>
      _repository.getActivePlanForPatient(patientId);

  /// Queries the draft treatment plan for a given [patientId].
  Future<BastiTreatmentPlanModel?> getDraftPlanForPatient(String patientId) =>
      _repository.getDraftPlanForPatient(patientId);

  /// Loads the active treatment plan for [patientId] if one exists.
  /// Returns true if loaded, false otherwise.
  Future<bool> loadActivePlanForPatient(String patientId) async {
    final activePlan = await _repository.getActivePlanForPatient(patientId);
    if (activePlan == null) return false;
    currentPlan.value = activePlan;
    await _refreshSessions();
    return true;
  }

  /// Loads the draft treatment plan for [patientId] if one exists.
  /// Returns true if loaded, false otherwise.
  Future<bool> loadDraftPlanForPatient(String patientId) async {
    final draftPlan = await _repository.getDraftPlanForPatient(patientId);
    if (draftPlan == null) return false;
    currentPlan.value = draftPlan;
    await _refreshSessions();
    return true;
  }

  /// Creates a new treatment plan (status: DRAFT) and stores it.
  /// Returns the assigned plan ID, or null if an active treatment already exists.
  Future<String?> createTreatmentPlan(BastiTreatmentPlanModel plan) async {
    // Prevent accidental duplicate active treatments for the same patient
    if (plan.patientId != null) {
      final existingActive =
          await _repository.getActivePlanForPatient(plan.patientId!);
      if (existingActive != null && existingActive.id != plan.id) {
        return null;
      }
    }

    final id = await _repository.createTreatmentPlan(plan);
    currentPlan.value = plan;
    persistedSessions.clear();
    return id;
  }

  /// Updates an existing treatment plan.
  Future<void> updateTreatmentPlan(BastiTreatmentPlanModel plan) async {
    await _repository.updateTreatmentPlan(plan);
    currentPlan.value = plan;
  }

  /// Loads an existing plan and its sessions back into reactive state.
  Future<void> loadPlan(String planId) async {
    final plan = await _repository.getTreatmentPlan(planId);
    if (plan == null) return;
    currentPlan.value = plan;
    await _refreshSessions();
  }

  /// Marks the plan ACTIVE (called automatically on first session save).
  Future<void> _activatePlanIfDraft() async {
    final plan = currentPlan.value;
    if (plan == null || plan.status != TreatmentStatus.draft) return;
    final updated = plan.copyWith(
      status: TreatmentStatus.active,
      startDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.updateTreatmentPlan(updated);
    currentPlan.value = updated;
  }

  /// Marks the plan COMPLETED.
  /// Returns false (and shows a snackbar) if not all sessions are done.
  Future<bool> completeTreatment() async {
    if (!allSessionsCompleted) {
      final pendingCount = totalPlannedDays - completedSessionCount;
      try {
        if (Get.key.currentState != null && Get.isSnackbarOpen != true) {
          Get.snackbar(
            'Treatment Not Complete',
            '$pendingCount treatment ${pendingCount == 1 ? "session is" : "sessions are"} still pending. Please record all scheduled sessions before completing Pradhan Karma.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFD32F2F),
            colorText: const Color(0xFFFFFFFF),
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
            borderRadius: 14,
          );
        }
      } catch (_) {}
      return false;
    }

    final plan = currentPlan.value;
    if (plan == null) return false;

    final updated = plan.copyWith(
      status: TreatmentStatus.completed,
      updatedAt: DateTime.now(),
    );
    await _repository.updateTreatmentPlan(updated);
    currentPlan.value = updated;
    return true;
  }

  // ── Session lifecycle ──────────────────────────────────────────────────────

  /// Saves or updates a session by dayNumber.
  ///
  /// - If no session exists for that day: inserts new (COMPLETED).
  /// - If a session already exists: updates it (keeps COMPLETED).
  /// - Auto-transitions plan to ACTIVE on first save.
  Future<void> saveSession(BastiSessionModel session) async {
    final planId = currentPlan.value?.id;
    if (planId == null) return;

    final existing =
        await _repository.getSession(planId, session.dayNumber);

    if (existing == null) {
      await _repository.saveSession(session);
    } else {
      await _repository.updateSession(session);
    }

    // Auto-activate plan on first session save
    await _activatePlanIfDraft();

    await _refreshSessions();
  }

  /// Retrieves a specific session by dayNumber (from persisted store).
  /// Returns null if not yet saved.
  Future<BastiSessionModel?> getSession(int dayNumber) async {
    final planId = currentPlan.value?.id;
    if (planId == null) return null;
    return _repository.getSession(planId, dayNumber);
  }

  /// Deletes or clears a session record for [dayNumber].
  Future<void> deleteSession(int dayNumber) async {
    final planId = currentPlan.value?.id;
    if (planId == null) return;
    await _repository.deleteSession(planId, dayNumber);
    await _refreshSessions();
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<void> _refreshSessions() async {
    final planId = currentPlan.value?.id;
    if (planId == null) return;
    final sessions = await _repository.getSessions(planId);
    persistedSessions.value = sessions;
  }

  /// Clears in-memory treatment plan data on session cleanup.
  void clearData() {
    currentPlan.value = null;
    persistedSessions.clear();
  }
}
