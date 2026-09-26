/// Lifecycle state of a treatment plan.
enum TreatmentStatus {
  /// Plan has been generated but treatment has not yet started.
  draft,

  /// At least one session has been saved; treatment is in progress.
  active,

  /// All sessions are completed and the plan has been formally closed.
  completed,
}

/// Lifecycle state of an individual treatment session (day).
enum SessionStatus {
  /// Session exists but has not been logged yet.
  pending,

  /// Session is currently open / being filled in (optional intermediate state).
  inProgress,

  /// Session has been saved and marked complete.
  completed,
}

// ── JSON helpers ────────────────────────────────────────────────────────────

extension TreatmentStatusJson on TreatmentStatus {
  String toJson() => name; // 'draft' | 'active' | 'completed'
}

extension SessionStatusJson on SessionStatus {
  String toJson() => name; // 'pending' | 'inProgress' | 'completed'
}

TreatmentStatus treatmentStatusFromJson(String? value) {
  switch (value) {
    case 'active':
      return TreatmentStatus.active;
    case 'completed':
      return TreatmentStatus.completed;
    default:
      return TreatmentStatus.draft;
  }
}

SessionStatus sessionStatusFromJson(String? value) {
  switch (value) {
    case 'inProgress':
      return SessionStatus.inProgress;
    case 'completed':
      return SessionStatus.completed;
    default:
      return SessionStatus.pending;
  }
}
