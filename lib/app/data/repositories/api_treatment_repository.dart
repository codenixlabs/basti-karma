import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/patient/basti_schedule_day_model.dart';
import '../models/patient/basti_session_model.dart';
import '../models/patient/basti_treatment_plan_model.dart';
import '../models/patient/treatment_status.dart';
import '../sources/local_treatment_data_source.dart';
import 'api_master_repository.dart';
import 'api_pradhana_karma_repository.dart';
import 'treatment_plan_repository.dart';

/// Backend-driven implementation of [TreatmentPlanRepository].
///
/// Communicates directly with the backend API via [ApiPradhanaKarmaRepository].
/// Maintains a purely transient in-memory store for active session speed, with
/// zero local disk or SharedPreferences persistence.
class ApiTreatmentRepository implements TreatmentPlanRepository {
  final ApiPradhanaKarmaRepository _pradhanaRepo;
  final LocalTreatmentDataSource _inMemoryStore;

  // Cache mapping planId -> patientId for session operations
  final Map<String, String> _planToPatientId = {};

  ApiTreatmentRepository({
    ApiPradhanaKarmaRepository? pradhanaRepo,
    LocalTreatmentDataSource? inMemoryStore,
  })  : _pradhanaRepo = pradhanaRepo ??
            (Get.isRegistered<ApiPradhanaKarmaRepository>()
                ? Get.find<ApiPradhanaKarmaRepository>()
                : ApiPradhanaKarmaRepository()),
        _inMemoryStore = inMemoryStore ?? LocalTreatmentDataSource();

  // ── Plan conversion helper ──────────────────────────────────────────────────

  BastiTreatmentPlanModel? _parsePlanFromBackend(
    String patientId,
    Map<String, dynamic> data,
    [BastiTreatmentPlanModel? inMemPlan]
  ) {
    // Verify Pradhana Karma was actually configured in backend
    final rawPatternCode = data['bastiPatternCode']?.toString().trim();
    final rawFormulation = data['bastiFormulationId'];
    final rawObservations = data['observation']?['dailyObservations'];
    final hasObservations = rawObservations is List &&
        rawObservations.any((d) =>
            d is Map &&
            (d['status']?.toString().toUpperCase() == 'COMPLETED' ||
                d['timeAdministered'] != null));
    final hasFormulation = rawFormulation != null &&
        (rawFormulation is String
            ? rawFormulation.isNotEmpty
            : (rawFormulation is Map && rawFormulation.isNotEmpty));
    final hasPattern = rawPatternCode != null && rawPatternCode.isNotEmpty;

    // If neither pattern, formulation, nor completed observation exists, no plan was configured!
    if (!hasPattern && !hasFormulation && !hasObservations) {
      return null;
    }

    final planId = data['_id']?.toString() ?? data['id']?.toString() ?? 'plan_$patientId';
    _planToPatientId[planId] = patientId;

    // Disease
    String diseaseId = '';
    String diseaseName = '';
    final dRaw = data['diseaseId'];
    if (dRaw is Map) {
      diseaseId = dRaw['_id']?.toString() ?? dRaw['id']?.toString() ?? '';
      diseaseName = dRaw['diseaseName']?.toString() ?? dRaw['name']?.toString() ?? '';
    } else if (dRaw is String) {
      diseaseId = dRaw;
      diseaseName = data['diseaseName']?.toString() ?? data['disease']?.toString() ?? '';
    }

    if (diseaseName.isEmpty && diseaseId.isNotEmpty && Get.isRegistered<ApiMasterRepository>()) {
      final master = Get.find<ApiMasterRepository>();
      final cached = master.cachedDiseases;
      if (cached != null) {
        final dLower = diseaseId.toLowerCase();
        final match = cached.firstWhereOrNull(
          (d) =>
              d.id.toLowerCase() == dLower ||
              (d.mongoId != null && d.mongoId!.toLowerCase() == dLower) ||
              d.name.toLowerCase() == dLower,
        );
        if (match != null) {
          diseaseName = match.name;
        }
      }
    }

    // Formulation
    String bastiOptionId = '';
    String bastiName = '';
    final fRaw = data['bastiFormulationId'];
    if (fRaw is Map) {
      bastiOptionId = fRaw['_id']?.toString() ?? fRaw['id']?.toString() ?? '';
      bastiName = fRaw['formulationName']?.toString() ?? fRaw['name']?.toString() ?? '';
    } else if (fRaw is String) {
      bastiOptionId = fRaw;
      bastiName = data['formulationName']?.toString() ?? data['bastiName']?.toString() ?? '';
    }

    final patternCode = data['bastiPatternCode']?.toString().toLowerCase() ?? 'yoga';
    final patternName = data['patternName']?.toString() ?? '${patternCode.toUpperCase()} Basti';

    // Sequence & Schedule Days
    final scheduleDays = <BastiScheduleDayModel>[];

    // 1. If backend already provides scheduleDays
    if (data['scheduleDays'] is List && (data['scheduleDays'] as List).isNotEmpty) {
      for (final item in (data['scheduleDays'] as List)) {
        if (item is Map) {
          scheduleDays.add(
            BastiScheduleDayModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    } else if (inMemPlan != null && inMemPlan.scheduleDays.isNotEmpty && inMemPlan.selectedPatternCode.toLowerCase().trim() == patternCode) {
      // Use existing configured schedule days if available and pattern matches
      scheduleDays.addAll(inMemPlan.scheduleDays);
    }

    // 2. If scheduleDays is empty, resolve sequence and construct days
    if (scheduleDays.isEmpty) {
      List<String> seq = [];
      if (data['sequence'] is List && (data['sequence'] as List).isNotEmpty) {
        seq = (data['sequence'] as List).map((e) => e.toString().toUpperCase()).toList();
      }

      final totalDaysRaw = data['totalDays'];
      final int? parsedTotalDays = totalDaysRaw is int
          ? totalDaysRaw
          : int.tryParse(totalDaysRaw?.toString() ?? '');

      if (seq.isEmpty) {
        final code = patternCode.toLowerCase().trim();
        if (code.contains('karma') || parsedTotalDays == 30) {
          seq = const [
            'A', 'N', 'A', 'N', 'A', 'N', 'A', 'N', 'A', 'N',
            'A', 'N', 'A', 'N', 'A', 'N', 'A', 'N', 'A', 'N',
            'A', 'N', 'A', 'N', 'A', 'A', 'A', 'A', 'A', 'A',
          ];
        } else if (code.contains('kala') || parsedTotalDays == 15 || parsedTotalDays == 16) {
          if (parsedTotalDays == 15) {
            seq = const [
              'A', 'N', 'A', 'N', 'A', 'N', 'A', 'N', 'A', 'N',
              'A', 'N', 'A', 'A', 'A',
            ];
          } else {
            seq = const [
              'A', 'N', 'A', 'N', 'A', 'N', 'A', 'N', 'A', 'N',
              'A', 'N', 'A', 'A', 'A', 'A',
            ];
          }
        } else {
          // Default to Yoga Basti (8 days)
          seq = const ['A', 'N', 'A', 'N', 'A', 'N', 'A', 'A'];
        }
      }

      if (parsedTotalDays != null &&
          parsedTotalDays > 0 &&
          seq.length != parsedTotalDays &&
          !patternCode.contains('yoga') &&
          !patternCode.contains('kala') &&
          !patternCode.contains('karma')) {
        seq = List.generate(parsedTotalDays, (i) => i.isEven ? 'A' : 'N');
      }

      final completedDays = <int>{};
      final dayBastiTypes = <int, String>{};
      final obs = data['observation'];
      if (obs is Map && obs['dailyObservations'] is List) {
        final dailyList = obs['dailyObservations'] as List;
        for (final d in dailyList) {
          if (d is Map) {
            final day = d['day'] as int? ?? (d['dayNumber'] as int? ?? 0);
            if (day > 0) {
              if (d['status']?.toString().toUpperCase() == 'COMPLETED') {
                completedDays.add(day);
              }
              if (d['bastiType'] != null) {
                dayBastiTypes[day] = d['bastiType'].toString().toUpperCase();
              }
            }
          }
        }
      }

      final bala = (data['patientBala'] as String?)?.toLowerCase() ??
          (data['bala'] as String?)?.toLowerCase() ??
          'madhyama';
      final defaultNiruha = bala == 'pravara'
          ? 600.0
          : (bala == 'madhyama' ? 480.0 : 360.0);
      final defaultAnuvasana = bala == 'pravara'
          ? 100.0
          : (bala == 'madhyama' ? 80.0 : 60.0);

      final niruhaDose = (data['calculatedNiruhaDose'] as num?)?.toDouble() ?? defaultNiruha;
      final anuvasanaDose = (data['calculatedAnuvasanaDose'] as num?)?.toDouble() ?? defaultAnuvasana;

      for (int i = 0; i < seq.length; i++) {
        final dayNumber = i + 1;
        final code = (dayBastiTypes[dayNumber] ?? seq[i]).trim().toUpperCase();
        final String scheduledType;
        final double scheduledDose;
        final String compSummary;

        if (code == 'MB') {
          scheduledType = 'Matra Basti';
          scheduledDose = (anuvasanaDose > 60) ? (anuvasanaDose / 2) : anuvasanaDose;
          compSummary = bastiName.isNotEmpty ? '$bastiName (Matra Basti)' : 'Matra Sneha Dravya';
        } else if (code == 'YB') {
          scheduledType = 'Yapana Basti';
          scheduledDose = niruhaDose;
          compSummary = bastiName.isNotEmpty ? '$bastiName (Yapana Basti)' : 'Yapana Formulation';
        } else if (code == 'N') {
          scheduledType = 'Niruha';
          scheduledDose = niruhaDose;
          compSummary = bastiName.isNotEmpty ? bastiName : 'Niruha Formulation';
        } else {
          scheduledType = 'Anuvasana';
          scheduledDose = anuvasanaDose;
          compSummary = 'Sneha Dravya';
        }

        scheduleDays.add(
          BastiScheduleDayModel(
            dayNumber: dayNumber,
            scheduledBastiType: scheduledType,
            bastiTypeCodeShort: code,
            scheduledDose: scheduledDose,
            doseUnit: 'ml',
            compositionSummary: compSummary,
            isCompleted: completedDays.contains(dayNumber),
          ),
        );
      }
    }

    // Status
    final statusStr = data['treatmentStatus']?.toString().toUpperCase();
    TreatmentStatus status = TreatmentStatus.draft;
    if (statusStr == 'COMPLETED') {
      status = TreatmentStatus.completed;
    } else if (statusStr == 'IN_PROGRESS' || statusStr == 'ACTIVE') {
      status = TreatmentStatus.active;
    } else {
      // Check if any daily observation is completed
      final obs = data['observation'];
      if (obs is Map && obs['dailyObservations'] is List) {
        final dailyList = obs['dailyObservations'] as List;
        final hasCompleted = dailyList.any((d) =>
            d is Map && (d['status']?.toString().toUpperCase() == 'COMPLETED'));
        status = hasCompleted ? TreatmentStatus.active : TreatmentStatus.draft;
      }
    }

    if (scheduleDays.isNotEmpty && scheduleDays.every((d) => d.isCompleted)) {
      status = TreatmentStatus.completed;
    }

    DateTime? startDate;
    if (data['startDate'] != null) {
      startDate = DateTime.tryParse(data['startDate'].toString());
    }

    final balaStr = (data['patientBala'] as String?) ??
        (data['bala'] as String?) ??
        'Madhyama';
    final fallbackNiruha = balaStr.toLowerCase() == 'pravara'
        ? 600.0
        : (balaStr.toLowerCase() == 'madhyama' ? 480.0 : 360.0);
    final fallbackAnuvasana = balaStr.toLowerCase() == 'pravara'
        ? 100.0
        : (balaStr.toLowerCase() == 'madhyama' ? 80.0 : 60.0);
    final planNiruhaDose = (data['calculatedNiruhaDose'] as num?)?.toDouble() ?? fallbackNiruha;
    final planAnuvasanaDose = (data['calculatedAnuvasanaDose'] as num?)?.toDouble() ?? fallbackAnuvasana;

    return BastiTreatmentPlanModel(
      id: planId,
      patientId: patientId,
      diseaseId: diseaseId,
      diseaseName: diseaseName,
      bastiOptionId: bastiOptionId,
      bastiName: bastiName,
      patientBala: balaStr,
      selectedPatternCode: patternCode,
      selectedPatternName: patternName,
      calculatedNiruhaDose: planNiruhaDose,
      calculatedAnuvasanaDose: planAnuvasanaDose,
      scheduleDays: scheduleDays,
      status: status,
      startDate: startDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ── Plan methods ────────────────────────────────────────────────────────────

  @override
  Future<String> createTreatmentPlan(BastiTreatmentPlanModel plan) async {
    _inMemoryStore.savePlan(plan);
    if (plan.patientId != null) {
      _planToPatientId[plan.id] = plan.patientId!;
      final hex24 = RegExp(r'^[0-9a-fA-F]{24}$');
      String dId = plan.diseaseId;
      String fId = plan.bastiOptionId;

      if ((!hex24.hasMatch(dId) || !hex24.hasMatch(fId)) && Get.isRegistered<ApiMasterRepository>()) {
        final master = Get.find<ApiMasterRepository>();
        if (!hex24.hasMatch(dId)) {
          final d = await master.getDiseaseById(dId);
          if (d?.mongoId != null && hex24.hasMatch(d!.mongoId!)) {
            dId = d.mongoId!;
          }
        }
      }

      if (hex24.hasMatch(dId) && hex24.hasMatch(fId)) {
        try {
          await _pradhanaRepo.initializeOrUpdatePradhanaKarma(
            plan.patientId!,
            diseaseId: dId,
            bastiPatternCode: plan.selectedPatternCode,
            bastiFormulationId: fId,
            startDate: plan.startDate ?? DateTime.now(),
            treatmentStatus: plan.status == TreatmentStatus.completed
                ? 'COMPLETED'
                : (plan.status == TreatmentStatus.active ? 'IN_PROGRESS' : 'PLANNED'),
          );
        } catch (e) {
          debugPrint('ApiTreatmentRepository.createTreatmentPlan error: $e');
        }
      }
    }
    return plan.id;
  }

  @override
  Future<BastiTreatmentPlanModel?> getTreatmentPlan(String id) async {
    final patientId = _planToPatientId[id];
    if (patientId != null) {
      final active = await getActivePlanForPatient(patientId);
      if (active != null && active.id == id) return active;
    }
    final json = await _inMemoryStore.fetchPlan(id);
    if (json != null) return BastiTreatmentPlanModel.fromJson(json);
    return null;
  }

  @override
  Future<void> updateTreatmentPlan(BastiTreatmentPlanModel plan) async {
    _inMemoryStore.updatePlan(plan);
    if (plan.patientId != null) {
      _planToPatientId[plan.id] = plan.patientId!;
      final hex24 = RegExp(r'^[0-9a-fA-F]{24}$');
      String dId = plan.diseaseId;
      String fId = plan.bastiOptionId;

      if ((!hex24.hasMatch(dId) || !hex24.hasMatch(fId)) && Get.isRegistered<ApiMasterRepository>()) {
        final master = Get.find<ApiMasterRepository>();
        if (!hex24.hasMatch(dId)) {
          final d = await master.getDiseaseById(dId);
          if (d?.mongoId != null && hex24.hasMatch(d!.mongoId!)) {
            dId = d.mongoId!;
          }
        }
      }

      if (hex24.hasMatch(dId) && hex24.hasMatch(fId)) {
        try {
          await _pradhanaRepo.initializeOrUpdatePradhanaKarma(
            plan.patientId!,
            diseaseId: dId,
            bastiPatternCode: plan.selectedPatternCode,
            bastiFormulationId: fId,
            startDate: plan.startDate ?? DateTime.now(),
            treatmentStatus: plan.status == TreatmentStatus.completed
                ? 'COMPLETED'
                : (plan.status == TreatmentStatus.active ? 'IN_PROGRESS' : 'PLANNED'),
          );
        } catch (e) {
          debugPrint('ApiTreatmentRepository.updateTreatmentPlan error: $e');
        }
      }
    }
  }

  @override
  Future<List<BastiTreatmentPlanModel>> getPlansForPatient(
    String patientId,
  ) async {
    try {
      final model = await _pradhanaRepo.getPradhanaKarma(patientId);
      if (model != null && model.rawJson != null) {
        final data = model.rawJson!['data'] is Map
            ? Map<String, dynamic>.from(model.rawJson!['data'] as Map)
            : model.rawJson!;
        final inMemPlans = await _inMemoryStore.fetchPlansForPatient(patientId);
        final existingPlanJson = inMemPlans.isNotEmpty ? inMemPlans.first : null;
        final existingPlan = existingPlanJson != null ? BastiTreatmentPlanModel.fromJson(existingPlanJson) : null;
        
        final plan = _parsePlanFromBackend(patientId, data, existingPlan);
        if (plan != null) {
          _inMemoryStore.savePlan(plan);
          return [plan];
        } else {
          return [];
        }
      }
    } catch (e) {
      debugPrint('ApiTreatmentRepository.getPlansForPatient error: $e');
    }

    final inMem = await _inMemoryStore.fetchPlansForPatient(patientId);
    return inMem
        .map(BastiTreatmentPlanModel.fromJson)
        .where((p) => p.bastiName.isNotEmpty || p.scheduleDays.any((d) => d.isCompleted))
        .toList();
  }

  @override
  Future<BastiTreatmentPlanModel?> getActivePlanForPatient(
    String patientId,
  ) async {
    final plans = await getPlansForPatient(patientId);
    for (final plan in plans) {
      if (plan.status == TreatmentStatus.active) {
        return plan;
      }
    }
    return null;
  }

  @override
  Future<BastiTreatmentPlanModel?> getDraftPlanForPatient(
    String patientId,
  ) async {
    final plans = await getPlansForPatient(patientId);
    for (final plan in plans) {
      if (plan.status == TreatmentStatus.draft) {
        return plan;
      }
    }
    return null;
  }

  // ── Session methods ─────────────────────────────────────────────────────────

  @override
  Future<List<BastiSessionModel>> getSessions(String treatmentPlanId) async {
    final patientId = _planToPatientId[treatmentPlanId];
    if (patientId != null) {
      try {
        final model = await _pradhanaRepo.getPradhanaKarma(patientId);
        if (model != null && model.rawJson != null) {
          final data = model.rawJson!['data'] is Map
              ? Map<String, dynamic>.from(model.rawJson!['data'] as Map)
              : model.rawJson!;

          final obs = data['observation'];
          if (obs is Map && obs['dailyObservations'] is List) {
            final dailyList = obs['dailyObservations'] as List;
            final sessionsByDay = <int, BastiSessionModel>{};

            for (final item in dailyList) {
              if (item is Map) {
                final rawDay = item['day'] ?? item['dayNumber'];
                final dayNum = rawDay is int
                    ? rawDay
                    : int.tryParse(rawDay?.toString() ?? '') ?? 1;
                final statusStr = item['status']?.toString().toUpperCase() ?? 'PENDING';
                final isCompleted = statusStr == 'COMPLETED';

                // Resolve symptoms map (supports both flat and nested 'symptoms' key)
                final symptomMap = (item['symptoms'] is Map)
                    ? Map<String, dynamic>.from(item['symptoms'] as Map)
                    : Map<String, dynamic>.from(item);

                // Determine whether this day was Niruha or Anuvasana
                String? bastiCode = item['bastiType']?.toString().toUpperCase();
                if (bastiCode == null || bastiCode.isEmpty) {
                  if (symptomMap['bastiType'] != null) {
                    bastiCode = symptomMap['bastiType'].toString().toUpperCase();
                  }
                  // Fallback 1: check scheduleDays from plan or rawJson
                  if ((bastiCode == null || bastiCode.isEmpty) && data['scheduleDays'] is List) {
                    final sDays = data['scheduleDays'] as List;
                    for (final sd in sDays) {
                      if (sd is Map && (sd['dayNumber'] == dayNum || sd['day'] == dayNum)) {
                        bastiCode = sd['bastiTypeCodeShort']?.toString().toUpperCase();
                        break;
                      }
                    }
                  }
                  // Fallback 2: check sequence
                  if ((bastiCode == null || bastiCode.isEmpty) && data['sequence'] is List) {
                    final seq = data['sequence'] as List;
                    if (dayNum >= 1 && dayNum <= seq.length) {
                      bastiCode = seq[dayNum - 1]?.toString().toUpperCase();
                    }
                  }
                  // Fallback 3: check presence of Niruha-specific symptoms
                  if (bastiCode == null || bastiCode.isEmpty) {
                    final hasNiruhaKey = symptomMap['prasristaVinaMutra'] == true ||
                        symptomMap['sameerantwama'] == true ||
                        symptomMap['ashayaLaghava'] == true ||
                        symptomMap['rogashanti'] == true ||
                        symptomMap['prakritiBala'] == true ||
                        symptomMap['siroHridGudaVedana'] == true ||
                        symptomMap['siroHridGudaBastiMedhraVedana'] == true ||
                        symptomMap['kaphaPittaVataRaktaKshayajVikara'] == true ||
                        symptomMap['angamarda'] == true ||
                        symptomMap['vepathu'] == true;
                    bastiCode = hasNiruhaKey ? 'N' : 'A';
                  }
                }

                final isKwathaBased = bastiCode == 'N' ||
                    bastiCode == 'NIRUHA' ||
                    bastiCode == 'YB' ||
                    bastiCode == 'YAPANA';

                final String scheduledType;
                final String shortCode;
                final double defaultDose;

                if (bastiCode == 'MB' || bastiCode == 'MATRA') {
                  scheduledType = 'Matra Basti';
                  shortCode = 'MB';
                  defaultDose = 50.0;
                } else if (bastiCode == 'YB' || bastiCode == 'YAPANA') {
                  scheduledType = 'Yapana Basti';
                  shortCode = 'YB';
                  defaultDose = 400.0;
                } else if (isKwathaBased) {
                  scheduledType = 'Niruha';
                  shortCode = 'N';
                  defaultDose = 400.0;
                } else {
                  scheduledType = 'Anuvasana';
                  shortCode = 'A';
                  defaultDose = 100.0;
                }

                final samyaka = isCompleted
                    ? (isKwathaBased
                        ? [
                            symptomMap['prasristaVinaMutra'] == true,
                            symptomMap['sameerantwama'] == true,
                            symptomMap['agniVriddhi'] == true,
                            symptomMap['ruchi'] == true,
                            symptomMap['ashayaLaghava'] == true,
                            symptomMap['rogashanti'] == true,
                            symptomMap['prakriti'] == true || symptomMap['prakritiBala'] == true,
                          ]
                        : [
                            symptomMap['sapurishaSnehaPratyeti'] == true,
                            symptomMap['shariraLaghavta'] == true,
                            symptomMap['bala'] == true,
                            symptomMap['srustachVega'] == true,
                            symptomMap['vatanulomana'] == true,
                            symptomMap['agnidipta'] == true,
                          ])
                    : List<bool>.filled(isKwathaBased ? 7 : 6, false);

                final ayoga = isCompleted
                    ? (isKwathaBased
                        ? [
                            symptomMap['siroHridGudaVedana'] == true ||
                                symptomMap['siroHridGudaBastiMedhraVedana'] == true,
                            symptomMap['sopha'] == true,
                            symptomMap['pratishyaya'] == true,
                            symptomMap['vikartika'] == true,
                            symptomMap['hrullasa'] == true,
                            symptomMap['marutaSanga'] == true,
                            symptomMap['mutraSanga'] == true,
                            symptomMap['shvaskashta'] == true,
                          ]
                        : [
                            symptomMap['adhaSariraRuja'] == true ||
                                symptomMap['adhaShariraRuja'] == true,
                            symptomMap['udaraRuja'] == true,
                            symptomMap['bahuPrushthaRuja'] == true,
                            symptomMap['parshvaRuja'] == true,
                            symptomMap['rukshaGatra'] == true,
                            symptomMap['rukshaSvara'] == true,
                            symptomMap['vitSanga'] == true,
                            symptomMap['mutraSanga'] == true,
                          ])
                    : List<bool>.filled(8, false);

                final isKlamaSelected = symptomMap['klama'] == true ||
                    symptomMap['kalma'] == true ||
                    item['klama'] == true ||
                    item['kalma'] == true;

                final atiyoga = isCompleted
                    ? (isKwathaBased
                        ? [
                            symptomMap['kaphaPittaVataRaktaKshayajVikara'] == true || item['kaphaPittaVataRaktaKshayajVikara'] == true,
                            symptomMap['supti'] == true || item['supti'] == true,
                            symptomMap['angamarda'] == true || item['angamarda'] == true,
                            isKlamaSelected,
                            symptomMap['vepathu'] == true || item['vepathu'] == true,
                            symptomMap['nidraNasha'] == true || item['nidraNasha'] == true,
                            symptomMap['balaNasha'] == true || item['balaNasha'] == true,
                            symptomMap['tamaPravesha'] == true || item['tamaPravesha'] == true,
                            symptomMap['unmada'] == true || item['unmada'] == true,
                            symptomMap['hikka'] == true || item['hikka'] == true,
                          ]
                        : [
                            symptomMap['hrullasa'] == true || item['hrullasa'] == true,
                            symptomMap['moha'] == true || item['moha'] == true,
                            isKlamaSelected,
                            symptomMap['sada'] == true || item['sada'] == true,
                            symptomMap['murchha'] == true || item['murchha'] == true,
                            symptomMap['vikartika'] == true || item['vikartika'] == true,
                          ])
                    : List<bool>.filled(isKwathaBased ? 10 : 6, false);

                final rawUpdated = item['updatedAt'] ?? item['date'] ?? data['updatedAt'];
                final itemUpdatedAt = rawUpdated != null
                    ? (DateTime.tryParse(rawUpdated.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0))
                    : DateTime.fromMillisecondsSinceEpoch(0);

                String parsedPratyagamana = item['pratyagamana']?.toString() ??
                    symptomMap['pratyagamana']?.toString() ??
                    '';
                if (parsedPratyagamana.isEmpty && item['notes'] != null) {
                  final match = RegExp(r'Pratyagamana:\s*([^|]+)').firstMatch(item['notes'].toString());
                  if (match != null) {
                    parsedPratyagamana = match.group(1)?.trim() ?? '';
                  }
                }

                String parsedVega = item['vega']?.toString() ?? '';
                if (parsedVega.isEmpty && item['notes'] != null) {
                  final match = RegExp(r'Vega:\s*([^|]+)').firstMatch(item['notes'].toString());
                  if (match != null) {
                    parsedVega = match.group(1)?.trim() ?? '';
                  } else if (!item['notes'].toString().contains('Pratyagamana:')) {
                    parsedVega = item['notes'].toString().replaceFirst(RegExp(r'^Vega:\s*'), '').trim();
                  }
                }

                String parsedNiruhaVyapada = '';
                String parsedAnuvasanaVyapada = '';
                if (item['paschataKarma'] != null && item['paschataKarma']['vyapadaAndManagement'] != null) {
                  final vyapada = item['paschataKarma']['vyapadaAndManagement'];
                  parsedNiruhaVyapada = vyapada['niruhaVyapada']?.toString() ?? '';
                  parsedAnuvasanaVyapada = vyapada['anuvasanaVyapada']?.toString() ?? '';
                }

                final session = BastiSessionModel(
                  id: 'session_${treatmentPlanId}_day$dayNum',
                  treatmentPlanId: treatmentPlanId,
                  dayNumber: dayNum,
                  scheduledBastiType: scheduledType,
                  bastiTypeCodeShort: shortCode,
                  scheduledDose: defaultDose,
                  doseUnit: 'ml',
                  status: isCompleted ? SessionStatus.completed : SessionStatus.pending,
                  adanaKala: isCompleted ? (item['timeAdministered']?.toString() ?? '') : '',
                  pratyagamana: isCompleted ? parsedPratyagamana : '',
                  vega: isCompleted ? parsedVega : '',
                  samyakaSelected: samyaka,
                  ayogaSelected: ayoga,
                  atiyogaSelected: atiyoga,
                  niruhaVyapada: parsedNiruhaVyapada,
                  anuvasanaVyapada: parsedAnuvasanaVyapada,
                  createdAt: itemUpdatedAt,
                  updatedAt: itemUpdatedAt,
                );

                final existing = sessionsByDay[dayNum];
                if (existing == null || isCompleted || !existing.isCompleted) {
                  sessionsByDay[dayNum] = session;
                }
              }
            }

            // Sync with _inMemoryStore and check for more recent in-memory sessions
            for (final dayNum in sessionsByDay.keys.toList()) {
              final backendSession = sessionsByDay[dayNum]!;
              final inMemJson = await _inMemoryStore.fetchSession(treatmentPlanId, dayNum);
              if (inMemJson != null) {
                final inMemSession = BastiSessionModel.fromJson(inMemJson);
                if (inMemSession.isCompleted) {
                  // Merge symptoms: preserve any symptom selected in inMemSession that backend might have stripped
                  final mergedAtiyoga = List<bool>.generate(
                    backendSession.atiyogaSelected.length,
                    (i) => backendSession.atiyogaSelected[i] ||
                        (i < inMemSession.atiyogaSelected.length && inMemSession.atiyogaSelected[i]),
                  );
                  final mergedSamyaka = List<bool>.generate(
                    backendSession.samyakaSelected.length,
                    (i) => backendSession.samyakaSelected[i] ||
                        (i < inMemSession.samyakaSelected.length && inMemSession.samyakaSelected[i]),
                  );
                  final mergedAyoga = List<bool>.generate(
                    backendSession.ayogaSelected.length,
                    (i) => backendSession.ayogaSelected[i] ||
                        (i < inMemSession.ayogaSelected.length && inMemSession.ayogaSelected[i]),
                  );
                  final mergedSession = backendSession.copyWith(
                    adanaKala: backendSession.adanaKala.isNotEmpty
                        ? backendSession.adanaKala
                        : inMemSession.adanaKala,
                    pratyagamana: backendSession.pratyagamana.isNotEmpty
                        ? backendSession.pratyagamana
                        : inMemSession.pratyagamana,
                    vega: backendSession.vega.isNotEmpty
                        ? backendSession.vega
                        : inMemSession.vega,
                    samyakaSelected: mergedSamyaka,
                    ayogaSelected: mergedAyoga,
                    atiyogaSelected: mergedAtiyoga,
                    niruhaVyapada: backendSession.niruhaVyapada.isNotEmpty
                        ? backendSession.niruhaVyapada
                        : inMemSession.niruhaVyapada,
                    anuvasanaVyapada: backendSession.anuvasanaVyapada.isNotEmpty
                        ? backendSession.anuvasanaVyapada
                        : inMemSession.anuvasanaVyapada,
                    updatedAt: inMemSession.updatedAt.isAfter(backendSession.updatedAt)
                        ? inMemSession.updatedAt
                        : backendSession.updatedAt,
                  );
                  sessionsByDay[dayNum] = mergedSession;
                  _inMemoryStore.saveSession(mergedSession);
                  continue;
                }
              }
              _inMemoryStore.saveSession(backendSession);
            }

            final sessions = sessionsByDay.values.toList()
              ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
            if (sessions.isNotEmpty) return sessions;
          }
        }
      } catch (e) {
        debugPrint('ApiTreatmentRepository.getSessions error: $e');
      }
    }

    final jsonList = await _inMemoryStore.fetchAllSessions(treatmentPlanId);
    return jsonList.map(BastiSessionModel.fromJson).toList();
  }

  @override
  Future<BastiSessionModel?> getSession(
    String treatmentPlanId,
    int dayNumber,
  ) async {
    final inMemJson = await _inMemoryStore.fetchSession(treatmentPlanId, dayNumber);
    final inMemSession = inMemJson != null ? BastiSessionModel.fromJson(inMemJson) : null;

    final sessions = await getSessions(treatmentPlanId);
    for (final s in sessions) {
      if (s.dayNumber == dayNumber) {
        if (inMemSession != null &&
            inMemSession.isCompleted &&
            inMemSession.updatedAt.isAfter(s.updatedAt)) {
          return inMemSession;
        }
        if (inMemSession != null && inMemSession.isCompleted) {
          return s.copyWith(
            adanaKala: s.adanaKala.isNotEmpty ? s.adanaKala : inMemSession.adanaKala,
            pratyagamana: s.pratyagamana.isNotEmpty ? s.pratyagamana : inMemSession.pratyagamana,
            vega: s.vega.isNotEmpty ? s.vega : inMemSession.vega,
            niruhaVyapada: s.niruhaVyapada.isNotEmpty ? s.niruhaVyapada : inMemSession.niruhaVyapada,
            anuvasanaVyapada: s.anuvasanaVyapada.isNotEmpty ? s.anuvasanaVyapada : inMemSession.anuvasanaVyapada,
          );
        }
        return s;
      }
    }
    return inMemSession;
  }

  Map<String, dynamic> _buildSymptomsMap(BastiSessionModel session) {
    final symptoms = <String, dynamic>{};
    final isKwatha = session.isKwathaBased ||
        session.scheduledBastiType.toLowerCase().contains('niruha') ||
        session.scheduledBastiType.toLowerCase().contains('yapana') ||
        session.bastiTypeCodeShort.toUpperCase() == 'N' ||
        session.bastiTypeCodeShort.toUpperCase() == 'YB';

    if (isKwatha) {
      // Niruha Samyaka (7)
      const sKeys = [
        'prasristaVinaMutra',
        'sameerantwama',
        'agniVriddhi',
        'ruchi',
        'ashayaLaghava',
        'rogashanti',
        'prakriti',
      ];
      for (int i = 0; i < sKeys.length && i < session.samyakaSelected.length; i++) {
        symptoms[sKeys[i]] = session.samyakaSelected[i];
      }
      if (session.samyakaSelected.length >= 7) {
        symptoms['prakritiBala'] = session.samyakaSelected[6];
      }

      // Niruha Ayoga (8)
      const aKeys = [
        'siroHridGudaVedana',
        'sopha',
        'pratishyaya',
        'vikartika',
        'hrullasa',
        'marutaSanga',
        'mutraSanga',
        'shvaskashta',
      ];
      for (int i = 0; i < aKeys.length && i < session.ayogaSelected.length; i++) {
        symptoms[aKeys[i]] = session.ayogaSelected[i];
      }
      if (session.ayogaSelected.isNotEmpty) {
        symptoms['siroHridGudaBastiMedhraVedana'] = session.ayogaSelected[0];
      }

      // Niruha Atiyoga (10)
      const atKeys = [
        'kaphaPittaVataRaktaKshayajVikara',
        'supti',
        'angamarda',
        'klama',
        'vepathu',
        'nidraNasha',
        'balaNasha',
        'tamaPravesha',
        'unmada',
        'hikka',
      ];
      for (int i = 0; i < atKeys.length && i < session.atiyogaSelected.length; i++) {
        symptoms[atKeys[i]] = session.atiyogaSelected[i];
      }
      if (session.atiyogaSelected.length > 3) {
        symptoms['kalma'] = session.atiyogaSelected[3];
      }
    } else {
      // Anuvasana Samyaka (6)
      const sKeys = [
        'sapurishaSnehaPratyeti',
        'shariraLaghavta',
        'bala',
        'srustachVega',
        'vatanulomana',
        'agnidipta',
      ];
      for (int i = 0; i < sKeys.length && i < session.samyakaSelected.length; i++) {
        symptoms[sKeys[i]] = session.samyakaSelected[i];
      }

      // Anuvasana Ayoga (8)
      const aKeys = [
        'adhaSariraRuja',
        'udaraRuja',
        'bahuPrushthaRuja',
        'parshvaRuja',
        'rukshaGatra',
        'rukshaSvara',
        'vitSanga',
        'mutraSanga',
      ];
      for (int i = 0; i < aKeys.length && i < session.ayogaSelected.length; i++) {
        symptoms[aKeys[i]] = session.ayogaSelected[i];
      }
      if (session.ayogaSelected.isNotEmpty) {
        symptoms['adhaShariraRuja'] = session.ayogaSelected[0];
      }

      // Anuvasana Atiyoga (6)
      const atKeys = [
        'hrullasa',
        'moha',
        'klama',
        'sada',
        'murchha',
        'vikartika',
      ];
      for (int i = 0; i < atKeys.length && i < session.atiyogaSelected.length; i++) {
        symptoms[atKeys[i]] = session.atiyogaSelected[i];
      }
      if (session.atiyogaSelected.length > 2) {
        symptoms['kalma'] = session.atiyogaSelected[2];
      }
    }
    
    symptoms['paschataKarma'] = {
      'vyapadaAndManagement': {
        if (session.niruhaVyapada.isNotEmpty) 'niruhaVyapada': session.niruhaVyapada,
        if (session.anuvasanaVyapada.isNotEmpty) 'anuvasanaVyapada': session.anuvasanaVyapada,
      }
    };
    if (session.vega.isNotEmpty) {
      symptoms['vega'] = session.vega;
    }
    
    return symptoms;
  }

  void mapPlanToPatient(String planId, String patientId) {
    _planToPatientId[planId] = patientId;
  }

  @override
  Future<void> saveSession(BastiSessionModel session) async {
    _inMemoryStore.saveSession(session);
    String? patientId = _planToPatientId[session.treatmentPlanId];
    if (patientId == null && session.treatmentPlanId.startsWith('plan_')) {
      patientId = session.treatmentPlanId.substring('plan_'.length);
      _planToPatientId[session.treatmentPlanId] = patientId;
    }
    if (patientId == null) {
      final planJson = await _inMemoryStore.fetchPlan(session.treatmentPlanId);
      if (planJson != null && planJson['patientId'] != null) {
        patientId = planJson['patientId'].toString();
        _planToPatientId[session.treatmentPlanId] = patientId;
      }
    }

    final symptoms = _buildSymptomsMap(session);
    final doseStr = '${session.scheduledDose}${session.doseUnit}';
    final noteParts = <String>[];
    if (session.pratyagamana.isNotEmpty) {
      noteParts.add('Pratyagamana: ${session.pratyagamana}');
    }
    if (session.vega.isNotEmpty) {
      noteParts.add('Vega: ${session.vega}');
    }
    final notes = noteParts.isNotEmpty ? noteParts.join(' | ') : null;
    final shortCode = session.bastiTypeCodeShort.trim().toUpperCase();
    final bastiTypeToSend = (shortCode == 'MB' || shortCode == 'YB' || shortCode == 'N' || shortCode == 'A')
        ? shortCode
        : (session.isMatra
            ? 'MB'
            : (session.isYapana
                ? 'YB'
                : (session.isNiruha ? 'N' : 'A')));
    symptoms['bastiType'] = bastiTypeToSend;
    symptoms['pratyagamana'] = session.pratyagamana;

    final selectedInPayload = symptoms.entries
        .where((e) => e.value == true && e.key != 'bastiType' && e.key != 'pratyagamana')
        .map((e) => e.key)
        .toList();
    debugPrint('[Day ${session.dayNumber} / ${session.id}] Selected observation IDs in update payload: $selectedInPayload');

    final selectedStored = session.selectedObservationIds;
    debugPrint('[Day ${session.dayNumber} / ${session.id}] Selected observation IDs actually stored: $selectedStored');

    if (patientId != null) {
      try {
        await _pradhanaRepo.addDailyObservation(
          patientId,
          day: session.dayNumber,
          status: 'COMPLETED',
          bastiType: bastiTypeToSend,
          dose: doseStr,
          timeAdministered: session.adanaKala.isNotEmpty ? session.adanaKala : null,
          pratyagamana: session.pratyagamana.isNotEmpty ? session.pratyagamana : null,
          notes: notes,
          symptoms: symptoms,
        );
      } catch (e) {
        debugPrint('ApiTreatmentRepository.saveSession error: $e');
        rethrow;
      }
    } else {
      throw Exception('Could not resolve patientId for session ${session.id}');
    }
  }

  @override
  Future<void> updateSession(BastiSessionModel session) async {
    _inMemoryStore.saveSession(session);
    String? patientId = _planToPatientId[session.treatmentPlanId];
    if (patientId == null && session.treatmentPlanId.startsWith('plan_')) {
      patientId = session.treatmentPlanId.substring('plan_'.length);
      _planToPatientId[session.treatmentPlanId] = patientId;
    }
    if (patientId == null) {
      final planJson = await _inMemoryStore.fetchPlan(session.treatmentPlanId);
      if (planJson != null && planJson['patientId'] != null) {
        patientId = planJson['patientId'].toString();
        _planToPatientId[session.treatmentPlanId] = patientId;
      }
    }

    final symptoms = _buildSymptomsMap(session);
    final doseStr = '${session.scheduledDose}${session.doseUnit}';
    final noteParts = <String>[];
    if (session.pratyagamana.isNotEmpty) {
      noteParts.add('Pratyagamana: ${session.pratyagamana}');
    }
    if (session.vega.isNotEmpty) {
      noteParts.add('Vega: ${session.vega}');
    }
    final notes = noteParts.isNotEmpty ? noteParts.join(' | ') : null;
    final updateShortCode = session.bastiTypeCodeShort.trim().toUpperCase();
    final updateBastiTypeToSend = (updateShortCode == 'MB' || updateShortCode == 'YB' || updateShortCode == 'N' || updateShortCode == 'A')
        ? updateShortCode
        : (session.isMatra
            ? 'MB'
            : (session.isYapana
                ? 'YB'
                : (session.isNiruha ? 'N' : 'A')));
    symptoms['bastiType'] = updateBastiTypeToSend;
    symptoms['pratyagamana'] = session.pratyagamana;

    final selectedInPayload = symptoms.entries
        .where((e) => e.value == true && e.key != 'bastiType' && e.key != 'pratyagamana')
        .map((e) => e.key)
        .toList();
    debugPrint('[Day ${session.dayNumber} / ${session.id}] Selected observation IDs in update payload: $selectedInPayload');

    final selectedStored = session.selectedObservationIds;
    debugPrint('[Day ${session.dayNumber} / ${session.id}] Selected observation IDs actually stored: $selectedStored');

    if (patientId != null) {
      try {
        final payload = <String, dynamic>{
          'status': 'COMPLETED',
          'bastiType': updateBastiTypeToSend,
          'dose': doseStr,
          if (session.adanaKala.isNotEmpty) 'timeAdministered': session.adanaKala,
          if (session.pratyagamana.isNotEmpty) 'pratyagamana': session.pratyagamana,
          'notes': notes,
          ...symptoms,
        };

        // PUT /api/pradhana-karma/:patientId/observations/:day (§5.4)
        final res = await _pradhanaRepo.updateDailyObservation(
          patientId,
          session.dayNumber,
          payload,
        );
        if (res == null) {
          // Fallback to addDailyObservation if PUT was not handled
          await _pradhanaRepo.addDailyObservation(
            patientId,
            day: session.dayNumber,
            status: 'COMPLETED',
            bastiType: updateBastiTypeToSend,
            dose: doseStr,
            timeAdministered: session.adanaKala.isNotEmpty ? session.adanaKala : null,
            pratyagamana: session.pratyagamana.isNotEmpty ? session.pratyagamana : null,
            notes: notes,
            symptoms: symptoms,
          );
        }
      } catch (e) {
        debugPrint('ApiTreatmentRepository.updateSession error: $e');
        rethrow;
      }
    } else {
      throw Exception('Could not resolve patientId for session ${session.id}');
    }
  }

  @override
  Future<void> deleteSession(String treatmentPlanId, int dayNumber) async {
    await _inMemoryStore.deleteSession(treatmentPlanId, dayNumber);

    final patientId = _planToPatientId[treatmentPlanId];
    if (patientId != null) {
      try {
        final clearedPayload = <String, dynamic>{
          'day': dayNumber,
          'status': 'PENDING',
          'timeAdministered': '',
          'pratyagamana': '',
          'notes': '',
          'dose': '',
          'bastiType': '',
          // Niruha Samyaka
          'prasristaVinaMutra': false,
          'sameerantwama': false,
          'agniVriddhi': false,
          'ruchi': false,
          'ashayaLaghava': false,
          'rogashanti': false,
          'prakriti': false,
          'prakritiBala': false,
          // Niruha Ayoga
          'siroHridGudaVedana': false,
          'siroHridGudaBastiMedhraVedana': false,
          'sopha': false,
          'pratishyaya': false,
          'vikartika': false,
          'hrullasa': false,
          'marutaSanga': false,
          'mutraSanga': false,
          'shvaskashta': false,
          // Niruha Atiyoga
          'kaphaPittaVataRaktaKshayajVikara': false,
          'supti': false,
          'angamarda': false,
          'klama': false,
          'vepathu': false,
          'nidraNasha': false,
          'balaNasha': false,
          'tamaPravesha': false,
          'unmada': false,
          'hikka': false,
          // Anuvasana Samyaka
          'sapurishaSnehaPratyeti': false,
          'shariraLaghavta': false,
          'bala': false,
          'srustachVega': false,
          'vatanulomana': false,
          'agnidipta': false,
          // Anuvasana Ayoga
          'adhaSariraRuja': false,
          'adhaShariraRuja': false,
          'udaraRuja': false,
          'bahuPrushthaRuja': false,
          'parshvaRuja': false,
          'rukshaGatra': false,
          'rukshaSvara': false,
          'vitSanga': false,
          // Anuvasana Atiyoga
          'moha': false,
          'sada': false,
          'murchha': false,
        };

        await _pradhanaRepo.updateDailyObservation(
          patientId,
          dayNumber,
          clearedPayload,
        );
      } catch (e) {
        debugPrint('ApiTreatmentRepository.deleteSession error: $e');
      }
    }
  }
}
