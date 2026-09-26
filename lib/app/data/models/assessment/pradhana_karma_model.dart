class PradhanaKarmaModel {
  final String? id;
  final String? patientId;
  final String? patientName;
  final String? doctorId;
  final String? doctorName;
  final String? diseaseId;
  final String? diseaseName;
  final String? bastiFormulationId;
  final String? formulationName;
  final String? bastiPatternCode;
  final dynamic observation;
  final Map<String, dynamic>? rawJson;

  const PradhanaKarmaModel({
    this.id,
    this.patientId,
    this.patientName,
    this.doctorId,
    this.doctorName,
    this.diseaseId,
    this.diseaseName,
    this.bastiFormulationId,
    this.formulationName,
    this.bastiPatternCode,
    this.observation,
    this.rawJson,
  });

  static String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      return (value['_id'] ?? value['id'])?.toString();
    }
    return value.toString();
  }

  static String? _extractName(dynamic value, [String? fallbackKey]) {
    if (value is Map) {
      if (fallbackKey != null && value[fallbackKey] != null) {
        return value[fallbackKey].toString();
      }
      if (value['name'] != null) return value['name'].toString();
      if (value['demographics'] is Map &&
          value['demographics']['fullName'] != null) {
        return value['demographics']['fullName'].toString();
      }
    }
    return null;
  }

  factory PradhanaKarmaModel.fromJson(Map<String, dynamic> json) {
    final patientRaw = json['patientId'];
    final doctorRaw = json['doctorId'];
    final diseaseRaw = json['diseaseId'];
    final bastiRaw = json['bastiFormulationId'];

    return PradhanaKarmaModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      patientId: _extractId(patientRaw),
      patientName: _extractName(patientRaw),
      doctorId: _extractId(doctorRaw),
      doctorName: _extractName(doctorRaw),
      diseaseId: _extractId(diseaseRaw),
      diseaseName: _extractName(diseaseRaw, 'diseaseName') ??
          json['diseaseName']?.toString() ??
          json['disease']?.toString(),
      bastiFormulationId: _extractId(bastiRaw),
      formulationName: _extractName(bastiRaw, 'formulationName') ??
          json['formulationName']?.toString() ??
          json['bastiName']?.toString(),
      bastiPatternCode: json['bastiPatternCode']?.toString(),
      observation: json['observation'],
      rawJson: json,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (patientId != null) 'patientId': patientId,
        if (doctorId != null) 'doctorId': doctorId,
        if (diseaseId != null) 'diseaseId': diseaseId,
        if (bastiFormulationId != null)
          'bastiFormulationId': bastiFormulationId,
        if (bastiPatternCode != null) 'bastiPatternCode': bastiPatternCode,
        if (observation != null) 'observation': observation,
      };
}
