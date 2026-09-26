/// Represents a patient in the BastiKarma system.
///
/// Immutable value object — use [copyWith] to produce updated copies.
/// The [id] is stable for the patient's lifetime and is the primary
/// relationship key: Patient.id → TreatmentPlan.patientId.
class PatientModel {
  // ── Identity ───────────────────────────────────────────────────────────────
  final String id; // 'pat_<millisecondsSinceEpoch>' or backend Mongo ObjectId

  // ── Basic Info (CRF Step 1 & Demographics) ─────────────────────────────────
  final String name;
  final int age;
  final String sex;
  final String? phoneNo;
  final String? occupation;
  final String? address;
  final String? religion;
  final String? maritalStatus;

  // Backwards compatibility getter for phone
  String? get phone => phoneNo;

  // ── Hospital Info (CRF Step 2 & hospitalInfo) ──────────────────────────────
  final String admissionType; // 'OPD' | 'IPD'
  final String? opdNumber;
  final String? ipdNumber;
  final String? clinicalDiseaseSelection;
  final String? customDiagnosis;
  final String diagnosis; // primary display diagnosis
  final String? diseaseId; // foreign key → DiseaseModel.id (if available)

  // Backwards compatibility getters
  String? get opdNo => opdNumber;
  String? get ipdNo => ipdNumber;

  // ── Clinical Information (CRF Step 3 & ClinicalInformation) ────────────────
  final String? chiefComplaints;
  final String? historyOfPresentIllness;
  final String? historyOfPastIllness;
  final String? familyHistory;

  // ── Personal History (CRF Step 4 & personalHistory) ────────────────────────
  final String? ahara;
  final String? vihara;
  final String? addiction;
  final String? bowelHabits;
  final String? nidra;
  final String? urineFrequency;
  final String? bloodGroup;

  // ── General Examination (CRF Step 6 & generalExamination) ──────────────────
  final String? bp;
  final String? rr;
  final String? hr;
  final String? temperature;
  final num? weight;
  final num? height;
  final num? bmi;

  // ── Rogi Pariksha (Ayurvedic constitution fields) ─────────────────────────
  final String prakriti;
  final String sarataha;
  final String sanhanan;
  final String pramana;
  final String satva;
  final String satmya;
  final String aharaShakti;
  final String vyayamaShakti;
  final String vaya;
  final String jihwa;
  final String desha;

  // ── Female History (CRF Step 5) ───────────────────────────────────────────
  final String? menstrualHistory;
  final int? numberOfDeliveries;
  final int? abortion;
  final String? surgicalIntervention;

  // ── Investigations (CRF Step 8 & 9) ──────────────────────────────────────
  final String? pathologicalRadiological;
  final String? photoUrl;
  final String? treatmentGiven;

  // ── Backend Assessment Status ─────────────────────────────────────────────
  final bool poorvaKarmaCompleted;
  final bool pradhanaKarmaCompleted;
  final bool paschataKarmaCompleted;

  // ── Timestamps ────────────────────────────────────────────────────────────
  final DateTime createdAt;

  const PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.sex,
    String? phoneNo,
    String? phone,
    this.occupation,
    this.address,
    this.religion,
    this.maritalStatus,
    this.admissionType = 'OPD',
    String? opdNumber,
    String? opdNo,
    String? ipdNumber,
    String? ipdNo,
    this.clinicalDiseaseSelection,
    this.customDiagnosis,
    required this.diagnosis,
    this.diseaseId,
    this.chiefComplaints,
    this.historyOfPresentIllness,
    this.historyOfPastIllness,
    this.familyHistory,
    this.ahara,
    this.vihara,
    this.addiction,
    this.bowelHabits,
    this.nidra,
    this.urineFrequency,
    this.bloodGroup,
    this.bp,
    this.rr,
    this.hr,
    this.temperature,
    this.weight,
    this.height,
    this.bmi,
    this.prakriti = '',
    this.sarataha = '',
    this.sanhanan = '',
    this.pramana = '',
    this.satva = '',
    this.satmya = '',
    this.aharaShakti = '',
    this.vyayamaShakti = '',
    this.vaya = '',
    this.jihwa = '',
    this.desha = '',
    this.pathologicalRadiological,
    this.photoUrl,
    this.treatmentGiven,
    this.menstrualHistory,
    this.numberOfDeliveries,
    this.abortion,
    this.surgicalIntervention,
    this.poorvaKarmaCompleted = false,
    this.pradhanaKarmaCompleted = false,
    this.paschataKarmaCompleted = false,
    required this.createdAt,
  })  : phoneNo = phoneNo ?? phone,
        opdNumber = opdNumber ?? opdNo,
        ipdNumber = ipdNumber ?? ipdNo;

  // ── Factory helpers ────────────────────────────────────────────────────────

  static num? _parseNum(dynamic val) {
    if (val == null) return null;
    if (val is num) return val;
    if (val is String) return num.tryParse(val);
    return null;
  }

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    final demographics = json['demographics'] is Map<String, dynamic>
        ? json['demographics'] as Map<String, dynamic>
        : (json['demographics'] is Map
            ? Map<String, dynamic>.from(json['demographics'] as Map)
            : null);
    final hospitalInfo = json['hospitalInfo'] is Map<String, dynamic>
        ? json['hospitalInfo'] as Map<String, dynamic>
        : (json['hospitalInfo'] is Map
            ? Map<String, dynamic>.from(json['hospitalInfo'] as Map)
            : null);
    final clinicalInfo = json['ClinicalInformation'] is Map<String, dynamic>
        ? json['ClinicalInformation'] as Map<String, dynamic>
        : (json['clinicalInformation'] is Map<String, dynamic>
            ? json['clinicalInformation'] as Map<String, dynamic>
            : (json['ClinicalInformation'] is Map
                ? Map<String, dynamic>.from(json['ClinicalInformation'] as Map)
                : (json['clinicalInformation'] is Map
                    ? Map<String, dynamic>.from(json['clinicalInformation'] as Map)
                    : null)));
    final personalHistory = json['personalHistory'] is Map<String, dynamic>
        ? json['personalHistory'] as Map<String, dynamic>
        : (json['personalHistory'] is Map
            ? Map<String, dynamic>.from(json['personalHistory'] as Map)
            : null);
    final generalExam = json['generalExamination'] is Map<String, dynamic>
        ? json['generalExamination'] as Map<String, dynamic>
        : (json['generalExamination'] is Map
            ? Map<String, dynamic>.from(json['generalExamination'] as Map)
            : null);
    final investigations = json['investigations'] is Map
        ? Map<String, dynamic>.from(json['investigations'] as Map)
        : null;

    final id = (json['_id'] ?? json['id'] ?? '').toString();
    final name = demographics?['fullName'] as String? ??
        json['name'] as String? ??
        '';
    final age = demographics?['age'] is num
        ? (demographics!['age'] as num).toInt()
        : (json['age'] is num ? (json['age'] as num).toInt() : 0);
    final sex = demographics?['sex'] as String? ??
        json['sex'] as String? ??
        '';

    // Demographics phoneNo (README contract) with fallback to legacy phone
    final phoneNo = demographics?['phoneNo'] as String? ??
        demographics?['phone'] as String? ??
        json['phoneNo'] as String? ??
        json['phone'] as String?;

    final occupation = demographics?['occupation'] as String? ??
        json['occupation'] as String?;
    final address = demographics?['address'] as String? ??
        json['address'] as String?;
    final religion = demographics?['religion'] as String? ??
        json['religion'] as String?;
    final maritalStatus = demographics?['maritalStatus'] as String? ??
        json['maritalStatus'] as String?;

    // Hospital info
    final admissionType = hospitalInfo?['admissionType'] as String? ??
        json['admissionType'] as String? ??
        'OPD';
    final opdNumber = hospitalInfo?['opdNumber'] as String? ??
        hospitalInfo?['opdNo'] as String? ??
        json['opdNumber'] as String? ??
        json['opdNo'] as String?;
    final ipdNumber = hospitalInfo?['ipdNumber'] as String? ??
        hospitalInfo?['ipdNo'] as String? ??
        json['ipdNumber'] as String? ??
        json['ipdNo'] as String?;
    final clinicalDiseaseSelection =
        hospitalInfo?['clinicalDiseaseSelection'] as String? ??
            json['clinicalDiseaseSelection'] as String?;
    final customDiagnosis = hospitalInfo?['customDiagnosis'] as String? ??
        json['customDiagnosis'] as String?;
    final diagnosis = clinicalDiseaseSelection ??
        customDiagnosis ??
        hospitalInfo?['diagnosis'] as String? ??
        clinicalInfo?['chiefComplaints'] as String? ??
        json['diagnosis'] as String? ??
        '';
    final diseaseId = hospitalInfo?['diseaseId'] as String? ??
        json['diseaseId'] as String?;

    // Clinical Information
    final chiefComplaints = clinicalInfo?['chiefComplaints'] as String? ??
        json['chiefComplaints'] as String?;
    final historyOfPresentIllness =
        clinicalInfo?['historyOfPresentIllness'] as String? ??
            clinicalInfo?['historyPresentIllness'] as String? ??
            json['historyOfPresentIllness'] as String?;
    final historyOfPastIllness =
        clinicalInfo?['historyOfPastIllness'] as String? ??
            clinicalInfo?['historyPastIllness'] as String? ??
            json['historyOfPastIllness'] as String?;
    final familyHistory = clinicalInfo?['familyHistory'] as String? ??
        json['familyHistory'] as String?;

    // Personal History
    final rawAhara = personalHistory?['ahara'] as String? ??
        json['ahara'] as String? ??
        json['diet'] as String?;
    final ahara = normalizeAharaFromBackend(rawAhara);
    final vihara = personalHistory?['vihara'] as String? ??
        json['vihara'] as String?;
    final addiction = personalHistory?['addiction'] as String? ??
        json['addiction'] as String?;
    final bowelHabits = personalHistory?['bowelHabits'] as String? ??
        json['bowelHabits'] as String?;
    final nidra = personalHistory?['nidra'] as String? ??
        json['nidra'] as String?;
    final urineFrequency = personalHistory?['urineFrequency'] as String? ??
        json['urineFrequency'] as String?;
    final bloodGroup = personalHistory?['bloodGroup'] as String? ??
        json['bloodGroup'] as String?;

    // General Examination
    final bp = generalExam?['bp'] as String? ?? json['bp'] as String?;
    final rr = generalExam?['rr']?.toString() ?? json['rr']?.toString();
    final hr = generalExam?['hr']?.toString() ?? json['hr']?.toString();
    final temperature = generalExam?['temperature']?.toString() ??
        json['temperature']?.toString();
    final weight =
        _parseNum(generalExam?['weight']) ?? _parseNum(json['weight']);
    final height =
        _parseNum(generalExam?['height']) ?? _parseNum(json['height']);
    final bmi = _parseNum(generalExam?['bmi']) ?? _parseNum(json['bmi']);

    // Investigations / Photo / Treatment
    final pathologicalRadiological =
        investigations?['pathologicalRadiological'] as String? ??
            json['pathologicalRadiological'] as String?;
    final photoUrl = investigations?['photoUrl'] as String? ??
        json['photoUrl'] as String? ??
        json['photo'] as String?;
    final treatmentGiven = investigations?['treatmentGiven'] as String? ??
        json['treatmentGiven'] as String? ??
        json['treatment'] as String?;

    // Female History (CRF Step 5)
    final femaleHistory = json['femaleHistory'] is Map<String, dynamic>
        ? json['femaleHistory'] as Map<String, dynamic>
        : (json['femaleHistory'] is Map
            ? Map<String, dynamic>.from(json['femaleHistory'] as Map)
            : null);
    final menstrualHistory = femaleHistory?['menstrualHistory'] as String? ??
        json['menstrualHistory'] as String?;
    final numberOfDeliveries = (femaleHistory?['numberOfDeliveries'] as num?)?.toInt() ??
        (json['numberOfDeliveries'] as num?)?.toInt();
    final abortion = (femaleHistory?['abortion'] as num?)?.toInt() ??
        (json['abortion'] as num?)?.toInt();
    final surgicalIntervention = femaleHistory?['surgicalIntervention'] as String? ??
        json['surgicalIntervention'] as String?;

    // Assessment Status
    final assessmentStatus = json['assessmentStatus'] is Map<String, dynamic>
        ? json['assessmentStatus'] as Map<String, dynamic>
        : (json['assessmentStatus'] is Map
            ? Map<String, dynamic>.from(json['assessmentStatus'] as Map)
            : null);
    final poorvaKarmaCompleted =
        assessmentStatus?['poorvaKarmaCompleted'] as bool? ??
            json['poorvaKarmaCompleted'] as bool? ??
            false;
    final pradhanaKarmaCompleted =
        assessmentStatus?['pradhanaKarmaCompleted'] as bool? ??
            json['pradhanaKarmaCompleted'] as bool? ??
            false;
    final paschataKarmaCompleted =
        assessmentStatus?['paschataKarmaCompleted'] as bool? ??
            assessmentStatus?['paschatataKarmaCompleted'] as bool? ??
            json['paschataKarmaCompleted'] as bool? ??
            false;

    // Rogi Pariksha
    final rogiPariksha = json['rogiPariksha'] is Map<String, dynamic>
        ? json['rogiPariksha'] as Map<String, dynamic>
        : (json['rogiPariksha'] is Map
            ? Map<String, dynamic>.from(json['rogiPariksha'] as Map)
            : null);

    final createdAt = json['createdAt'] != null
        ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
        : DateTime.now();

    return PatientModel(
      id: id,
      name: name,
      age: age,
      sex: sex,
      phoneNo: phoneNo,
      occupation: occupation,
      address: address,
      religion: religion,
      maritalStatus: maritalStatus,
      admissionType: admissionType,
      opdNumber: opdNumber,
      ipdNumber: ipdNumber,
      clinicalDiseaseSelection: clinicalDiseaseSelection,
      customDiagnosis: customDiagnosis,
      diagnosis: diagnosis,
      diseaseId: diseaseId,
      chiefComplaints: chiefComplaints,
      historyOfPresentIllness: historyOfPresentIllness,
      historyOfPastIllness: historyOfPastIllness,
      familyHistory: familyHistory,
      ahara: ahara,
      vihara: vihara,
      addiction: addiction,
      bowelHabits: bowelHabits,
      nidra: nidra,
      urineFrequency: urineFrequency,
      bloodGroup: bloodGroup,
      bp: bp,
      rr: rr,
      hr: hr,
      temperature: temperature,
      weight: weight,
      height: height,
      bmi: bmi,
      prakriti: rogiPariksha?['prakriti'] as String? ?? json['prakriti'] as String? ?? '',
      sarataha: rogiPariksha?['sarataha'] as String? ?? json['sarataha'] as String? ?? '',
      sanhanan: rogiPariksha?['sanhanan'] as String? ?? json['sanhanan'] as String? ?? '',
      pramana: rogiPariksha?['pramana'] as String? ?? json['pramana'] as String? ?? '',
      satva: rogiPariksha?['satva'] as String? ?? json['satva'] as String? ?? '',
      satmya: rogiPariksha?['satmya'] as String? ?? json['satmya'] as String? ?? '',
      aharaShakti: rogiPariksha?['aharaShakti'] as String? ?? json['aharaShakti'] as String? ?? '',
      vyayamaShakti: rogiPariksha?['vyayamaShakti'] as String? ?? json['vyayamaShakti'] as String? ?? '',
      vaya: rogiPariksha?['vaya'] as String? ?? json['vaya'] as String? ?? '',
      jihwa: rogiPariksha?['jihwa'] as String? ?? json['jihwa'] as String? ?? '',
      desha: rogiPariksha?['desha'] as String? ?? json['desha'] as String? ?? '',
      pathologicalRadiological: pathologicalRadiological,
      photoUrl: photoUrl,
      treatmentGiven: treatmentGiven,
      menstrualHistory: menstrualHistory,
      numberOfDeliveries: numberOfDeliveries,
      abortion: abortion,
      surgicalIntervention: surgicalIntervention,
      poorvaKarmaCompleted: poorvaKarmaCompleted,
      pradhanaKarmaCompleted: pradhanaKarmaCompleted,
      paschataKarmaCompleted: paschataKarmaCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'sex': sex,
        'phoneNo': phoneNo,
        'phone': phoneNo,
        'occupation': occupation,
        'address': address,
        'religion': religion,
        'maritalStatus': maritalStatus,
        'admissionType': admissionType,
        'opdNumber': opdNumber,
        'ipdNumber': ipdNumber,
        'clinicalDiseaseSelection': clinicalDiseaseSelection,
        'customDiagnosis': customDiagnosis,
        'diagnosis': diagnosis,
        'diseaseId': diseaseId,
        'chiefComplaints': chiefComplaints,
        'historyOfPresentIllness': historyOfPresentIllness,
        'historyOfPastIllness': historyOfPastIllness,
        'familyHistory': familyHistory,
        'ahara': ahara,
        'vihara': vihara,
        'addiction': addiction,
        'bowelHabits': bowelHabits,
        'nidra': nidra,
        'urineFrequency': urineFrequency,
        'bloodGroup': bloodGroup,
        'bp': bp,
        'rr': rr,
        'hr': hr,
        'temperature': temperature,
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'prakriti': prakriti,
        'sarataha': sarataha,
        'sanhanan': sanhanan,
        'pramana': pramana,
        'satva': satva,
        'satmya': satmya,
        'aharaShakti': aharaShakti,
        'vyayamaShakti': vyayamaShakti,
        'vaya': vaya,
        'jihwa': jihwa,
        'desha': desha,
        if (menstrualHistory != null && menstrualHistory!.isNotEmpty)
          'menstrualHistory': menstrualHistory,
        if (numberOfDeliveries != null) 'numberOfDeliveries': numberOfDeliveries,
        if (abortion != null) 'abortion': abortion,
        if (surgicalIntervention != null && surgicalIntervention!.isNotEmpty)
          'surgicalIntervention': surgicalIntervention,
        if (pathologicalRadiological != null &&
            pathologicalRadiological!.isNotEmpty)
          'pathologicalRadiological': pathologicalRadiological,
        if (treatmentGiven != null && treatmentGiven!.isNotEmpty)
          'treatmentGiven': treatmentGiven,
        if (pathologicalRadiological != null ||
            photoUrl != null ||
            treatmentGiven != null)
          'investigations': {
            if (pathologicalRadiological != null &&
                pathologicalRadiological!.isNotEmpty)
              'pathologicalRadiological': pathologicalRadiological,
            if (photoUrl != null && photoUrl!.isNotEmpty)
              'photoUrl': photoUrl,
            if (treatmentGiven != null && treatmentGiven!.isNotEmpty)
              'treatmentGiven': treatmentGiven,
          },
        'createdAt': createdAt.toIso8601String(),
      };

  PatientModel copyWith({
    String? id,
    String? name,
    int? age,
    String? sex,
    String? phoneNo,
    String? phone,
    String? occupation,
    String? address,
    String? religion,
    String? maritalStatus,
    String? admissionType,
    String? opdNumber,
    String? opdNo,
    String? ipdNumber,
    String? ipdNo,
    String? clinicalDiseaseSelection,
    String? customDiagnosis,
    String? diagnosis,
    String? diseaseId,
    String? chiefComplaints,
    String? historyOfPresentIllness,
    String? historyOfPastIllness,
    String? familyHistory,
    String? ahara,
    String? vihara,
    String? addiction,
    String? bowelHabits,
    String? nidra,
    String? urineFrequency,
    String? bloodGroup,
    String? bp,
    String? rr,
    String? hr,
    String? temperature,
    num? weight,
    num? height,
    num? bmi,
    String? prakriti,
    String? sarataha,
    String? sanhanan,
    String? pramana,
    String? satva,
    String? satmya,
    String? aharaShakti,
    String? vyayamaShakti,
    String? vaya,
    String? jihwa,
    String? desha,
    String? pathologicalRadiological,
    String? photoUrl,
    String? treatmentGiven,
    String? menstrualHistory,
    int? numberOfDeliveries,
    int? abortion,
    String? surgicalIntervention,
    bool? poorvaKarmaCompleted,
    bool? pradhanaKarmaCompleted,
    bool? paschataKarmaCompleted,
    DateTime? createdAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      phoneNo: phoneNo ?? phone ?? this.phoneNo,
      occupation: occupation ?? this.occupation,
      address: address ?? this.address,
      religion: religion ?? this.religion,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      admissionType: admissionType ?? this.admissionType,
      opdNumber: opdNumber ?? opdNo ?? this.opdNumber,
      ipdNumber: ipdNumber ?? ipdNo ?? this.ipdNumber,
      clinicalDiseaseSelection:
          clinicalDiseaseSelection ?? this.clinicalDiseaseSelection,
      customDiagnosis: customDiagnosis ?? this.customDiagnosis,
      diagnosis: diagnosis ?? this.diagnosis,
      diseaseId: diseaseId ?? this.diseaseId,
      chiefComplaints: chiefComplaints ?? this.chiefComplaints,
      historyOfPresentIllness:
          historyOfPresentIllness ?? this.historyOfPresentIllness,
      historyOfPastIllness: historyOfPastIllness ?? this.historyOfPastIllness,
      familyHistory: familyHistory ?? this.familyHistory,
      ahara: ahara ?? this.ahara,
      vihara: vihara ?? this.vihara,
      addiction: addiction ?? this.addiction,
      bowelHabits: bowelHabits ?? this.bowelHabits,
      nidra: nidra ?? this.nidra,
      urineFrequency: urineFrequency ?? this.urineFrequency,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      bp: bp ?? this.bp,
      rr: rr ?? this.rr,
      hr: hr ?? this.hr,
      temperature: temperature ?? this.temperature,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
      prakriti: prakriti ?? this.prakriti,
      sarataha: sarataha ?? this.sarataha,
      sanhanan: sanhanan ?? this.sanhanan,
      pramana: pramana ?? this.pramana,
      satva: satva ?? this.satva,
      satmya: satmya ?? this.satmya,
      aharaShakti: aharaShakti ?? this.aharaShakti,
      vyayamaShakti: vyayamaShakti ?? this.vyayamaShakti,
      vaya: vaya ?? this.vaya,
      jihwa: jihwa ?? this.jihwa,
      desha: desha ?? this.desha,
      pathologicalRadiological:
          pathologicalRadiological ?? this.pathologicalRadiological,
      photoUrl: photoUrl ?? this.photoUrl,
      treatmentGiven: treatmentGiven ?? this.treatmentGiven,
      menstrualHistory: menstrualHistory ?? this.menstrualHistory,
      numberOfDeliveries: numberOfDeliveries ?? this.numberOfDeliveries,
      abortion: abortion ?? this.abortion,
      surgicalIntervention:
          surgicalIntervention ?? this.surgicalIntervention,
      poorvaKarmaCompleted: poorvaKarmaCompleted ?? this.poorvaKarmaCompleted,
      pradhanaKarmaCompleted:
          pradhanaKarmaCompleted ?? this.pradhanaKarmaCompleted,
      paschataKarmaCompleted:
          paschataKarmaCompleted ?? this.paschataKarmaCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Normalizes ahara (diet) values from UI or legacy models to the backend-accepted enum:
  /// - "Vegetarian" / "Veg" -> "Veg"
  /// - "Non-Vegetarian" / "Non-Veg" -> "Non-Veg"
  /// - "Mixed" -> "Mixed"
  static String? normalizeAharaToBackend(String? ahara) {
    if (ahara == null) return null;
    final trimmed = ahara.trim().toLowerCase();
    if (trimmed == 'veg' || trimmed == 'vegetarian') return 'Veg';
    if (trimmed == 'non-veg' ||
        trimmed == 'non-vegetarian' ||
        trimmed == 'nonveg') {
      return 'Non-Veg';
    }
    if (trimmed == 'mixed') return 'Mixed';
    return ahara.trim();
  }

  /// Normalizes ahara values received from backend into canonical UI values:
  /// - "Veg" / "Vegetarian" -> "Veg"
  /// - "Non-Veg" / "Non-Vegetarian" -> "Non-Veg"
  /// - "Mixed" -> "Mixed"
  static String? normalizeAharaFromBackend(String? ahara) {
    if (ahara == null) return null;
    final trimmed = ahara.trim().toLowerCase();
    if (trimmed == 'veg' || trimmed == 'vegetarian') return 'Veg';
    if (trimmed == 'non-veg' ||
        trimmed == 'non-vegetarian' ||
        trimmed == 'nonveg') {
      return 'Non-Veg';
    }
    if (trimmed == 'mixed') return 'Mixed';
    return ahara.trim();
  }
}
