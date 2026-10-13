class FollowUpModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String notes;
  final String? updatedAt;

  FollowUpModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.notes,
    this.updatedAt,
  });

  factory FollowUpModel.fromJson(Map<String, dynamic> json) {
    return FollowUpModel(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      notes: json['notes'] ?? '',
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'notes': notes,
      'updatedAt': updatedAt,
    };
  }
}
