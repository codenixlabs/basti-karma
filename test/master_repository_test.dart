import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:bastikarma/app/data/models/master/basti_formulation_model.dart';
import 'package:bastikarma/app/data/models/master/basti_option_model.dart';
import 'package:bastikarma/app/data/models/master/disease_model.dart';
import 'package:bastikarma/app/data/models/patient/patient_model.dart';
import 'package:bastikarma/app/data/repositories/api_master_repository.dart';
import 'package:bastikarma/app/data/repositories/api_patient_repository.dart';
import 'package:bastikarma/app/data/services/api_service.dart';

void main() {
  const jsonString = '''
{
  "success": true,
  "count": 2,
  "data": [
    {
      "_id": "6ab2b3104bea0b71fcb10462",
      "id": "basti_dvi_panchamuladi_yapana_yapana",
      "name": "Dvi panchamuladi yapana basti",
      "rawName": "Dvi panchamuladi yapana basti. (only YB)",
      "bastiType": "Yapana Basti",
      "formulationDetails": "Dvi panchamuladi yapana basti",
      "ingredientsRaw": "",
      "formulationRecipeRaw": "",
      "isCrossReference": false,
      "referencedCondition": "",
      "unresolvedReference": false,
      "classicalReferenceIds": [
        "ref_9"
      ],
      "diseaseIds": [],
      "sourceText": "Name: Dvi panchamuladi yapana basti. (only YB) | Ingredients:  | Formulation: ",
      "recipeCompleteness": "blank_recipe",
      "ingredients": [],
      "__v": 0,
      "createdAt": "2026-09-22T16:55:44.302Z",
      "updatedAt": "2026-09-22T16:55:44.302Z"
    },
    {
      "_id": "6ab2b3104bea0b71fcb10460",
      "id": "basti_rasnadi_nb_ab",
      "name": "Rasnadi niruha basti",
      "rawName": "Rasnadi niruha basti.(NB+AB)",
      "bastiType": "Niruha Basti + Anuvasana Basti",
      "formulationDetails": "Mentioned in prameha.",
      "ingredientsRaw": "Mentioned in prameha.",
      "formulationRecipeRaw": "",
      "isCrossReference": false,
      "referencedCondition": "",
      "unresolvedReference": false,
      "classicalReferenceIds": [
        "ref_8",
        "ref_35"
      ],
      "diseaseIds": [],
      "sourceText": "Name: Rasnadi niruha basti.(NB+AB) | Ingredients: As mentioned in prameha. | Formulation: ",
      "recipeCompleteness": "partial_recipe",
      "ingredients": [
        {
          "id": "ing_0067",
          "name": "Mentioned in prameha.",
          "quantity": null,
          "unit": null,
          "category": "Herb / Ingredient",
          "sourceText": "Mentioned in prameha.",
          "_id": "6ab2b3104bea0b71fcb10461"
        }
      ],
      "__v": 0,
      "createdAt": "2026-09-22T16:55:44.302Z",
      "updatedAt": "2026-09-22T16:55:44.302Z"
    }
  ]
}
''';

  List<dynamic> extractList(dynamic body) {
    dynamic raw = body;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }
    if (raw is Map) {
      final data = raw['data'];
      if (data is List) {
        return data;
      }
      return const [];
    } else if (raw is List) {
      return raw;
    }
    return const [];
  }

  Map<String, dynamic> toMap(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item;
    } else if (item is Map) {
      return Map<String, dynamic>.from(item);
    }
    return <String, dynamic>{};
  }

  test('parses from raw JSON string', () {
    final list = extractList(jsonString);
    expect(list.length, 2);
    final formulations = list.map((e) => BastiFormulationModel.fromJson(toMap(e))).toList();
    expect(formulations.length, 2);
    final options = formulations.map((f) => BastiOptionModel.fromFormulation(f, diseaseId: 'dis_ajirna')).toList();
    expect(options.length, 2);
    expect(options[0].name, 'Dvi panchamuladi yapana basti');
    expect(options[0].bastiTypeDisplay, 'Yapana Basti');
    expect(options[1].name, 'Rasnadi niruha basti');
    expect(options[1].bastiTypeDisplay, 'Niruha Basti + Anuvasana Basti');
  });

  test('parses from Map<dynamic, dynamic>', () {
    final decoded = jsonDecode(jsonString) as Map;
    final dynamic dynamicMap = Map<dynamic, dynamic>.from(decoded);
    final list = extractList(dynamicMap);
    expect(list.length, 2);
    final formulations = list.map((e) => BastiFormulationModel.fromJson(toMap(e))).toList();
    expect(formulations.length, 2);
    final options = formulations.map((f) => BastiOptionModel.fromFormulation(f, diseaseId: 'dis_ajirna')).toList();
    expect(options.length, 2);
  });

  test('DiseaseModel slugify and robust id extraction', () {
    expect(DiseaseModel.slugify('Ajirna'), 'dis_ajirna');
    expect(DiseaseModel.slugify('Adhya Vata'), 'dis_adhya_vata');
    expect(DiseaseModel.slugify('   Amavata  '), 'dis_amavata');

    // 1. Backend with id already set
    final d1 = DiseaseModel.fromJson({
      'id': 'dis_ajirna',
      '_id': '6ab2b3104bea0b71fcb10400',
      'name': 'Ajirna',
    });
    expect(d1.id, 'dis_ajirna');
    expect(d1.mongoId, '6ab2b3104bea0b71fcb10400');

    // 2. Backend with only _id and name (no id field)
    final d2 = DiseaseModel.fromJson({
      '_id': '6ab2b3104bea0b71fcb10400',
      'name': 'Ajirna',
    });
    expect(d2.id, 'dis_ajirna');
    expect(d2.mongoId, '6ab2b3104bea0b71fcb10400');

    // 3. Backend with Mongo ID in id field
    final d3 = DiseaseModel.fromJson({
      'id': '6ab2b3104bea0b71fcb10400',
      '_id': '6ab2b3104bea0b71fcb10400',
      'name': 'Ajirna',
    });
    expect(d3.id, 'dis_ajirna');
    expect(d3.mongoId, '6ab2b3104bea0b71fcb10400');
  });

  test('ApiMasterRepository slug resolution', () {
    final repo = ApiMasterRepository();
    expect(repo.resolveDiseaseSlug('dis_ajirna'), 'dis_ajirna');
    expect(repo.resolveDiseaseSlug('Ajirna'), 'dis_ajirna');
    expect(repo.resolveDiseaseSlug('custom_12345', diseaseName: 'Ajirna'), 'dis_ajirna');
    expect(repo.resolveDiseaseSlug('6ab2b3104bea0b71fcb10400', diseaseName: 'Ajirna'), 'dis_ajirna');
  });

  test('ApiService logs API response with status, duration, and body without truncation', () async {
    final logs = <String>[];
    ApiService.logWriter = (msg) => logs.add(msg);
    ApiService.enableLogging = true;

    final service = ApiService(baseUrl: 'https://example.com/api');
    await service.loggedCall(
      'GET',
      '/master/diseases',
      null,
      () async => const Response(
        statusCode: 200,
        body: {
          'success': true,
          'count': 1,
          'data': [
            {
              '_id': '6ab2b3104bea0b71fcb10400',
              'id': 'dis_ajirna',
              'name': 'Ajirna',
              'category': 'Agni Dosha',
            }
          ],
        },
      ),
    );

    expect(logs.isNotEmpty, true);
    final combinedLog = logs.join('\n');
    expect(combinedLog.contains('🌐 [API REQUEST] → GET'), true);
    expect(combinedLog.contains('📥 [API RESPONSE] ← 🟢 SUCCESS 200'), true);
    expect(combinedLog.contains('dis_ajirna'), true);
    expect(combinedLog.contains('Ajirna'), true);

    ApiService.logWriter = null;
  });

  test('ApiPatientRepository sends pathological & radiological findings and all CRF fields in payload', () {
    final patient = PatientModel(
      id: 'pat_123',
      name: 'John Doe',
      age: 40,
      sex: 'Male',
      phoneNo: '9876543210',
      religion: 'Hindu',
      occupation: 'Engineer',
      maritalStatus: 'Married',
      address: '123 Street',
      admissionType: 'OPD',
      opdNumber: 'OPD-101',
      clinicalDiseaseSelection: 'Amavata',
      customDiagnosis: 'Rheumatoid Arthritis',
      diagnosis: 'Amavata',
      chiefComplaints: 'Joint stiffness and pain',
      historyOfPresentIllness: 'Started 3 months ago',
      historyOfPastIllness: 'None',
      familyHistory: 'Father had joint issues',
      ahara: 'Veg',
      vihara: 'Sedentary',
      addiction: 'Tea',
      bowelHabits: 'Constipated',
      nidra: 'Disturbed',
      urineFrequency: '5-6 times/day',
      bloodGroup: 'B+',
      bp: '130/85',
      rr: '18',
      hr: '76',
      temperature: '98.4',
      weight: 72.5,
      height: 175.0,
      bmi: 23.7,
      prakriti: 'Vata-Pitta',
      sarataha: 'Madhyama',
      sanhanan: 'Madhyama',
      pramana: 'Pravara',
      satva: 'Pravara',
      satmya: 'Sarvarasa Satmya',
      aharaShakti: 'Madhyama',
      vyayamaShakti: 'Avara',
      vaya: 'Madhyama (Adult 16–60)',
      jihwa: 'Ishat lipta',
      desha: 'Sadharana (Normal)',
      pathologicalRadiological: 'CBC: Hb 11.2, ESR 45. X-Ray: Reduced joint space.',
      treatmentGiven: 'Deepana Pachana followed by Niruha Basti',
      createdAt: DateTime.now(),
    );

    final repo = ApiPatientRepository();
    final payload = repo.patientToBackendPayload(patient);

    // 1. Pathological & radiological findings (strictly inside investigations)
    expect(payload['investigations'], isA<Map<String, dynamic>>());
    expect(payload['investigations']['pathologicalRadiological'], 'CBC: Hb 11.2, ESR 45. X-Ray: Reduced joint space.');
    expect(payload['investigations']['treatmentGiven'], 'Deepana Pachana followed by Niruha Basti');
    expect(payload['pathologicalRadiological'], isNull);

    // 2. Treatment (strictly root 'treatment', not duplicated as 'treatmentGiven')
    expect(payload['treatment'], 'Deepana Pachana followed by Niruha Basti');
    expect(payload['treatmentGiven'], isNull);

    // 3. Rogi Pariksha (strictly inside rogiPariksha, not duplicated at root)
    expect(payload['rogiPariksha'], isA<Map<String, dynamic>>());
    expect(payload['rogiPariksha']['prakriti'], 'Vata-Pitta');
    expect(payload['rogiPariksha']['desha'], 'Sadharan');
    expect(payload['prakriti'], isNull);
    expect(payload['desha'], isNull);

    // 4. Demographics & Hospital Info & Clinical Info (no duplicate keys)
    expect(payload['demographics']['fullName'], 'John Doe');
    expect(payload['demographics']['phoneNo'], '9876543210');
    expect(payload['demographics']['name'], isNull);
    expect(payload['demographics']['phone'], isNull);

    expect(payload['hospitalInfo']['clinicalDiseaseSelection'], 'Amavata');
    expect(payload['hospitalInfo']['opdNumber'], 'OPD-101');
    expect(payload['hospitalInfo']['opdNo'], isNull);
    expect(payload['hospitalInfo']['diagnosis'], isNull);

    // ClinicalInformation is only sent once as PascalCase, not lowercase
    expect(payload['ClinicalInformation']['chiefComplaints'], 'Joint stiffness and pain');
    expect(payload['ClinicalInformation']['historyOfPresentIllness'], 'Started 3 months ago');
    expect(payload['ClinicalInformation']['historyPresentIllness'], isNull);
    expect(payload['clinicalInformation'], isNull);

    // Personal History has ahara, not diet
    expect(payload['personalHistory']['ahara'], 'Veg');
    expect(payload['personalHistory']['diet'], isNull);

    // 5. PatientModel serialization and deserialization
    final json = patient.toJson();
    final fromJsonPatient = PatientModel.fromJson(json);
    expect(fromJsonPatient.pathologicalRadiological, 'CBC: Hb 11.2, ESR 45. X-Ray: Reduced joint space.');
    expect(fromJsonPatient.desha, 'Sadharana (Normal)');
    expect(fromJsonPatient.prakriti, 'Vata-Pitta');
  });

  test('ApiService extracts PDF filename from Content-Disposition header correctly', () {
    // 1. Quoted filename
    expect(
      ApiService.extractFileNameFromContentDisposition('attachment; filename="John_Doe_Report.pdf"'),
      'John_Doe_Report.pdf',
    );

    // 2. Unquoted filename
    expect(
      ApiService.extractFileNameFromContentDisposition('attachment; filename=Charlie_Report.pdf'),
      'Charlie_Report.pdf',
    );

    // 3. RFC 5987 / UTF-8 encoded filename
    expect(
      ApiService.extractFileNameFromContentDisposition("attachment; filename*=UTF-8''Dr%20Smith%20Report.pdf"),
      'Dr Smith Report.pdf',
    );

    // 4. Null and empty fallback
    expect(
      ApiService.extractFileNameFromContentDisposition(null, fallback: 'Custom_Fallback.pdf'),
      'Custom_Fallback.pdf',
    );
    expect(
      ApiService.extractFileNameFromContentDisposition('', fallback: 'Custom_Fallback.pdf'),
      'Custom_Fallback.pdf',
    );

    // 5. Sanitizes illegal filename characters
    expect(
      ApiService.extractFileNameFromContentDisposition('filename="John/Doe:Report?.pdf"'),
      'John_Doe_Report_.pdf',
    );
  });
}

