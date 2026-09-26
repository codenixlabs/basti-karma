/// Models representing clinical results computed and returned by the backend
/// for Poorva Karma assessments.
class PoorvaEligibilityResult {
  final bool isEligible;
  final String message;

  const PoorvaEligibilityResult({
    required this.isEligible,
    required this.message,
  });

  factory PoorvaEligibilityResult.fromJson(Map<String, dynamic> json) {
    final eligible = json['isEligible'] as bool? ?? false;
    final msg = json['message'] as String? ??
        (eligible ? 'Eligible' : 'Not Eligible');
    return PoorvaEligibilityResult(
      isEligible: eligible,
      message: msg,
    );
  }
}

class AgniAssessmentResult {
  final int totalScore;
  final String agniType;
  final String? recommendedDrugs;

  const AgniAssessmentResult({
    required this.totalScore,
    required this.agniType,
    this.recommendedDrugs,
  });

  factory AgniAssessmentResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return AgniAssessmentResult(
      totalScore: (data['totalScore'] as num?)?.toInt() ??
          (json['totalScore'] as num?)?.toInt() ??
          0,
      agniType: data['agniType'] as String? ??
          json['agniType'] as String? ??
          'Agni Evaluated',
      recommendedDrugs: data['recommendedDrugs'] as String? ??
          json['recommendedDrugs'] as String?,
    );
  }
}

class KosthaAssessmentResult {
  final int totalScore;
  final String kosthaType;

  const KosthaAssessmentResult({
    required this.totalScore,
    required this.kosthaType,
  });

  factory KosthaAssessmentResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return KosthaAssessmentResult(
      totalScore: (data['totalScore'] as num?)?.toInt() ??
          (json['totalScore'] as num?)?.toInt() ??
          0,
      kosthaType: data['kosthaType'] as String? ??
          json['kosthaType'] as String? ??
          'Kostha Evaluated',
    );
  }
}

class SaamaNiramaResult {
  final bool deepanPachanaRequired;

  const SaamaNiramaResult({
    required this.deepanPachanaRequired,
  });

  factory SaamaNiramaResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return SaamaNiramaResult(
      deepanPachanaRequired: data['deepanPachanaRequired'] as bool? ??
          json['deepanPachanaRequired'] as bool? ??
          false,
    );
  }
}
