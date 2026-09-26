import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/data/models/master/basti_option_model.dart';
import '../../../app/data/models/master/basti_pattern_model.dart';
import '../../../app/data/models/master/disease_model.dart';
import '../../../app/data/models/patient/basti_schedule_day_model.dart';
import '../../../app/data/models/patient/basti_session_model.dart';
import '../../../app/data/models/patient/basti_treatment_plan_model.dart';
import '../../../app/data/models/patient/treatment_status.dart';
import '../../../app/data/models/poorva_karma/poorva_karma_results.dart';
import '../../../app/data/repositories/api_poorva_karma_repository.dart';
import '../../../app/data/repositories/api_paschata_karma_repository.dart';
import '../../../app/data/repositories/api_pradhana_karma_repository.dart';
import '../../../app/data/repositories/basti_clinical_repository.dart';
import '../../../app/data/services/api_service.dart';
import '../../../app/data/services/basti_dose_calculator_service.dart';
import '../../../app/data/services/basti_schedule_generator_service.dart';
import '../../patients/controller/patient_controller.dart';
import 'treatment_plan_controller.dart';

// Per-session observation data
class BastiSessionData {
  final int sessionNumber;
  final adanaKala = TextEditingController();
  final pratyagamana = TextEditingController();
  final vega = TextEditingController();
  late final RxList<bool> samyaka;
  late final RxList<bool> ayoga;
  late final RxList<bool> atiyoga;
  final RxString niruhaVyapada = ''.obs;
  final RxString anuvasanaVyapada = ''.obs;

  BastiSessionData(
    this.sessionNumber, {
    required int samyakaCount,
    required int ayogaCount,
    required int atiyogaCount,
  }) {
    samyaka = List.filled(samyakaCount, false).obs;
    ayoga = List.filled(ayogaCount, false).obs;
    atiyoga = List.filled(atiyogaCount, false).obs;
  }

  void dispose() {
    adanaKala.dispose();
    pratyagamana.dispose();
    vega.dispose();
  }
}

class AssessmentController extends GetxController {
  // ── Clinical Repositories & Services ────────────────────────────────────
  final repository = BastiClinicalRepository();
  final doseCalculator = BastiDoseCalculatorService();
  final scheduleGenerator = BastiScheduleGeneratorService();
  final _poorvaRepo = ApiPoorvaKarmaRepository();
  final _paschataRepo = ApiPaschataKarmaRepository();
  final _pradhanaRepo = ApiPradhanaKarmaRepository();

  // ── Clinical Master Data Observables ─────────────────────────────────────
  final selectedDisease = Rxn<DiseaseModel>();
  final availableDiseases = <DiseaseModel>[].obs;
  final availableBastiOptions = <BastiOptionModel>[].obs;
  final selectedBastiOption = Rxn<BastiOptionModel>();
  final calculatedNiruhaDose = Rxn<DoseCalculationResult>();
  final calculatedAnuvasanaDose = Rxn<DoseCalculationResult>();
  final calculatedMatraDose = Rxn<DoseCalculationResult>();
  final calculatedYapanaDose = Rxn<DoseCalculationResult>();
  final allPatterns = <BastiPatternModel>[].obs;
  final availablePatterns = <BastiPatternModel>[].obs;
  final selectedPattern = Rxn<BastiPatternModel>();
  final generatedSchedule = <BastiScheduleDayModel>[].obs;
  final isLoadingClinicalData = false.obs;
  final clinicalDataError = ''.obs;

  /// Tracks which day number is currently saving/updating or deleting observations.
  final savingSessionDay = Rxn<int>();
  final deletingSessionDay = Rxn<int>();

  // ── Patient context (passed from patient list) ───────────────────────────
  final String? patientId;
  final String patientName;
  final int patientAge;
  final String prakriti; // from CRF step 7 — auto-filled
  final String sarataha;
  final String sanhanan;
  final String pramana;
  final String satva;
  final String satmya;
  final String aharaShakti;
  final String vyayamaShakti;
  final String vaya;
  final String jihwa;
  final BastiTreatmentPlanModel? initialPlan;
  final bool initialPoorvaKarmaCompleted;
  final bool initialPradhanaKarmaCompleted;
  final bool initialPaschataKarmaCompleted;

  // ── Backend-calculated Poorva Karma results ──────────────────────────────
  final niruhaBackendResult = Rxn<PoorvaEligibilityResult>();
  final anuvasanaBackendResult = Rxn<PoorvaEligibilityResult>();
  final agniBackendResult = Rxn<AgniAssessmentResult>();
  final kosthaBackendResult = Rxn<KosthaAssessmentResult>();
  final saamaBackendResult = Rxn<SaamaNiramaResult>();

  AssessmentController({
    this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.prakriti,
    required this.sarataha,
    required this.sanhanan,
    required this.pramana,
    required this.satva,
    required this.satmya,
    required this.aharaShakti,
    required this.vyayamaShakti,
    required this.vaya,
    required this.jihwa,
    DiseaseModel? initialDisease,
    this.initialPlan,
    this.initialPoorvaKarmaCompleted = false,
    this.initialPradhanaKarmaCompleted = false,
    this.initialPaschataKarmaCompleted = false,
  }) {
    final effectivePlan =
        initialPlan ??
        (Get.isRegistered<TreatmentPlanController>() &&
                Get.find<TreatmentPlanController>()
                        .currentPlan
                        .value
                        ?.patientId ==
                    patientId
            ? Get.find<TreatmentPlanController>().currentPlan.value
            : null);

    if (initialDisease != null) {
      selectedDisease.value = initialDisease;
    }
    if (effectivePlan != null) {
      if (effectivePlan.patientBala.isNotEmpty) {
        bala.value = ApiPoorvaKarmaRepository.normalizeBala(effectivePlan.patientBala);
        isBalaFromPoorvaKarma.value = true;
      }
      if (effectivePlan.bastiName.isNotEmpty) {
        selectedBastiType.value = effectivePlan.bastiName;
        formulationCtrl.text = effectivePlan.bastiName;
      }
      if (effectivePlan.calculatedNiruhaDose > 0 ||
          effectivePlan.calculatedAnuvasanaDose > 0) {
        dravyaDoseCtrl.text =
            'Niruha: ${effectivePlan.calculatedNiruhaDose.toInt()} ml | Anuvasana: ${effectivePlan.calculatedAnuvasanaDose.toInt()} ml';
      }
      if (effectivePlan.scheduleDays.isNotEmpty) {
        generatedSchedule.value = List.from(effectivePlan.scheduleDays);
        scheduleCtrl.text =
            '${effectivePlan.selectedPatternName} (${effectivePlan.scheduleDays.length} Days): ${effectivePlan.scheduleDays.map((d) => d.bastiTypeCodeShort).join(" ")}';
        _initSessionsForGeneratedSchedule();
      }
    }

    // Baseline fallback if not already set from effectivePlan:
    if (bala.value == null || bala.value!.isEmpty) {
      final s = sanhanan.toLowerCase();
      final sar = sarataha.toLowerCase();
      final v = vyayamaShakti.toLowerCase();
      if (s.contains('pravar') || sar.contains('pravar') || v.contains('pravar')) {
        bala.value = 'Pravara';
      } else if (s.contains('avar') || sar.contains('avar') || v.contains('avar')) {
        bala.value = 'Avara';
      } else {
        bala.value = 'Madhyama';
      }
    }
  }

  Future<void>? initFuture;

  @override
  void onInit() {
    super.onInit();
    if (initialPoorvaKarmaCompleted) {
      purvakarmaComplete.value = true;
    }
    if (initialPradhanaKarmaCompleted) {
      pradhankarmaComplete.value = true;
    }
    if (initialPaschataKarmaCompleted) {
      paschatkarmaComplete.value = true;
    }

    if (generatedSchedule.isNotEmpty) {
      _restoreAllPersistedSessions();
    }

    // Immediately trigger background synchronization of patient Bala from Poorva Karma
    syncBalaFromPoorvaKarma();

    initFuture = loadClinicalMasterData();

    // Listen to Bala changes and recalculate doses automatically
    ever(bala, (String? newBala) {
      if (newBala != null) {
        recalculateDoses();
      }
    });

    ever(selectedBastiType, (_) => _initSessions());

    // Verify backend assessment status if patientId exists and not already loaded in memory
    checkPatientAssessmentStatus();
  }

  /// Checks for updated assessment status (e.g. poorvaKarmaCompleted)
  Future<void> checkPatientAssessmentStatus() async {
    if (patientId == null || patientId!.isEmpty) return;

    // 1. If PatientController has the patient in memory, synchronize directly without network call
    if (Get.isRegistered<PatientController>()) {
      final p = Get.find<PatientController>().currentPatient.value;
      if (p != null && p.id == patientId) {
        if (p.poorvaKarmaCompleted) purvakarmaComplete.value = true;
        if (p.pradhanaKarmaCompleted) pradhankarmaComplete.value = true;
        if (p.paschataKarmaCompleted) paschatkarmaComplete.value = true;
        return;
      }
    }

    // 2. If status was already provided via constructor flags, do not make redundant network call
    if (initialPoorvaKarmaCompleted ||
        initialPradhanaKarmaCompleted ||
        initialPaschataKarmaCompleted) {
      return;
    }

    try {
      final apiService = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : ApiService();
      final res = await apiService.get('/patients/$patientId');
      if (res.isOk && res.body is Map) {
        final data = (res.body as Map)['data'];
        if (data is Map) {
          final status = data['assessmentStatus'];
          if (status is Map) {
            if (status['poorvaKarmaCompleted'] == true) {
              purvakarmaComplete.value = true;
            }
            if (status['pradhanaKarmaCompleted'] == true) {
              pradhankarmaComplete.value = true;
            }
            if (status['paschataKarmaCompleted'] == true) {
              paschatkarmaComplete.value = true;
            }
          }
        }
      }
    } catch (_) {
      // Non-blocking status synchronization
    }
  }

  Future<void> loadClinicalMasterData({bool forceRefresh = false}) async {
    if (isLoadingClinicalData.value && initFuture != null) {
      await initFuture;
      return;
    }
    isLoadingClinicalData.value = true;
    clinicalDataError.value = '';
    try {
      await syncBalaFromPoorvaKarma();
      final diseases = await repository.getDiseases(forceRefresh: forceRefresh);
      final sortedDiseases = List<DiseaseModel>.from(diseases)
        ..sort((a, b) => a.displayLabel.trim().toLowerCase().compareTo(b.displayLabel.trim().toLowerCase()));
      availableDiseases.value = sortedDiseases;

      final effectivePlan =
          initialPlan ??
          (Get.isRegistered<TreatmentPlanController>() &&
                  Get.find<TreatmentPlanController>()
                          .currentPlan
                          .value
                          ?.patientId ==
                      patientId
              ? Get.find<TreatmentPlanController>().currentPlan.value
              : null);

      // Determine initial disease
      if (effectivePlan != null &&
          (effectivePlan.diseaseId.isNotEmpty || effectivePlan.diseaseName.isNotEmpty)) {
        final planId = effectivePlan.diseaseId.trim().toLowerCase();
        final planName = effectivePlan.diseaseName.trim().toLowerCase();
        for (final d in availableDiseases) {
          final matchId = planId.isNotEmpty &&
              (d.id.toLowerCase() == planId ||
                  (d.mongoId != null && d.mongoId!.toLowerCase() == planId));
          final matchName = planName.isNotEmpty &&
              (d.name.toLowerCase() == planName ||
                  d.displayLabel.toLowerCase().contains(planName));
          if (matchId || matchName) {
            selectedDisease.value = d;
            break;
          }
        }
      }

      // If still not matched, check PatientController.currentPatient for clinical diagnosis
      if (selectedDisease.value == null && Get.isRegistered<PatientController>()) {
        final patient = Get.find<PatientController>().currentPatient.value;
        if (patient != null && patient.id == patientId) {
          final targetName = (patient.clinicalDiseaseSelection ?? patient.diagnosis).trim().toLowerCase();
          final targetId = patient.diseaseId?.trim().toLowerCase();
          for (final d in availableDiseases) {
            final matchId = targetId != null && targetId.isNotEmpty &&
                (d.id.toLowerCase() == targetId ||
                    (d.mongoId != null && d.mongoId!.toLowerCase() == targetId));
            final matchName = targetName.isNotEmpty &&
                (d.name.toLowerCase() == targetName ||
                    d.displayLabel.toLowerCase().contains(targetName));
            if (matchId || matchName) {
              selectedDisease.value = d;
              break;
            }
          }
          if (selectedDisease.value == null && targetName.isNotEmpty) {
            // Prefer existing master disease by name or slug match before creating custom
            final matchedMaster = availableDiseases.firstWhereOrNull(
              (d) =>
                  !d.id.startsWith('custom_') &&
                  (d.name.trim().toLowerCase() == targetName ||
                   d.displayLabel.trim().toLowerCase() == targetName ||
                   DiseaseModel.slugify(d.name) == DiseaseModel.slugify(targetName)),
            );
            if (matchedMaster != null) {
              selectedDisease.value = matchedMaster;
            } else {
              final customDisease = DiseaseModel(
                id: targetId?.isNotEmpty == true
                    ? targetId!
                    : DiseaseModel.slugify(patient.clinicalDiseaseSelection ?? patient.diagnosis),
                name: patient.clinicalDiseaseSelection ?? patient.diagnosis,
                englishName: patient.clinicalDiseaseSelection ?? patient.diagnosis,
                description: 'Custom added disease',
              );
              availableDiseases.add(customDisease);
              availableDiseases.sort(
                (a, b) => a.displayLabel.trim().toLowerCase().compareTo(b.displayLabel.trim().toLowerCase()),
              );
              selectedDisease.value = customDisease;
            }
          }
        }
      }

      if (selectedDisease.value == null && availableDiseases.isNotEmpty) {
        selectedDisease.value = availableDiseases.first;
      }

      final patterns = await repository.getBastiPatterns();
      allPatterns.value = patterns;
      filterPatternsForCurrentBastiOption();

      if (selectedDisease.value != null) {
        final d = selectedDisease.value!;
        final options = await repository.getBastiOptionsForDisease(
          d.id,
          diseaseName: d.name,
          forceRefresh: forceRefresh,
        );
        availableBastiOptions.value = options;
        if (options.isNotEmpty) {
          if (effectivePlan != null &&
              (effectivePlan.bastiOptionId.isNotEmpty ||
                  effectivePlan.bastiName.isNotEmpty)) {
            final optId = effectivePlan.bastiOptionId.toLowerCase();
            final optName = effectivePlan.bastiName.toLowerCase();
            for (final o in options) {
              if (o.id.toLowerCase() == optId ||
                  o.name.toLowerCase() == optName ||
                  optName.contains(o.name.toLowerCase())) {
                selectedBastiOption.value = o;
                break;
              }
            }
          }
          selectedBastiOption.value ??= options.first;
          selectedBastiType.value = (effectivePlan?.bastiName.isNotEmpty == true &&
                  !effectivePlan!.bastiName.contains('Yukti'))
              ? effectivePlan.bastiName
              : (selectedBastiOption.value?.name ??
                    selectedBastiOption.value?.bastiTypeDisplay);
          formulationCtrl.text =
              selectedBastiOption.value?.formulationDetails ?? '';
        } else {
          final d = selectedDisease.value!;
          final yuktiOption = BastiOptionModel(
            id: 'opt_${d.id}_yukti',
            diseaseId: d.id,
            name: '${d.name} Formulation (Yukti)',
            bastiTypeCode: 'NB+AB',
            bastiTypeDisplay: 'Niruha Basti + Anuvasana Basti',
            indicationStage: 'Physician Yukti based formulation for ${d.name}',
            ingredients: const [],
            formulationDetails: 'Yukti based formulation as determined by physician.',
            classicalReference: 'Physician Yukti',
          );
          availableBastiOptions.value = [yuktiOption];
          selectedBastiOption.value = yuktiOption;
          selectedBastiType.value = yuktiOption.name;
          formulationCtrl.text = yuktiOption.formulationDetails;
        }
        filterPatternsForCurrentBastiOption();
      }

      if (effectivePlan != null &&
          (effectivePlan.selectedPatternCode.isNotEmpty ||
              effectivePlan.selectedPatternName.isNotEmpty)) {
        final code = effectivePlan.selectedPatternCode.toLowerCase().trim();
        final name = effectivePlan.selectedPatternName.toLowerCase().trim();
        for (final p in patterns) {
          if (p.code.toLowerCase().trim() == code ||
              p.name.toLowerCase().trim() == name ||
              p.name.toLowerCase().trim() == code ||
              p.code.toLowerCase().trim() == name) {
            selectedPattern.value = p;
            break;
          }
        }
        if (selectedPattern.value == null &&
            effectivePlan.scheduleDays.isNotEmpty) {
          selectedPattern.value = BastiPatternModel(
            code: effectivePlan.selectedPatternCode.isNotEmpty
                ? effectivePlan.selectedPatternCode
                : 'yoga',
            name: effectivePlan.selectedPatternName.isNotEmpty
                ? effectivePlan.selectedPatternName
                : 'Yoga Basti',
            totalDays: effectivePlan.scheduleDays.length,
            recommendedBala: effectivePlan.patientBala.isNotEmpty
                ? effectivePlan.patientBala
                : 'Avara',
            sequence: effectivePlan.scheduleDays
                .map((d) => d.bastiTypeCodeShort)
                .toList(),
            clinicalIndications: '',
          );
        }
      }

      await recalculateDoses();

      // If effectivePlan has scheduleDays, restore them and restore session observations
      if (effectivePlan != null && effectivePlan.scheduleDays.isNotEmpty) {
        generatedSchedule.value = List.from(effectivePlan.scheduleDays);
        final pat = selectedPattern.value;
        if (pat != null) {
          scheduleCtrl.text =
              '${pat.name} (${pat.totalDays} Days): ${effectivePlan.scheduleDays.map((d) => d.bastiTypeCodeShort).join(" ")}';
        } else {
          scheduleCtrl.text =
              '${effectivePlan.selectedPatternName} (${effectivePlan.scheduleDays.length} Days): ${effectivePlan.scheduleDays.map((d) => d.bastiTypeCodeShort).join(" ")}';
        }
        _initSessionsForGeneratedSchedule();
        await _restoreAllPersistedSessions();
      }
    } catch (e) {
      clinicalDataError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingClinicalData.value = false;
    }
  }

  Future<void> _restoreAllPersistedSessions() async {
    if (!Get.isRegistered<TreatmentPlanController>()) return;
    final tpc = Get.find<TreatmentPlanController>();
    for (int day = 1; day <= generatedSchedule.length; day++) {
      final persisted = await tpc.getSession(day);
      final dayIndex = day - 1;
      if (dayIndex >= 0 && dayIndex < sessions.length) {
        final sessionData = sessions[dayIndex];
        if (persisted != null && persisted.isCompleted) {
          if (persisted.adanaKala.isNotEmpty) {
            sessionData.adanaKala.text = persisted.adanaKala;
          }
          if (persisted.pratyagamana.isNotEmpty) {
            sessionData.pratyagamana.text = persisted.pratyagamana;
          }
          if (persisted.vega.isNotEmpty) {
            sessionData.vega.text = persisted.vega;
          }
          for (
            int i = 0;
            i < sessionData.samyaka.length &&
                i < persisted.samyakaSelected.length;
            i++
          ) {
            sessionData.samyaka[i] = persisted.samyakaSelected[i];
          }
          for (
            int i = 0;
            i < sessionData.ayoga.length && i < persisted.ayogaSelected.length;
            i++
          ) {
            sessionData.ayoga[i] = persisted.ayogaSelected[i];
          }
          for (
            int i = 0;
            i < sessionData.atiyoga.length &&
                i < persisted.atiyogaSelected.length;
            i++
          ) {
            sessionData.atiyoga[i] = persisted.atiyogaSelected[i];
          }
        } else {
          sessionData.adanaKala.clear();
          sessionData.pratyagamana.clear();
          sessionData.vega.clear();
          for (int i = 0; i < sessionData.samyaka.length; i++) {
            sessionData.samyaka[i] = false;
          }
          for (int i = 0; i < sessionData.ayoga.length; i++) {
            sessionData.ayoga[i] = false;
          }
          for (int i = 0; i < sessionData.atiyoga.length; i++) {
            sessionData.atiyoga[i] = false;
          }
        }
        sessionData.samyaka.refresh();
        sessionData.ayoga.refresh();
        sessionData.atiyoga.refresh();
      }
    }
    observationTick.value++;
  }

  Future<void> fetchBastiOptionsForSelectedDisease({bool forceRefresh = false}) async {
    final disease = selectedDisease.value;
    if (disease == null) return;

    isLoadingClinicalData.value = true;
    clinicalDataError.value = '';
    try {
      // 1. If disease is custom or was created before master data loaded,
      // check if availableDiseases has a matching master disease
      DiseaseModel effectiveDisease = disease;
      if (disease.id.startsWith('custom_') || RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(disease.id)) {
        final masterMatch = availableDiseases.firstWhereOrNull(
          (d) =>
              !d.id.startsWith('custom_') &&
              (d.name.trim().toLowerCase() == disease.name.trim().toLowerCase() ||
               d.displayLabel.trim().toLowerCase() == disease.name.trim().toLowerCase() ||
               DiseaseModel.slugify(d.name) == DiseaseModel.slugify(disease.name)),
        );
        if (masterMatch != null) {
          effectiveDisease = masterMatch;
          selectedDisease.value = masterMatch;
        }
      }

      final options = await repository.getBastiOptionsForDisease(
        effectiveDisease.id,
        diseaseName: effectiveDisease.name,
        forceRefresh: forceRefresh,
      );

      if (options.isNotEmpty) {
        availableBastiOptions.value = options;
        // Keep existing selection if valid and not Yukti, otherwise select first
        final current = selectedBastiOption.value;
        final matching = current == null || current.name.contains('Yukti')
            ? null
            : options.firstWhereOrNull(
                (o) =>
                    o.id == current.id ||
                    (o.mongoId != null && o.mongoId == current.mongoId) ||
                    o.name.toLowerCase() == current.name.toLowerCase(),
              );
        final toSelect = matching ?? options.first;
        selectedBastiOption.value = toSelect;
        selectedBastiType.value = toSelect.name;
        formulationCtrl.text = toSelect.formulationDetails;
      } else {
        final yuktiOption = BastiOptionModel(
          id: 'opt_${effectiveDisease.id}_yukti',
          diseaseId: effectiveDisease.id,
          name: '${effectiveDisease.name} Formulation (Yukti)',
          bastiTypeCode: 'NB+AB',
          bastiTypeDisplay: 'Niruha Basti + Anuvasana Basti',
          indicationStage: 'Physician Yukti based formulation for ${effectiveDisease.name}',
          ingredients: const [],
          formulationDetails: 'Yukti based formulation as determined by physician.',
          classicalReference: 'Physician Yukti',
        );
        availableBastiOptions.value = [yuktiOption];
        selectedBastiOption.value = yuktiOption;
        selectedBastiType.value = yuktiOption.name;
        formulationCtrl.text = yuktiOption.formulationDetails;
      }
      filterPatternsForCurrentBastiOption();
    } catch (e) {
      if (disease.id.startsWith('custom_')) {
        final yuktiOption = BastiOptionModel(
          id: 'opt_${disease.id}_yukti',
          diseaseId: disease.id,
          name: '${disease.name} Formulation (Yukti)',
          bastiTypeCode: 'NB+AB',
          bastiTypeDisplay: 'Niruha Basti + Anuvasana Basti',
          indicationStage: 'Physician Yukti based formulation for ${disease.name}',
          ingredients: const [],
          formulationDetails: 'Yukti based formulation as determined by physician.',
          classicalReference: 'Physician Yukti',
        );
        availableBastiOptions.value = [yuktiOption];
        selectedBastiOption.value = yuktiOption;
        selectedBastiType.value = yuktiOption.name;
        formulationCtrl.text = yuktiOption.formulationDetails;
      } else {
        clinicalDataError.value = e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      isLoadingClinicalData.value = false;
    }
  }

  Future<bool> recalculateDoses() async {
    final effectivePlan =
        initialPlan ??
        (Get.isRegistered<TreatmentPlanController>() &&
                Get.find<TreatmentPlanController>()
                        .currentPlan
                        .value
                        ?.patientId ==
                    patientId
            ? Get.find<TreatmentPlanController>().currentPlan.value
            : null);

    final activeBala =
        bala.value ??
        (effectivePlan?.patientBala.isNotEmpty == true
            ? effectivePlan!.patientBala
            : 'Madhyama');

    final opt = selectedBastiOption.value;
    final bType = (opt?.bastiTypeCode.isNotEmpty == true
            ? opt!.bastiTypeCode
            : opt?.bastiTypeDisplay ?? '')
        .toLowerCase();

    DoseCalculationResult? niruhaRes;
    DoseCalculationResult? anuvasanaRes;
    DoseCalculationResult? matraRes;
    DoseCalculationResult? yapanaRes;

    if (bType.contains('yapana') || bType == 'yb') {
      yapanaRes = await doseCalculator.calculateDose(
          bastiType: 'Yapana',
          patientBala: activeBala,
      );
    } else if (bType.contains('matra') || (bType.contains('sneha') && !bType.contains('niruha')) || bType == 'mb') {
      matraRes = await doseCalculator.calculateDose(
          bastiType: 'Matra',
          patientBala: activeBala,
      );
    } else {
      final results = await Future.wait([
        doseCalculator.calculateDose(bastiType: 'Niruha', patientBala: activeBala),
        doseCalculator.calculateDose(bastiType: 'Anuvasana', patientBala: activeBala),
      ]);
      niruhaRes = results[0];
      anuvasanaRes = results[1];
    }

    calculatedNiruhaDose.value = niruhaRes;
    calculatedAnuvasanaDose.value = anuvasanaRes;
    calculatedMatraDose.value = matraRes;
    calculatedYapanaDose.value = yapanaRes;

    if (bType.contains('yapana') || bType == 'yb') {
      final yVol = yapanaRes?.totalVolume ?? niruhaRes?.totalVolume ?? 400.0;
      dravyaDoseCtrl.text = 'Yapana: ${yVol.toInt()} ml';
    } else if (bType.contains('matra') || (bType.contains('sneha') && !bType.contains('niruha')) || bType == 'mb') {
      final mVol = matraRes?.totalVolume ?? (anuvasanaRes != null ? (anuvasanaRes.totalVolume / 2) : 50.0);
      final aVol = anuvasanaRes?.totalVolume ?? 100.0;
      dravyaDoseCtrl.text = 'Matra: ${mVol.toInt()} ml | Anuvasana: ${aVol.toInt()} ml';
    } else if (niruhaRes != null && anuvasanaRes != null) {
      dravyaDoseCtrl.text =
          'Niruha: ${niruhaRes.totalVolume.toInt()} ml | Anuvasana: ${anuvasanaRes.totalVolume.toInt()} ml';
    }

    final hasExistingPlan =
        effectivePlan != null ||
        (Get.isRegistered<TreatmentPlanController>() &&
            Get.find<TreatmentPlanController>().currentPlan.value != null) ||
        generatedSchedule.isNotEmpty ||
        selectedPattern.value != null;

    bool didCallGenerate = false;
    // Recommend pattern aligned with patient Bala ONLY for brand-new treatment creation
    if (!hasExistingPlan && availablePatterns.isNotEmpty) {
      try {
        final recPattern = availablePatterns.firstWhere(
          (p) => p.recommendedBala.toLowerCase() == activeBala.toLowerCase(),
        );
        selectedPattern.value = recPattern;
      } catch (_) {
        if (availablePatterns.isNotEmpty) {
          selectedPattern.value = availablePatterns.first;
        }
      }
      
      if (selectedPattern.value != null && selectedBastiOption.value != null) {
        await generateSchedule();
        didCallGenerate = true;
      }
    }
    
    return didCallGenerate;
  }

  /// Whether the treatment plan is already active (sessions have been logged
  /// or status is COMPLETED), meaning clinical formulation and pattern
  /// schedule should not be silently replaced or mutated.
  bool get isTreatmentPlanActive {
    if (Get.isRegistered<TreatmentPlanController>()) {
      final tpc = Get.find<TreatmentPlanController>();
      if (tpc.completedSessionCount > 0 ||
          tpc.currentPlan.value?.status == TreatmentStatus.completed) {
        return true;
      }
    }
    return loggedSessionCount > 0 ||
        initialPlan?.status == TreatmentStatus.completed;
  }

  Future<void> selectDisease(DiseaseModel disease) async {
    if (isTreatmentPlanActive) return;
    selectedDisease.value = disease;
    await fetchBastiOptionsForSelectedDisease(forceRefresh: true);

    // Fix basti option selection BEFORE calculating doses!
    if (availableBastiOptions.isNotEmpty) {
      final isCurrentYukti = selectedBastiOption.value?.name.contains('Yukti') == true;
      final hasRealOptions = availableBastiOptions.any((o) => !o.name.contains('Yukti'));
      final exists = !isCurrentYukti && availableBastiOptions.any(
        (o) =>
            o.id == selectedBastiOption.value?.id ||
            (o.mongoId != null && o.mongoId == selectedBastiOption.value?.mongoId) ||
            o.name == selectedBastiOption.value?.name,
      );
      if (!exists || (isCurrentYukti && hasRealOptions)) {
        final firstOpt = availableBastiOptions.firstWhere(
          (o) => !o.name.contains('Yukti'),
          orElse: () => availableBastiOptions.first,
        );
        selectedBastiOption.value = firstOpt;
        selectedBastiType.value = firstOpt.name;
        formulationCtrl.text = firstOpt.formulationDetails;
      }
    }

    filterPatternsForCurrentBastiOption();

    final didCallGenerate = await recalculateDoses();

    if (!didCallGenerate && selectedPattern.value == null && availablePatterns.isNotEmpty) {
      selectedPattern.value = availablePatterns.first;
      if (selectedBastiOption.value != null) {
        await generateSchedule();
      } else {
        await _syncDiseaseSelection();
      }
    } else if (!didCallGenerate && selectedPattern.value != null && selectedBastiOption.value != null) {
      await generateSchedule();
    } else if (!didCallGenerate) {
      await _syncDiseaseSelection();
    }
  }

  Future<void> addNewDiseaseAndSelect(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final existing = availableDiseases.firstWhereOrNull(
      (d) =>
          d.name.toLowerCase() == trimmed.toLowerCase() ||
          d.displayLabel.toLowerCase() == trimmed.toLowerCase() ||
          DiseaseModel.slugify(d.name) == DiseaseModel.slugify(trimmed),
    );
    if (existing != null) {
      await selectDisease(existing);
      return;
    }

    final newDisease = DiseaseModel(
      id: DiseaseModel.slugify(trimmed),
      name: trimmed,
      englishName: trimmed,
      description: 'Custom added disease',
    );

    availableDiseases.add(newDisease);
    availableDiseases.sort(
      (a, b) => a.displayLabel.trim().toLowerCase().compareTo(b.displayLabel.trim().toLowerCase()),
    );
    await selectDisease(newDisease);
  }

  Future<void> _syncDiseaseSelection() async {
    if (!Get.isRegistered<TreatmentPlanController>()) return;
    final tpc = Get.find<TreatmentPlanController>();
    final current = tpc.currentPlan.value;
    if (current != null && current.patientId == patientId) {
      final hex24 = RegExp(r'^[0-9a-fA-F]{24}$');
      String? backendDiseaseId = selectedDisease.value?.mongoId;
      if (backendDiseaseId == null || !hex24.hasMatch(backendDiseaseId)) {
        if (selectedDisease.value != null &&
            hex24.hasMatch(selectedDisease.value!.id)) {
          backendDiseaseId = selectedDisease.value!.id;
        }
      }

      final updated = current.copyWith(
        diseaseId: backendDiseaseId ?? selectedDisease.value?.id ?? '',
        diseaseName: selectedDisease.value?.name ?? '',
        updatedAt: DateTime.now(),
      );
      await tpc.updateTreatmentPlan(updated);
    }
  }

  /// Filters [allPatterns] down into [availablePatterns] matching the selected formulation's bastiType.
  void filterPatternsForCurrentBastiOption() {
    final option = selectedBastiOption.value;
    final bastiType = (option?.bastiTypeCode.isNotEmpty == true
            ? option!.bastiTypeCode
            : option?.bastiTypeDisplay) ??
        '';

    if (bastiType.isEmpty || allPatterns.isEmpty) {
      availablePatterns.value = List.from(allPatterns);
      return;
    }

    final filtered = allPatterns.where((p) => p.matchesBastiType(bastiType)).toList();
    if (filtered.isNotEmpty) {
      availablePatterns.value = filtered;
    } else {
      // Graceful fallback to all patterns if no pattern matches specific filter
      availablePatterns.value = List.from(allPatterns);
    }

    // Ensure currently selected pattern is still valid in availablePatterns
    if (selectedPattern.value == null ||
        !availablePatterns.any((p) => p.code.toLowerCase() == selectedPattern.value!.code.toLowerCase())) {
      if (availablePatterns.isNotEmpty) {
        final activeBala = bala.value ?? 'Madhyama';
        final rec = availablePatterns.firstWhereOrNull(
          (p) => p.recommendedBala.toLowerCase() == activeBala.toLowerCase(),
        );
        selectedPattern.value = rec ?? availablePatterns.first;
      }
    }
  }

  Future<void> selectBastiOption(BastiOptionModel option) async {
    if (isTreatmentPlanActive) return;
    selectedBastiOption.value = option;
    selectedBastiType.value = option.name;
    formulationCtrl.text = option.formulationDetails;
    filterPatternsForCurrentBastiOption();
    final didCallGenerate = await recalculateDoses();
    if (!didCallGenerate) {
      await generateSchedule();
    }
  }

  Future<void> selectPattern(BastiPatternModel pattern) async {
    if (isTreatmentPlanActive) return;
    selectedPattern.value = pattern;
    await generateSchedule();
  }

  Future<void> generateSchedule() async {
    final pattern = selectedPattern.value;
    final option = selectedBastiOption.value;
    final niruha = calculatedNiruhaDose.value;
    final anuvasana = calculatedAnuvasanaDose.value;
    final matra = calculatedMatraDose.value;
    final yapana = calculatedYapanaDose.value;

    if (pattern == null || option == null) {
      return;
    }

    final niruhaVol = niruha?.totalVolume ?? 400.0;
    final anuvasanaVol = anuvasana?.totalVolume ?? 100.0;
    final matraVol = matra?.totalVolume ?? (anuvasanaVol > 60 ? anuvasanaVol / 2 : anuvasanaVol);
    final yapanaVol = yapana?.totalVolume ?? niruhaVol;

    final days = scheduleGenerator.generateSchedule(
      pattern: pattern,
      niruhaDose: niruhaVol,
      anuvasanaDose: anuvasanaVol,
      matraDose: matraVol,
      yapanaDose: yapanaVol,
      selectedBasti: option,
      niruhaCompositionSummary: niruha?.summaryText ?? '',
      anuvasanaCompositionSummary: anuvasana?.summaryText ?? '',
      matraCompositionSummary: matra?.summaryText ?? '',
      yapanaCompositionSummary: yapana?.summaryText ?? '',
    );

    generatedSchedule.value = days;
    scheduleCtrl.text =
        '${pattern.name} (${pattern.totalDays} Days): ${pattern.sequence.join(" ")}';
    _initSessionsForGeneratedSchedule();
    await _createOrUpdateTreatmentPlan(
      pattern,
      option,
      niruha ?? DoseCalculationResult(bastiType: 'Niruha', bala: bala.value ?? 'Madhyama', totalVolume: niruhaVol, unit: 'ml', components: const [], sourceReference: ''),
      anuvasana ?? DoseCalculationResult(bastiType: 'Anuvasana', bala: bala.value ?? 'Madhyama', totalVolume: anuvasanaVol, unit: 'ml', components: const [], sourceReference: ''),
      days,
    );
  }

  /// Persists the configured treatment plan into the repository.
  Future<void> persistTreatmentPlan() async {
    final pattern = selectedPattern.value;
    final option = selectedBastiOption.value;
    final niruha = calculatedNiruhaDose.value;
    final anuvasana = calculatedAnuvasanaDose.value;

    if (pattern == null ||
        option == null ||
        niruha == null ||
        anuvasana == null) {
      return;
    }

    if (generatedSchedule.isEmpty) {
      await generateSchedule();
    } else {
      await _createOrUpdateTreatmentPlan(
        pattern,
        option,
        niruha,
        anuvasana,
        generatedSchedule,
      );
    }
  }

  // ── Persistence integration ──────────────────────────────────────────────

  /// Creates or updates the treatment plan in the repository whenever the
  /// schedule is (re)generated.
  Future<void> _createOrUpdateTreatmentPlan(
    BastiPatternModel pattern,
    BastiOptionModel option,
    DoseCalculationResult niruha,
    DoseCalculationResult anuvasana,
    List<BastiScheduleDayModel> days,
  ) async {
    if (!Get.isRegistered<TreatmentPlanController>()) return;
    final tpc = Get.find<TreatmentPlanController>();
    final now = DateTime.now();

    final current = tpc.currentPlan.value;
    final existingPlan = (current != null && current.patientId == patientId)
        ? current
        : (initialPlan != null && initialPlan!.patientId == patientId
              ? initialPlan
              : null);

    final isExisting = existingPlan != null;
    final planId = existingPlan?.id ?? 'plan_${now.millisecondsSinceEpoch}';
    final createdAt = existingPlan?.createdAt ?? now;
    final status = existingPlan?.status ?? TreatmentStatus.draft;
    final startDate = existingPlan?.startDate;

    final hex24 = RegExp(r'^[0-9a-fA-F]{24}$');
    String? backendDiseaseId = selectedDisease.value?.mongoId;
    if (backendDiseaseId == null || !hex24.hasMatch(backendDiseaseId)) {
      if (selectedDisease.value != null &&
          hex24.hasMatch(selectedDisease.value!.id)) {
        backendDiseaseId = selectedDisease.value!.id;
      } else {
        final matched = availableDiseases.firstWhereOrNull(
          (d) =>
              d.id == selectedDisease.value?.id ||
              d.name == selectedDisease.value?.name,
        );
        backendDiseaseId = matched?.mongoId;
      }
    }

    String? backendFormulationId = option.mongoId;
    if (backendFormulationId == null ||
        !hex24.hasMatch(backendFormulationId)) {
      if (hex24.hasMatch(option.id)) {
        backendFormulationId = option.id;
      } else {
        final matched = availableBastiOptions.firstWhereOrNull(
          (o) => o.id == option.id || o.name == option.name,
        );
        backendFormulationId = matched?.mongoId;
      }
    }

    final plan = BastiTreatmentPlanModel(
      id: planId,
      patientId: patientId,
      diseaseId: backendDiseaseId ?? selectedDisease.value?.mongoId ?? selectedDisease.value?.id ?? '',
      diseaseName: selectedDisease.value?.name ?? '',
      bastiOptionId: backendFormulationId ?? option.mongoId ?? option.id,
      bastiName: option.name,
      patientBala: bala.value ?? 'Madhyama',
      selectedPatternCode: pattern.code,
      selectedPatternName: pattern.name,
      calculatedNiruhaDose: niruha.totalVolume,
      calculatedAnuvasanaDose: anuvasana.totalVolume,
      scheduleDays: days,
      status: status,
      startDate: startDate,
      createdAt: createdAt,
      updatedAt: now,
    );

    if (isExisting) {
      await tpc.updateTreatmentPlan(plan);
    } else {
      await tpc.createTreatmentPlan(plan);
    }

    // Sync to backend if patientId is present
    if (patientId != null && patientId!.isNotEmpty) {
      try {
        if (backendDiseaseId != null &&
            hex24.hasMatch(backendDiseaseId) &&
            backendFormulationId != null &&
            hex24.hasMatch(backendFormulationId)) {
          await _pradhanaRepo.initializeOrUpdatePradhanaKarma(
            patientId!,
            diseaseId: backendDiseaseId,
            bastiPatternCode: plan.selectedPatternCode,
            bastiFormulationId: backendFormulationId,
            startDate: plan.startDate ?? now,
            treatmentStatus: plan.status == TreatmentStatus.completed
                ? 'COMPLETED'
                : (plan.status == TreatmentStatus.active
                    ? 'IN_PROGRESS'
                    : 'PLANNED'),
          );
        } else {
          debugPrint(
            'Skipping backend PUT /pradhana-karma: non-ObjectId diseaseId ($backendDiseaseId) or formulationId ($backendFormulationId)',
          );
        }
      } catch (e) {
        debugPrint('Failed to sync treatment plan to backend: $e');
      }
    }
  }

  /// Reads observations from [BastiSessionData] for [dayNumber] and persists
  /// the session as COMPLETED via [TreatmentPlanController].
  Future<void> saveCurrentSession(int dayNumber) async {
    savingSessionDay.value = dayNumber;
    try {
      if (!Get.isRegistered<TreatmentPlanController>()) return;
      final tpc = Get.find<TreatmentPlanController>();
    if (tpc.currentPlan.value == null ||
        tpc.currentPlan.value?.diseaseName != selectedDisease.value?.name) {
      await persistTreatmentPlan();
    }
    final planId = tpc.currentPlan.value?.id;
    if (planId == null) return;

    final dayIndex = dayNumber - 1;
    if (dayIndex < 0 || dayIndex >= sessions.length) return;
    final sessionData = sessions[dayIndex];

    final schedule = generatedSchedule;
    if (dayIndex >= schedule.length) return;
    final dayModel = schedule[dayIndex];

    final now = DateTime.now();
    final existing = await tpc.getSession(dayNumber);

    final sessionModel = BastiSessionModel(
      id: existing?.id ?? 'session_${planId}_day$dayNumber',
      treatmentPlanId: planId,
      dayNumber: dayNumber,
      scheduledBastiType: dayModel.scheduledBastiType,
      bastiTypeCodeShort: dayModel.bastiTypeCodeShort,
      scheduledDose: dayModel.scheduledDose,
      doseUnit: dayModel.doseUnit,
      status: SessionStatus.completed,
      adanaKala: sessionData.adanaKala.text,
      pratyagamana: sessionData.pratyagamana.text,
      vega: sessionData.vega.text,
      samyakaSelected: List<bool>.from(sessionData.samyaka),
      ayogaSelected: List<bool>.from(sessionData.ayoga),
      atiyogaSelected: List<bool>.from(sessionData.atiyoga),
      niruhaVyapada: sessionData.niruhaVyapada.value,
      anuvasanaVyapada: sessionData.anuvasanaVyapada.value,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final selectedBeforeSave = sessionModel.selectedObservationIds;
    debugPrint(
      '[Day $dayNumber / ${sessionModel.id}] Selected observation IDs before save: $selectedBeforeSave',
    );

    await tpc.saveSession(sessionModel);
    // Trigger UI rebuild of the progress counter
    observationTick.value++;
  } finally {
    savingSessionDay.value = null;
  }
}

  /// Clears/deletes observations for [dayNumber] from memory, persisted store,
  /// and backend, resetting the day's status to pending.
  Future<void> deleteSession(int dayNumber) async {
    deletingSessionDay.value = dayNumber;
    try {
      final dayIndex = dayNumber - 1;
    if (dayIndex >= 0 && dayIndex < sessions.length) {
      final s = sessions[dayIndex];
      s.adanaKala.clear();
      s.pratyagamana.clear();
      s.vega.clear();
      s.niruhaVyapada.value = '';
      s.anuvasanaVyapada.value = '';
      for (int i = 0; i < s.samyaka.length; i++) {
        s.samyaka[i] = false;
      }
      for (int i = 0; i < s.ayoga.length; i++) {
        s.ayoga[i] = false;
      }
      for (int i = 0; i < s.atiyoga.length; i++) {
        s.atiyoga[i] = false;
      }
      s.samyaka.refresh();
      s.ayoga.refresh();
      s.atiyoga.refresh();
    }

    if (Get.isRegistered<TreatmentPlanController>()) {
      final tpc = Get.find<TreatmentPlanController>();
      await tpc.deleteSession(dayNumber);
    }

    if (patientId != null && patientId!.isNotEmpty) {
      try {
        final clearedPayload = <String, dynamic>{
          'day': dayNumber,
          'status': 'PENDING',
          'timeAdministered': '',
          'pratyagamana': '',
          'notes': '',
          'dose': '',
          'bastiType': '',
          'paschataKarma': {
            'vyapadaAndManagement': {
              'niruhaVyapada': '',
              'anuvasanaVyapada': '',
            }
          },
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
          patientId!,
          dayNumber,
          clearedPayload,
        );
      } catch (e) {
        debugPrint('Failed to sync session deletion to backend: $e');
      }
    }

    observationTick.value++;
  } finally {
    deletingSessionDay.value = null;
  }
}

  /// Restores persisted observation values into the in-memory [BastiSessionData]
  /// for [dayNumber] so the form shows correct data when a day is reopened.
  Future<void> restoreSessionData(int dayNumber) async {
    if (!Get.isRegistered<TreatmentPlanController>()) return;
    final tpc = Get.find<TreatmentPlanController>();
    final persisted = await tpc.getSession(dayNumber);

    final dayIndex = dayNumber - 1;
    if (dayIndex < 0 || dayIndex >= sessions.length) return;
    final sessionData = sessions[dayIndex];

    if (persisted == null || !persisted.isCompleted) {
      sessionData.adanaKala.clear();
      sessionData.pratyagamana.clear();
      sessionData.vega.clear();
      sessionData.niruhaVyapada.value = '';
      sessionData.anuvasanaVyapada.value = '';
      for (int i = 0; i < sessionData.samyaka.length; i++) {
        sessionData.samyaka[i] = false;
      }
      for (int i = 0; i < sessionData.ayoga.length; i++) {
        sessionData.ayoga[i] = false;
      }
      for (int i = 0; i < sessionData.atiyoga.length; i++) {
        sessionData.atiyoga[i] = false;
      }
      sessionData.samyaka.refresh();
      sessionData.ayoga.refresh();
      sessionData.atiyoga.refresh();
      observationTick.value++;
      return;
    }

    final selectedReopened = persisted.selectedObservationIds;
    debugPrint(
      '[Day $dayNumber / ${persisted.id}] Selected observation IDs returned when Day $dayNumber is reopened: $selectedReopened',
    );

    if (persisted.adanaKala.isNotEmpty) {
      sessionData.adanaKala.text = persisted.adanaKala;
    }
    if (persisted.pratyagamana.isNotEmpty) {
      sessionData.pratyagamana.text = persisted.pratyagamana;
    }
    if (persisted.vega.isNotEmpty) {
      sessionData.vega.text = persisted.vega;
    }
    
    sessionData.niruhaVyapada.value = persisted.niruhaVyapada;
    sessionData.anuvasanaVyapada.value = persisted.anuvasanaVyapada;

    // Restore symptom toggles
    for (
      int i = 0;
      i < sessionData.samyaka.length && i < persisted.samyakaSelected.length;
      i++
    ) {
      sessionData.samyaka[i] = persisted.samyakaSelected[i];
    }
    for (
      int i = 0;
      i < sessionData.ayoga.length && i < persisted.ayogaSelected.length;
      i++
    ) {
      sessionData.ayoga[i] = persisted.ayogaSelected[i];
    }
    for (
      int i = 0;
      i < sessionData.atiyoga.length && i < persisted.atiyogaSelected.length;
      i++
    ) {
      sessionData.atiyoga[i] = persisted.atiyogaSelected[i];
    }
    sessionData.samyaka.refresh();
    sessionData.ayoga.refresh();
    sessionData.atiyoga.refresh();
    observationTick.value++;
  }

  void _initSessionsForGeneratedSchedule() {
    for (final s in sessions) {
      s.dispose();
    }
    final days = generatedSchedule;
    sessions.value = List.generate(days.length, (i) {
      final isKwatha = days[i].isKwathaBased;
      return BastiSessionData(
        i + 1,
        samyakaCount: isKwatha
            ? niruhasamyakaSymptoms.length
            : anuvasanSamyakaSymptoms.length,
        ayogaCount: isKwatha
            ? niruhaAyogaSymptoms.length
            : anuvasanAyogaSymptoms.length,
        atiyogaCount: isKwatha
            ? niruhaAtiyogaSymptoms.length
            : anuvasanAtiyogaSymptoms.length,
      );
    });
    observationTick.value = 0;
  }

  // ── Phase completion tracking ────────────────────────────────────────────
  final purvakarmaComplete = false.obs;
  final pradhankarmaComplete = false.obs;
  final paschatkarmaComplete = false.obs;

  // ── Paschatkarma save / load state ────────────────────────────────────────
  final isSavingPaschatkarma = false.obs;
  final isLoadingPaschatkarma = false.obs;

  // ── Poorva Karma API save guard ──────────────────────────────────────────
  /// True while a step is being persisted to the backend.
  /// Used to disable Next/Complete buttons to prevent duplicate taps.
  final isSavingStep = false.obs;

  /// Holds the latest error message when saving Poorva Karma steps fails.
  final poorvaKarmaError = RxnString();

  /// Persists the data for [step] (0-indexed) to the backend.
  ///
  /// Returns `true` when the data was saved successfully, `false` when the
  /// API call fails. The caller is responsible for showing error UI and
  /// deciding whether to block navigation.
  Future<bool> saveCurrentPoorvaStep(int step) async {
    poorvaKarmaError.value = null;
    if (patientId == null || patientId!.isEmpty) {
      poorvaKarmaError.value = 'Patient ID is missing. Cannot save assessment.';
      return false;
    }

    if (isSavingStep.value) return false;
    isSavingStep.value = true;
    try {
      switch (step) {
        case 0: // Niruha
          final res = await _poorvaRepo.saveNiruha(
            patientId!,
            List<bool?>.from(niruhaAnswers),
          );
          niruhaBackendResult.value = res;
          break;
        case 1: // Anuvasana
          final res = await _poorvaRepo.saveAnuvasana(
            patientId!,
            List<bool?>.from(anuvasanAnswers),
          );
          anuvasanaBackendResult.value = res;
          break;
        case 2: // Pariksha
          await _poorvaRepo.savePariksha(
            patientId!,
            prakriti: parikshaPrakriti.value ?? '',
            sarataha: parikshaSarataha.value ?? '',
            sanhanan: parikshaSanhanan.value ?? '',
            pramana: parikshaPramana.value ?? '',
            satva: parikshaSatva.value ?? '',
            satmya: parikshaSatmya.value ?? '',
            aharaShakti: parikshAhara.value ?? '',
            vyayamaShakti: parikshVyayama.value ?? '',
            vaya: parikshVaya.value ?? '',
            jihwa: parikshJihwa.value ?? '',
          );
          break;
        case 3: // Agni
          final res = await _poorvaRepo.saveAgni(
            patientId!,
            jaranShaktiScore: jaranShaktiSelected.length,
            abhyavaharanaShaktiScore: abhyavaharanaIndex.value ?? 0,
            ruchiScore: ruchiIndex.value ?? 0,
          );
          agniBackendResult.value = res;
          break;
        case 4: // Kostha
          final res = await _poorvaRepo.saveKostha(
            patientId!,
            List<int?>.from(koshthaAnswers),
          );
          kosthaBackendResult.value = res;
          break;
        case 5: // Saama-Nirama + Bala (both saved before Complete)
          final res = await _poorvaRepo.saveSaamaNirama(
            patientId!,
            List<bool?>.from(saamaAnswers),
          );
          saamaBackendResult.value = res;
          if (bala.value != null) {
            await _poorvaRepo.saveBala(patientId!, bala.value!);
          }
          break;
      }
      return true;
    } catch (e) {
      poorvaKarmaError.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSavingStep.value = false;
    }
  }

  final isLoadingPoorvaKarma = false.obs;

  /// Loads previously saved Poorva Karma assessment from backend for [patientId].
  /// Restores all sections and returns the 0-indexed resume step (0 to 5).
  Future<int> loadPoorvaKarma() async {
    if (patientId == null || patientId!.isEmpty) return 0;

    isLoadingPoorvaKarma.value = true;
    try {
      final data = await _poorvaRepo.getPoorvaKarma(patientId!);
      if (data == null) return 0;
      debugPrint('loadPoorvaKarma received keys: ${data.keys.toList()}');

      // 1. Niruha
      if (data['niruhaEligibility'] is Map) {
        final m = data['niruhaEligibility'] as Map<String, dynamic>;
        if (m.containsKey('recentInternalSnehanaEtc')) {
          niruhaAnswers[0] = m['recentInternalSnehanaEtc'] as bool?;
          niruhaAnswers[1] = m['continuousVomitingEtc'] as bool?;
          niruhaAnswers[2] = m['historyOfMiscarriageOrPregnant'] as bool?;
          niruhaAnswers[3] = m['uncontrolledDiabetesHypertensionCkd'] as bool?;
          niruhaAnswers.refresh();
        }
        niruhaBackendResult.value = PoorvaEligibilityResult.fromJson(m);
      }

      // 2. Anuvasana
      if (data['anuvasanaEligibility'] is Map) {
        final m = data['anuvasanaEligibility'] as Map<String, dynamic>;
        if (m.containsKey('hasAsthapanaContraindications')) {
          anuvasanAnswers[0] = m['hasAsthapanaContraindications'] as bool?;
          anuvasanAnswers[1] = m['impairedDigestion'] as bool?;
          anuvasanAnswers[2] = m['diarrhoeaOrHardBowel'] as bool?;
          anuvasanAnswers[3] = m['intestinalWormsPleehaEtc'] as bool?;
          anuvasanAnswers[4] = m['aruchiPoisoningCoryzaEtc'] as bool?;
          anuvasanAnswers.refresh();
        }
        anuvasanaBackendResult.value = PoorvaEligibilityResult.fromJson(m);
      }

      // 3. Pariksha
      if (data['pariksha'] is Map) {
        final m = data['pariksha'] as Map<String, dynamic>;
        if (m['prakriti'] != null) {
          parikshaPrakriti.value = _toUiPrakriti(m['prakriti'].toString());
        }
        if (m['sarataha'] != null) {
          parikshaSarataha.value = _toUiPma(m['sarataha'].toString());
        }
        if (m['sanhanan'] != null) {
          parikshaSanhanan.value = _toUiPma(m['sanhanan'].toString());
        }
        if (m['pramana'] != null) {
          parikshaPramana.value = _toUiPma(m['pramana'].toString());
        }
        if (m['satva'] != null) {
          parikshaSatva.value = _toUiPma(m['satva'].toString());
        }
        if (m['satmya'] != null) {
          parikshaSatmya.value = _toUiPma(m['satmya'].toString());
        }
        if (m['aharaShakti'] != null) {
          parikshAhara.value = _toUiPma(m['aharaShakti'].toString());
        }
        if (m['vyayamaShakti'] != null) {
          parikshVyayama.value = _toUiPma(m['vyayamaShakti'].toString());
        }
        if (m['vaya'] != null) {
          parikshVaya.value = _toUiVaya(m['vaya'].toString());
        }
        if (m['jihwa'] != null) {
          parikshJihwa.value = _toUiJihwa(m['jihwa'].toString());
        }
      }

      // 4. Agni
      if (data['agniAssessment'] is Map) {
        final m = data['agniAssessment'] as Map<String, dynamic>;
        final jaranScore = m['jaranShaktiScore'] as int? ?? 0;
        jaranShaktiSelected.clear();
        for (int i = 0; i < jaranScore && i < jaranShaktiSymptoms.length; i++) {
          jaranShaktiSelected.add(i);
        }
        abhyavaharanaIndex.value = m['abhyavaharanaShaktiScore'] as int?;
        ruchiIndex.value = m['ruchiScore'] as int?;
        agniBackendResult.value = AgniAssessmentResult.fromJson(m);
      }

      // 5. Kostha
      if (data['kosthaAssessment'] is Map) {
        final m = data['kosthaAssessment'] as Map<String, dynamic>;
        if (m.containsKey('bowelFrequencyScore')) {
          koshthaAnswers[0] = m['bowelFrequencyScore'] as int?;
          koshthaAnswers[1] = m['consistencyScore'] as int?;
          koshthaAnswers[2] = m['urgencyScore'] as int?;
          koshthaAnswers[3] = m['patientExperienceScore'] as int?;
          koshthaAnswers[4] = m['foodHabitChangeScore'] as int?;
          koshthaAnswers.refresh();
        }
        kosthaBackendResult.value = KosthaAssessmentResult.fromJson(m);
      }

      // 6. Saama/Nirama
      final saamaRaw =
          data['saamaNiramaLakshana'] ??
          data['saamaNirama'] ??
          data['saamaNiramaAssessment'] ??
          data['samaNirama'] ??
          data['saama_nirama'] ??
          data['saama'];
      if (saamaRaw is Map) {
        final m = Map<String, dynamic>.from(saamaRaw);
        final symptomsMap = (m['data'] is Map)
            ? Map<String, dynamic>.from(m['data'] as Map)
            : m;
        const keys = [
          'srotorodha',
          'balabhransha',
          'gaurava',
          'alasya',
          'anilaMudhata',
          'apaki',
          'nishthivana',
          'malaSanga',
          'aruchi',
          'klama',
        ];
        final hasAnyKey = keys.any((k) => symptomsMap.containsKey(k));
        if (hasAnyKey || symptomsMap.containsKey('deepanPachanaRequired')) {
          for (int i = 0; i < keys.length; i++) {
            saamaAnswers[i] = symptomsMap[keys[i]] == true;
          }
          saamaAnswers.refresh();
        }
        saamaBackendResult.value = SaamaNiramaResult.fromJson(symptomsMap);
      }

      // 7. Bala
      if (data['bala'] != null && data['bala'].toString().isNotEmpty) {
        final b = data['bala'].toString();
        bala.value = ApiPoorvaKarmaRepository.normalizeBala(b);
        isBalaFromPoorvaKarma.value = true;
      }

      // 8. Overall completion
      if (data['poorvaKarmaCompleted'] == true) {
        purvakarmaComplete.value = true;
        return 5;
      }

      // Compute resume step
      if (!niruhaAllAnswered) return 0;
      if (!anuvasanAllAnswered) return 1;
      if (!parikshAllFilled) return 2;
      if (!agniAllAnswered) return 3;
      if (!koshthaAllAnswered) return 4;
      return 5;
    } catch (_) {
      return 0;
    } finally {
      isLoadingPoorvaKarma.value = false;
    }
  }

  final isLoadingPradhanaKarma = false.obs;
  bool _hasLoadedPradhanaKarma = false;
  Future<void>? _loadPradhanaKarmaFuture;

  bool get hasLoadedPradhanaKarma => _hasLoadedPradhanaKarma;

  /// Loads previously saved Pradhana Karma assessment from backend for [patientId].
  /// Restores plan details, schedule, and observations.
  Future<void> loadPradhanaKarma({bool forceRefresh = false}) async {
    if (patientId == null || patientId!.isEmpty) return;
    if (_loadPradhanaKarmaFuture != null && !forceRefresh) {
      await _loadPradhanaKarmaFuture;
      return;
    }
    if (_hasLoadedPradhanaKarma && !forceRefresh) return;

    _loadPradhanaKarmaFuture = _loadPradhanaKarmaInternal(forceRefresh: forceRefresh);
    try {
      await _loadPradhanaKarmaFuture;
    } finally {
      _loadPradhanaKarmaFuture = null;
    }
  }

  Future<void> _loadPradhanaKarmaInternal({bool forceRefresh = false}) async {
    if (isLoadingPradhanaKarma.value && !forceRefresh) return;
    isLoadingPradhanaKarma.value = true;
    try {
      await syncBalaFromPoorvaKarma();
      if (initFuture != null) {
        await initFuture;
      }
      final model = await _pradhanaRepo.getPradhanaKarma(patientId!, forceRefresh: forceRefresh);
      if (model != null && model.rawJson != null) {
        final data = model.rawJson!['data'] is Map
            ? Map<String, dynamic>.from(model.rawJson!['data'] as Map)
            : model.rawJson!;

        // 1. Restore Disease
        final mDiseaseId = model.diseaseId?.trim().toLowerCase();
        final mDiseaseName = (model.diseaseName ??
                data['diseaseName']?.toString() ??
                data['disease']?.toString())
            ?.trim()
            .toLowerCase();

        if ((mDiseaseId != null && mDiseaseId.isNotEmpty) ||
            (mDiseaseName != null && mDiseaseName.isNotEmpty)) {
          final matched = availableDiseases.firstWhereOrNull(
            (d) =>
                (mDiseaseId != null &&
                    (d.id.toLowerCase() == mDiseaseId ||
                        (d.mongoId != null &&
                            d.mongoId!.toLowerCase() == mDiseaseId))) ||
                (mDiseaseName != null &&
                    (d.name.toLowerCase() == mDiseaseName ||
                        d.displayLabel.toLowerCase().contains(mDiseaseName))),
          );
          if (matched != null) {
            final isAlreadySelected =
                selectedDisease.value?.id == matched.id &&
                availableBastiOptions.isNotEmpty;
            selectedDisease.value = matched;
            if (!isAlreadySelected) {
              await fetchBastiOptionsForSelectedDisease(forceRefresh: false);
            }
          }
        }

        // 2. Restore Formulation / Option
        final mFormId = model.bastiFormulationId?.trim().toLowerCase();
        final mFormName = (model.formulationName ??
                data['bastiName']?.toString() ??
                data['formulationName']?.toString())
            ?.trim()
            .toLowerCase();

        if ((mFormId != null && mFormId.isNotEmpty) ||
            (mFormName != null && mFormName.isNotEmpty)) {
          final matchedOpt = availableBastiOptions.firstWhereOrNull(
            (o) =>
                (mFormId != null &&
                    (o.id.toLowerCase() == mFormId ||
                        (o.mongoId != null &&
                            o.mongoId!.toLowerCase() == mFormId))) ||
                (mFormName != null && o.name.toLowerCase() == mFormName),
          );
          if (matchedOpt != null) {
            selectedBastiOption.value = matchedOpt;
            selectedBastiType.value = matchedOpt.name;
            formulationCtrl.text = matchedOpt.formulationDetails;
          } else if (model.formulationName != null &&
              !model.formulationName!.contains('Yukti')) {
            selectedBastiType.value = model.formulationName!;
            formulationCtrl.text = model.formulationName!;
          } else if (availableBastiOptions.isNotEmpty) {
            final firstReal = availableBastiOptions.firstWhere(
              (o) => !o.name.contains('Yukti'),
              orElse: () => availableBastiOptions.first,
            );
            selectedBastiOption.value = firstReal;
            selectedBastiType.value = firstReal.name;
            formulationCtrl.text = firstReal.formulationDetails;
          }
        }

        // 3. Restore Pattern
        if (model.bastiPatternCode != null && model.bastiPatternCode!.isNotEmpty) {
          final code = model.bastiPatternCode!.toLowerCase().trim();
          final matched = availablePatterns.firstWhereOrNull(
            (p) => p.code.toLowerCase() == code,
          );
          if (matched != null) {
            selectedPattern.value = matched;
          }
        }

        // 4. Restore Schedule if not yet set
        final rawPatternCode =
            model.bastiPatternCode ?? data['bastiPatternCode']?.toString();
        final rawFormulation =
            model.bastiFormulationId ?? data['bastiFormulationId'];
        final hasValidPattern =
            rawPatternCode != null &&
            rawPatternCode.toString().trim().isNotEmpty;
        final hasValidFormulation =
            rawFormulation != null &&
            rawFormulation.toString().trim().isNotEmpty;

        if (generatedSchedule.isEmpty &&
            (hasValidPattern || hasValidFormulation)) {
          List<String> seq = [];
          if (data['sequence'] is List &&
              (data['sequence'] as List).isNotEmpty) {
            seq = (data['sequence'] as List)
                .map((e) => e.toString().toUpperCase())
                .toList();
          } else if (selectedPattern.value?.sequence != null &&
              selectedPattern.value!.sequence.isNotEmpty) {
            seq = selectedPattern.value!.sequence
                .map((e) => e.toUpperCase())
                .toList();
          } else {
            final patCode = (rawPatternCode ?? 'yoga').toLowerCase().trim();
            final totalDaysRaw = data['totalDays'];
            final int? parsedTotalDays = totalDaysRaw is int
                ? totalDaysRaw
                : int.tryParse(totalDaysRaw?.toString() ?? '');

            if (patCode.contains('karma') || parsedTotalDays == 30) {
              seq = const [
                'A',
                'N',
                'A',
                'N',
                'A',
                'N',
                'A',
                'N',
                'A',
                'N',
                'A',
                'N',
                'A',
                'N',
                'A',
                'N',
                'A',
                'N',
                'A',
                'N',
                'A',
                'N',
                'A',
                'N',
                'A',
                'A',
                'A',
                'A',
                'A',
                'A',
              ];
            } else if (patCode.contains('kala') ||
                parsedTotalDays == 15 ||
                parsedTotalDays == 16) {
              if (parsedTotalDays == 15) {
                seq = const [
                  'A',
                  'N',
                  'A',
                  'N',
                  'A',
                  'N',
                  'A',
                  'N',
                  'A',
                  'N',
                  'A',
                  'N',
                  'A',
                  'A',
                  'A',
                ];
              } else {
                seq = const [
                  'A',
                  'N',
                  'A',
                  'N',
                  'A',
                  'N',
                  'A',
                  'N',
                  'A',
                  'N',
                  'A',
                  'N',
                  'A',
                  'A',
                  'A',
                  'A',
                ];
              }
            } else {
              seq = const ['A', 'N', 'A', 'N', 'A', 'N', 'A', 'A'];
            }
          }

          if (calculatedNiruhaDose.value == null || calculatedAnuvasanaDose.value == null) {
            await recalculateDoses();
          }

          final activeBalaStr = (bala.value ?? 'Madhyama').toLowerCase();
          final defaultNiruha = activeBalaStr == 'pravara'
              ? 600.0
              : (activeBalaStr == 'madhyama' ? 480.0 : 360.0);
          final defaultAnuvasana = activeBalaStr == 'pravara'
              ? 100.0
              : (activeBalaStr == 'madhyama' ? 80.0 : 60.0);

          final niruhaVol = calculatedNiruhaDose.value?.totalVolume ?? defaultNiruha;
          final anuvasanaVol = calculatedAnuvasanaDose.value?.totalVolume ?? defaultAnuvasana;

          final schedule = <BastiScheduleDayModel>[];
          for (int i = 0; i < seq.length; i++) {
            final code = seq[i].trim().toUpperCase();
            final String scheduledType;
            final double scheduledDose;
            final String compSummary;

            if (code == 'MB') {
              scheduledType = 'Matra Basti';
              scheduledDose = calculatedMatraDose.value?.totalVolume ??
                  (anuvasanaVol > 60 ? anuvasanaVol / 2 : anuvasanaVol);
              compSummary = model.formulationName != null
                  ? '${model.formulationName} (Matra Basti)'
                  : 'Matra Sneha Dravya';
            } else if (code == 'YB') {
              scheduledType = 'Yapana Basti';
              scheduledDose = calculatedYapanaDose.value?.totalVolume ?? niruhaVol;
              compSummary = model.formulationName != null
                  ? '${model.formulationName} (Yapana Basti)'
                  : 'Yapana Formulation';
            } else if (code == 'N') {
              scheduledType = 'Niruha';
              scheduledDose = niruhaVol;
              compSummary = model.formulationName ?? 'Niruha Formulation';
            } else {
              scheduledType = 'Anuvasana';
              scheduledDose = anuvasanaVol;
              compSummary = 'Sneha Dravya';
            }

            schedule.add(
              BastiScheduleDayModel(
                dayNumber: i + 1,
                scheduledBastiType: scheduledType,
                bastiTypeCodeShort: code,
                scheduledDose: scheduledDose,
                doseUnit: 'ml',
                compositionSummary: compSummary,
              ),
            );
          }
          generatedSchedule.value = schedule;
          final patName =
              data['patternName'] ??
              '${model.bastiPatternCode ?? "Yoga"} Basti';
          scheduleCtrl.text =
              '$patName (${schedule.length} Days): ${seq.join(" ")}';
          dravyaDoseCtrl.text = 'Niruha: ${niruhaVol.toInt()} ml | Anuvasana: ${anuvasanaVol.toInt()} ml';
          _initSessionsForGeneratedSchedule();
        }

        // 5. Restore Daily Observations
        final obs = data['observation'];
        if (obs is Map && obs['dailyObservations'] is List) {
          final dailyList = obs['dailyObservations'] as List;
          final dailyMap = <int, Map>{};
          for (final item in dailyList) {
            if (item is Map) {
              final rawDay = item['day'] ?? item['dayNumber'];
              final dayNum = rawDay is int
                  ? rawDay
                  : int.tryParse(rawDay?.toString() ?? '');
              if (dayNum != null) {
                final statusStr = item['status']?.toString().toUpperCase();
                final isCompleted = statusStr == 'COMPLETED';
                final existing = dailyMap[dayNum];
                if (existing == null ||
                    isCompleted ||
                    existing['status']?.toString().toUpperCase() != 'COMPLETED') {
                  dailyMap[dayNum] = item;
                }
              }
            }
          }

          for (final item in dailyMap.values) {
            final dayNum = item['day'] as int? ?? (item['dayNumber'] as int?);
            if (dayNum != null && dayNum >= 1 && dayNum <= sessions.length) {
              final sData = sessions[dayNum - 1];
              final statusStr = item['status']?.toString().toUpperCase();
              final isCompleted = statusStr == 'COMPLETED';

                if (!isCompleted) {
                  sData.adanaKala.clear();
                  sData.pratyagamana.clear();
                  sData.vega.clear();
                  for (int i = 0; i < sData.samyaka.length; i++) {
                    sData.samyaka[i] = false;
                  }
                  for (int i = 0; i < sData.ayoga.length; i++) {
                    sData.ayoga[i] = false;
                  }
                  for (int i = 0; i < sData.atiyoga.length; i++) {
                    sData.atiyoga[i] = false;
                  }
                  sData.samyaka.refresh();
                  sData.ayoga.refresh();
                  sData.atiyoga.refresh();
                  continue;
                }

                // Resolve symptoms map (supports both flat and nested 'symptoms' key)
                final symptomMap = (item['symptoms'] is Map)
                    ? Map<String, dynamic>.from(item['symptoms'] as Map)
                    : Map<String, dynamic>.from(item);

                final adminTime = item['timeAdministered']?.toString();
                if (adminTime != null && adminTime.isNotEmpty) {
                  sData.adanaKala.text = adminTime;
                }

                String parsedPratyagamana = item['pratyagamana']?.toString() ??
                    symptomMap['pratyagamana']?.toString() ??
                    '';
                if (parsedPratyagamana.isEmpty && item['notes'] != null) {
                  final match = RegExp(r'Pratyagamana:\s*([^|]+)').firstMatch(item['notes'].toString());
                  if (match != null) {
                    parsedPratyagamana = match.group(1)?.trim() ?? '';
                  }
                }
                if (parsedPratyagamana.isNotEmpty) {
                  sData.pratyagamana.text = parsedPratyagamana;
                }

                String parsedVega = '';
                if (item['notes'] != null) {
                  final match = RegExp(r'Vega:\s*([^|]+)').firstMatch(item['notes'].toString());
                  if (match != null) {
                    parsedVega = match.group(1)?.trim() ?? '';
                  } else if (!item['notes'].toString().contains('Pratyagamana:')) {
                    parsedVega = item['notes'].toString().replaceFirst(RegExp(r'^Vega:\s*'), '').trim();
                  }
                }
                if (parsedVega.isNotEmpty) {
                  sData.vega.text = parsedVega;
                }

                if (dayNum - 1 < generatedSchedule.length) {
                  final isKwatha = generatedSchedule[dayNum - 1].isKwathaBased;
                  if (isKwatha) {
                    const sKeys = [
                      'prasristaVinaMutra',
                      'sameerantwama',
                      'agniVriddhi',
                      'ruchi',
                      'ashayaLaghava',
                      'rogashanti',
                      'prakriti',
                    ];
                    for (
                      int i = 0;
                      i < sKeys.length && i < sData.samyaka.length;
                      i++
                    ) {
                      sData.samyaka[i] =
                          symptomMap[sKeys[i]] == true || item[sKeys[i]] == true;
                      if (i == 6 &&
                          (symptomMap['prakritiBala'] == true ||
                              item['prakritiBala'] == true)) {
                        sData.samyaka[i] = true;
                      }
                    }

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
                    for (
                      int i = 0;
                      i < aKeys.length && i < sData.ayoga.length;
                      i++
                    ) {
                      sData.ayoga[i] =
                          symptomMap[aKeys[i]] == true || item[aKeys[i]] == true;
                      if (i == 0 &&
                          (symptomMap['siroHridGudaBastiMedhraVedana'] == true ||
                              item['siroHridGudaBastiMedhraVedana'] == true)) {
                        sData.ayoga[i] = true;
                      }
                    }

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
                    for (
                      int i = 0;
                      i < atKeys.length && i < sData.atiyoga.length;
                      i++
                    ) {
                      sData.atiyoga[i] =
                          symptomMap[atKeys[i]] == true ||
                          item[atKeys[i]] == true ||
                          (atKeys[i] == 'klama' &&
                              (symptomMap['kalma'] == true ||
                               item['kalma'] == true));
                    }
                  } else {
                    const sKeys = [
                      'sapurishaSnehaPratyeti',
                      'shariraLaghavta',
                      'bala',
                      'srustachVega',
                      'vatanulomana',
                      'agnidipta',
                    ];
                    for (
                      int i = 0;
                      i < sKeys.length && i < sData.samyaka.length;
                      i++
                    ) {
                      sData.samyaka[i] =
                          symptomMap[sKeys[i]] == true || item[sKeys[i]] == true;
                    }

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
                    for (
                      int i = 0;
                      i < aKeys.length && i < sData.ayoga.length;
                      i++
                    ) {
                      sData.ayoga[i] =
                          symptomMap[aKeys[i]] == true || item[aKeys[i]] == true;
                      if (i == 0 &&
                          (symptomMap['adhaShariraRuja'] == true ||
                              item['adhaShariraRuja'] == true)) {
                        sData.ayoga[i] = true;
                      }
                    }

                    const atKeys = [
                      'hrullasa',
                      'moha',
                      'klama',
                      'sada',
                      'murchha',
                      'vikartika',
                    ];
                    for (
                      int i = 0;
                      i < atKeys.length && i < sData.atiyoga.length;
                      i++
                    ) {
                      sData.atiyoga[i] =
                          symptomMap[atKeys[i]] == true ||
                          item[atKeys[i]] == true ||
                          (atKeys[i] == 'klama' &&
                              (symptomMap['kalma'] == true ||
                               item['kalma'] == true));
                    }
                  }
                  sData.samyaka.refresh();
                  sData.ayoga.refresh();
                  sData.atiyoga.refresh();
                }
              }
            }
          observationTick.value++;
        }
      }
      _hasLoadedPradhanaKarma = true;
    } catch (e) {
      debugPrint('Error loading pradhana karma from backend: $e');
    } finally {
      isLoadingPradhanaKarma.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PURVAKARMA
  // ════════════════════════════════════════════════════════════════════════════

  // ── A. Yogya/Ayogya — Niruha contraindications ───────────────────────────
  // null = unanswered, true = Yes, false = No
  // 4 grouped questions per Cha. Si. 1/3-4 & Cha. Si. 2/14
  final niruhaAnswers = List<bool?>.filled(4, null).obs;

  static const List<String> niruhaQuestions = [
    'Does the patient have a history of recent internal Snehana or excessive Snehana, Vamana, Virechana, or Nasya karma?',
    'Does the patient have continuous vomiting, abdominal distension (Adhmana), Ama-Atisara, Alasaka (intestinal torpor), Visuchika (gastroenteritis), intestinal obstruction, perforation of intestine, or ascites?',
    'Does the patient have a history of miscarriage or is currently pregnant?',
    'Does the patient have uncontrolled diabetes, uncontrolled hypertension, or chronic kidney disease?',
  ];

  void setNiruhaAnswer(int index, bool value) {
    niruhaAnswers[index] = value;
    niruhaAnswers.refresh();
  }

  bool get niruhaAllAnswered => niruhaAnswers.every((a) => a != null);

  // ── A. Yogya/Ayogya — Anuvasan contraindications ─────────────────────────
  // 5 grouped questions per Cha. Si. 2/17
  final anuvasanAnswers = List<bool?>.filled(5, null).obs;

  static const List<String> anuvasanQuestions = [
    'Does the patient have any Asthapana (Niruha) Basti contraindication condition?',
    'Does the patient have impaired digestion (Agnimandya)?',
    'Does the patient have diarrhoea (Atisara) or hard bowel / constipation with obstruction?',
    'Does the patient have intestinal worms (Krimi), splenic disorders (Pleeha Roga), Kapha-dominant Udara Roga, or Abhishyandi conditions of Pitta and Kapha?',
    'Does the patient have Aruchi, acute poisoning, coryza (Pratishyaya), Nava Jvara, Pandu, Kamala, Arsha, Urustambha, Shleepada, Galaganda, Apachi, general debility or weakness, Kushta, or Sthaulya?',
  ];

  void setAnuvasanAnswer(int index, bool value) {
    anuvasanAnswers[index] = value;
    anuvasanAnswers.refresh();
  }

  bool get anuvasanAllAnswered => anuvasanAnswers.every((a) => a != null);

  // ── B. Pariksha — dropdowns (auto-filled from CRF) ───────────────────────
  late final parikshaPrakriti = Rxn<String>()..value = _toUiPrakriti(prakriti);
  late final parikshaSarataha = Rxn<String>()..value = _toUiPma(sarataha);
  late final parikshaSanhanan = Rxn<String>()..value = _toUiPma(sanhanan);
  late final parikshaPramana = Rxn<String>()..value = _toUiPma(pramana);
  late final parikshaSatva = Rxn<String>()..value = _toUiPma(satva);
  late final parikshaSatmya = Rxn<String>()..value = _toUiPma(satmya);
  late final parikshAhara = Rxn<String>()..value = _toUiPma(aharaShakti);
  late final parikshVyayama = Rxn<String>()..value = _toUiPma(vyayamaShakti);
  late final parikshVaya = Rxn<String>()
    ..value = vaya.isNotEmpty ? _toUiVaya(vaya) : _inferVaya(patientAge);
  late final parikshJihwa = Rxn<String>()..value = _toUiJihwa(jihwa);

  static String? _inferVaya(int age) {
    if (age <= 0) return null;
    if (age <= 16) return 'Bala (Child 0–16)';
    if (age <= 60) return 'Madhyama (Adult 16–60)';
    return 'Vriddha (Old 60+)';
  }

  static String? _toUiVaya(String v) {
    final lower = v.toLowerCase().trim();
    if (lower.contains('bala') || lower.contains('child')) {
      return 'Bala (Child 0–16)';
    }
    if (lower.contains('vriddha') || lower.contains('old')) {
      return 'Vriddha (Old 60+)';
    }
    if (lower.contains('madhyam') || lower.contains('adult')) {
      return 'Madhyama (Adult 16–60)';
    }
    return v.isNotEmpty ? v : null;
  }

  static String? _toUiPma(String v) {
    if (v.isEmpty) return null;
    final lower = v.toLowerCase().trim();
    if (lower.contains('pravar') || lower.contains('sarvarasa')) {
      return 'Pravar';
    }
    if (lower.contains('avar') ||
        lower.contains('ekarasa') ||
        lower.contains('poor')) {
      return 'Avara';
    }
    if (lower.contains('madhyam') || lower.contains('moderate')) {
      return 'Madhyam';
    }
    return v;
  }

  static String? _toUiPrakriti(String v) {
    if (v.isEmpty) return null;
    final lower = v.toLowerCase().trim();
    if (lower == 'vata') return 'Vata Pradhana';
    if (lower == 'pitta') return 'Pitta Pradhana';
    if (lower == 'kapha') return 'Kapha Pradhana';
    if (lower.contains('sama')) return 'Sama';
    return v;
  }

  static String? _toUiJihwa(String v) {
    if (v.isEmpty) return null;
    final lower = v.toLowerCase().trim();
    if (lower == 'clean' || lower == 'moist' || lower == 'nirlipta') {
      return 'Nirlipta';
    }
    if (lower == 'ishat lipta' || lower == 'ishatlipta') return 'Ishat Lipta';
    if (lower == 'coated' ||
        lower == 'dry' ||
        lower == 'trembling' ||
        lower == 'lipta') {
      return 'Lipta';
    }
    return v;
  }

  bool get parikshAllFilled =>
      parikshaPrakriti.value != null &&
      parikshaSarataha.value != null &&
      parikshaSanhanan.value != null &&
      parikshaPramana.value != null &&
      parikshaSatva.value != null &&
      parikshaSatmya.value != null &&
      parikshAhara.value != null &&
      parikshVyayama.value != null &&
      parikshVaya.value != null &&
      parikshJihwa.value != null;

  // ── C. Agni ─────────────────────────────────────────────────────────────
  // Doctor selects symptoms & options; scoring is computed by the backend.
  static const List<String> jaranShaktiSymptoms = [
    'Utsaha (enthusiasm)',
    'Laghuta (lightness in body)',
    'Udgara Suddhi (clear eructation)',
    'Kshudha and Trishna Pravritti (hunger & thirst)',
    'Yathochita Malotsarga (proper bowel movement)',
  ];
  final jaranShaktiSelected = <int>{}.obs;

  void toggleJaranSymptom(int i) {
    if (jaranShaktiSelected.contains(i)) {
      jaranShaktiSelected.remove(i);
    } else {
      jaranShaktiSelected.add(i);
    }
  }

  // Abhyavaharana Shakti: radio index 0–5
  final abhyavaharanaIndex = Rxn<int>();
  static const List<String> abhyavaharanaOptions = [
    'Not taking food at all',
    'Taking food in less quantity once a day',
    'Taking food in less quantity twice a day',
    'Taking food in moderate quantity twice a day',
    'Taking food in normal quantity twice a day',
    'Taking food in excessive quantity twice or thrice a day',
  ];

  void setAbhyavaharana(int index) {
    abhyavaharanaIndex.value = index;
  }

  // Ruchi: radio index 0–5
  final ruchiIndex = Rxn<int>();
  static const List<String> ruchiOptions = [
    'Totally unwilling for meal',
    'Unwilling for food but could take the meal',
    'Willing only towards most liked food',
    'Willing towards only one taste (pungent, sour or sweet)',
    'Willing towards some specific food or taste',
    'Equally willing towards all food stuffs',
  ];

  void setRuchi(int index) {
    ruchiIndex.value = index;
  }

  /// Deepan Pachana recommendation based on Prakriti + Agni
  String get agniDeepanPachana {
    final p = parikshaPrakriti.value ?? prakriti;
    final isPitta = p.contains('Pitta') || p == 'P';
    if (isPitta) {
      return 'Shankh Vati 2 TID B/F\nPanchatikta Kashaya 60 ml BD B/F';
    }
    return 'Chitrakadi Vati 2 TID B/F\nAampachaka Vati 2 TID A/F';
  }

  bool get agniAllAnswered =>
      jaranShaktiSelected.isNotEmpty &&
      abhyavaharanaIndex.value != null &&
      ruchiIndex.value != null;

  // ── D. Koshtha — hidden scoring ──────────────────────────────────────────
  // 5 questions, each answered a(1)/b(2)/c(3)
  final koshthaAnswers = List<int?>.filled(5, null).obs;

  static const List<String> koshthaQuestions = [
    'Frequency of bowel per day',
    'Consistency of stool',
    'Urgency for bowel movement',
    'Effect of 200 ml milk / 100 gm grapes / 50 gm jaggery on bowel habit',
    'Do changes in food habits affect bowel habits?',
  ];

  static const List<List<String>> koshthaOptions = [
    [
      'Less than once per day',
      'Once or twice per day',
      'More than twice per day',
    ],
    ['Hard stool', 'Soft, well-formed', 'Loose / Watery'],
    [
      'No urgency — sits a long time with discomfort',
      'Moderate urgency, can be controlled',
      'Marked urgency — cannot be controlled',
    ],
    [
      'No change in bowel habit',
      'Normal well-formed stool',
      'Watery / not well-formed stool',
    ],
    ['Frequently hard', 'Occasionally affected', 'Frequently loose'],
  ];

  void setKoshtha(int questionIndex, int optionIndex) {
    // optionIndex 0→score 1, 1→score 2, 2→score 3
    koshthaAnswers[questionIndex] = optionIndex + 1;
    koshthaAnswers.refresh();
  }

  bool get koshthaAllAnswered => koshthaAnswers.every((a) => a != null);

  // ── E. Saama / Nirama ────────────────────────────────────────────────────
  final saamaAnswers = List<bool?>.filled(10, null).obs;

  static const List<String> saamaSymptoms = [
    'Srotorodha — obstruction or clogging of micro channels (intestines, capillaries)',
    'Balabhransha — weakness or loss of strength',
    'Gaurava — heaviness in the body',
    'Alasya — fatigue',
    'Anila Mudhata — obstruction in the flow of Vayu (excrete gas)',
    
    'Apaki — indigestion',
    'Nishthivana — excessive salivation',
    'Mala Sanga — obstruction of Mala (stool, urine, gas)',
    'Aruchi — anorexia',
    'Klama — lethargy (Ashtanga Hridayam, Sutrasthana Chapter 13)',
  ];

  void setSaama(int index, bool value) {
    saamaAnswers[index] = value;
    saamaAnswers.refresh();
  }

  bool get saamaAllAnswered => saamaAnswers.every((a) => a != null);

  // ── F. Bala Assessment ───────────────────────────────────────────────────
  final bala = Rxn<String>();
  final isBalaLoading = false.obs;
  final isBalaFromPoorvaKarma = false.obs;
  static const List<String> balaOptions = ['Pravara', 'Madhyama', 'Avara'];

  /// Synchronizes the patient's assessed Bala from the backend Poorva Karma document.
  Future<void> syncBalaFromPoorvaKarma({bool forceRefresh = false}) async {
    if (patientId == null || patientId!.isEmpty) return;
    if (isBalaFromPoorvaKarma.value && !forceRefresh) return;

    isBalaLoading.value = true;
    try {
      final data = await _poorvaRepo.getPoorvaKarma(patientId!);
      if (data != null) {
        final bRaw = data['bala'] ??
            (data['balaAssessment'] is Map ? (data['balaAssessment'] as Map)['bala'] : null) ??
            (data['data'] is Map ? (data['data'] as Map)['bala'] : null);
        if (bRaw != null && bRaw.toString().trim().isNotEmpty) {
          final normalized = ApiPoorvaKarmaRepository.normalizeBala(bRaw.toString());
          bala.value = normalized;
          isBalaFromPoorvaKarma.value = true;
          debugPrint('Synced patient Bala from Poorva Karma: $normalized');
          return;
        }
      }
    } catch (e) {
      debugPrint('syncBalaFromPoorvaKarma error: $e');
    } finally {
      isBalaLoading.value = false;
    }
  }

  // ── Purvakarma overall completion ────────────────────────────────────────
  bool get canCompletePurvakarma =>
      niruhaAllAnswered &&
      anuvasanAllAnswered &&
      parikshAllFilled &&
      agniAllAnswered &&
      koshthaAllAnswered &&
      saamaAllAnswered &&
      bala.value != null;

  Future<bool> completePurvakarma() async {
    poorvaKarmaError.value = null;
    if (!canCompletePurvakarma) return false;
    if (patientId == null || patientId!.isEmpty) {
      poorvaKarmaError.value =
          'Patient ID is missing. Cannot complete assessment.';
      return false;
    }
    isSavingStep.value = true;
    try {
      final saamaRes = await _poorvaRepo.saveSaamaNirama(
        patientId!,
        List<bool?>.from(saamaAnswers),
      );
      saamaBackendResult.value = saamaRes;
      if (bala.value != null) {
        await _poorvaRepo.saveBala(patientId!, bala.value!);
      }
      await _poorvaRepo.completePoorvaKarma(patientId!);
    } catch (e) {
      poorvaKarmaError.value = e.toString().replaceFirst('Exception: ', '');
      isSavingStep.value = false;
      return false;
    }
    isSavingStep.value = false;
    purvakarmaComplete.value = true;
    return true;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PRADHAN KARMA
  // ════════════════════════════════════════════════════════════════════════════

  final selectedBastiType = Rxn<String>();
  final dravyaDoseCtrl = TextEditingController();
  final formulationCtrl = TextEditingController();
  final scheduleCtrl = TextEditingController();

  // ── Observation — symptom lists ──────────────────────────────────────────

  static const List<String> niruhasamyakaSymptoms = [
    'Prasrista Vina Mutra (proper urine output)',
    'Sameerantwama (proper expulsion of Vayu)',
    'Agni Vriddhi (increase in digestive fire)',
    'Ruchi (appetite restored)',
    'Ashaya Laghava (lightness in abdomen)',
    'Rogashanti (relief from disease)',
    'Prakriti Bala (restoration of natural strength)',
  ];

  static const List<String> niruhaAyogaSymptoms = [
    'Siro-Hrid-Guda-Basti-Medhra Vedana (pain in head/heart/rectum)',
    'Sopha (oedema/swelling)',
    'Pratishyaya (rhinitis/coryza)',
    'Vikartika (rectal cutting pain)',
    'Hrullasa (nausea)',
    'Maruta Sanga (retention of flatus)',
    'Mutra Sanga (retention of urine)',
    'Shvaskashta (difficulty in breathing)',
  ];

  static const List<String> niruhaAtiyogaSymptoms = [
    'Kapha-Pitta-Vata-Rakta Kshayaj Vikara (depletion disorders)',
    'Supti (numbness)',
    'Angamarda (body ache)',
    'Klama (mental fatigue)',
    'Vepathu (tremors)',
    'Nidra Nasha (loss of sleep)',
    'Bala Nasha (loss of strength)',
    'Tama Pravesha (blackout/fainting)',
    'Unmada (mental disturbance)',
    'Hikka (hiccup)',
  ];

  static const List<String> anuvasanSamyakaSymptoms = [
    'Sapurisha Sneha Pratyeti (oily stool passed properly)',
    'Sharira Laghavta (lightness in body)',
    'Bala (strength restored)',
    'Srustach Vega (proper urge for defecation)',
    'Vatanulomana (proper downward movement of Vayu)',
    'Agnidipta (increase in digestive fire)',
  ];

  static const List<String> anuvasanAyogaSymptoms = [
    'Adha Sharira Ruja (pain in lower body)',
    'Udara Ruja (abdominal pain)',
    'Bahu-Prushtha Ruja (pain in arms and back)',
    'Parshva Ruja (flank pain)',
    'Ruksha Gatra (dryness of body)',
    'Ruksha Svara (dryness of voice)',
    'Vit Sanga (retention of stool)',
    'Mutra Sanga (retention of urine)',
  ];

  static const List<String> anuvasanAtiyogaSymptoms = [
    'Hrullasa (nausea)',
    'Moha (confusion/delusion)',
    'Klama (mental fatigue)',
    'Sada (lassitude)',
    'Murchha (fainting)',
    'Vikartika (rectal cutting pain)',
  ];

  List<String> get activeSamyakaSymptoms =>
      selectedBastiType.value == 'Anuvasan Basti'
      ? anuvasanSamyakaSymptoms
      : niruhasamyakaSymptoms;

  List<String> get activeAyogaSymptoms =>
      selectedBastiType.value == 'Anuvasan Basti'
      ? anuvasanAyogaSymptoms
      : niruhaAyogaSymptoms;

  List<String> get activeAtiyogaSymptoms =>
      selectedBastiType.value == 'Anuvasan Basti'
      ? anuvasanAtiyogaSymptoms
      : niruhaAtiyogaSymptoms;

  int get _sessionCountForType {
    switch (selectedBastiType.value) {
      case 'Niruha Basti':
        return 12;
      case 'Anuvasan Basti':
        return 18;
      case 'Yoga Basti':
        return 8;
      case 'Kala Basti':
        return 16;
      case 'Karma Basti':
        return 30;
      default:
        return 12;
    }
  }

  // ── Observation — session list ───────────────────────────────────────────
  final sessions = <BastiSessionData>[].obs;
  final observationTick = 0.obs; // incremented on any symptom toggle

  void _initSessions() {
    if (generatedSchedule.isNotEmpty) {
      // Retain schedule-driven sessions
      return;
    }
    for (final s in sessions) {
      s.dispose();
    }
    sessions.value = List.generate(
      _sessionCountForType,
      (i) => BastiSessionData(
        i + 1,
        samyakaCount: activeSamyakaSymptoms.length,
        ayogaCount: activeAyogaSymptoms.length,
        atiyogaCount: activeAtiyogaSymptoms.length,
      ),
    );
    observationTick.value = 0;
  }

  void toggleSessionSymptom(BastiSessionData session, String type, int i) {
    if (type == 'samyaka') {
      session.samyaka[i] = !session.samyaka[i];
    } else if (type == 'ayoga') {
      session.ayoga[i] = !session.ayoga[i];
    } else if (type == 'atiyoga') {
      session.atiyoga[i] = !session.atiyoga[i];
    }
    observationTick.value++;
  }

  /// Returns the number of COMPLETED sessions from the persisted store.
  /// Falls back to the in-memory heuristic if the controller is not registered.
  int get loggedSessionCount {
    if (Get.isRegistered<TreatmentPlanController>()) {
      return Get.find<TreatmentPlanController>().completedSessionCount;
    }
    // Fallback: count in-memory sessions that have any data
    return sessions
        .where(
          (s) =>
              s.samyaka.any((v) => v) ||
              s.ayoga.any((v) => v) ||
              s.atiyoga.any((v) => v) ||
              s.adanaKala.text.isNotEmpty,
        )
        .length;
  }

  bool get pradhanAllFilled =>
      selectedBastiType.value != null &&
      dravyaDoseCtrl.text.trim().isNotEmpty &&
      scheduleCtrl.text.trim().isNotEmpty;

  /// Completes Pradhan Karma only when:
  /// 1. Plan fields are filled.
  /// 2. ALL sessions are COMPLETED in the persisted store.
  ///
  /// If sessions are not all complete, delegates the validation snackbar
  /// to [TreatmentPlanController.completeTreatment] and blocks completion.
  Future<void> completePradhanKarma() async {
    if (!pradhanAllFilled) return;

    if (Get.isRegistered<TreatmentPlanController>()) {
      final tpc = Get.find<TreatmentPlanController>();
      final success = await tpc.completeTreatment();
      if (!success) return; // snackbar already shown by TreatmentPlanController
    }

    if (patientId != null && patientId!.isNotEmpty) {
      try {
        await _pradhanaRepo.completePradhanaKarma(patientId!);
      } catch (e) {
        debugPrint('Failed to mark pradhana karma complete on backend: $e');
      }
    }

    pradhankarmaComplete.value = true;

    if (Get.isRegistered<PatientController>()) {
      final pc = Get.find<PatientController>();
      final curr = pc.currentPatient.value;
      if (curr != null && curr.id == patientId) {
        pc.currentPatient.value = curr.copyWith(pradhanaKarmaCompleted: true);
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PASCHATKARMA
  // ════════════════════════════════════════════════════════════════════════════

  // Niruha Vyapada — 12 options
  static const List<String> niruhaVyapadas = [
    'None observed',
    'Ayoga (under-action)',
    'Atiyoga (over-action)',
    'Klama (mental fatigue)',
    'Adhmana (flatulence)',
    'Hikka (hiccup)',
    'Hadprapti',
    'Udavarta',
    'Pravahika',
    'Shiro Arti (headache)',
    'Anga Arti (body pain)',
    'Parikartika (rectal pain)',
    'Parisrava (rectal discharge)',
  ];

  static const Map<String, String> niruhaChikitsa = {
    'Ayoga (under-action)':
        'Ushna pramathya, Swedana, Phalaavarti, Virechana, Bilvamuladi Tikshna Basti',
    'Atiyoga (over-action)':
        'Sheeta Basti, Piccha Basti, Anuvasan Basti with Ghrit Manda, Prishnaparnadi Basti with Ghrita',
    'Klama (mental fatigue)':
        'Agnideepanartha Kashaya (Pippali + Lavana). Prasanna, Asava, Arishta prayoga. Gomutra Basti. Swedana and Virukshana measures.',
    'Adhmana (flatulence)':
        'Shyamaphaladi Siddha Taila Anuvasana, Guda Varti, Dashamoola and Gomutra Siddha Niruha Basti',
    'Hikka (hiccup)':
        'Bruhmana Chikitsa. Bala Stiradi Varga Siddha Taila Anuvasana. Vatanashaka Dhuma, Leha, Mamsarasa, Ksheera, Sweda.',
    'Hadprapti':
        'Amla and Lavana Skandha Siddha Niruha Basti, Vataghna Dravya Siddha Anuvasana Basti',
    'Udavarta':
        'Sheeta Ambu Sechana on face if unconscious. Mardana on Parshwa and Udara. If retained — Bilwadi Dwipanchamula Basti. If reaches Shiras — Navana, Dhuma, Lepa of Sarshapa.',
    'Pravahika':
        'Abhyanga with Lavana Taila. Pradhamana Nasya and Dhumapana for Shirovirechana. After food — Tikshna and Vatanulomaka Dravya Siddha Anuvasana Basti.',
    'Shiro Arti (headache)':
        'Abhyanga with Lavana Taila. Pradhamana Nasya and Dhumapana for Shirovirechana. Tikshna Vatanulomaka Dravya Siddha Anuvasana Basti after food.',
    'Anga Arti (body pain)':
        'Abhyanga with Lavana Taila, Ushna Jala Sinchana. Then Niruha Basti with Yava, Kola, Kulatttha, Panchamula Siddha Kwatha.',
    'Parikartika (rectal pain)':
        'Basti with Madhura-Sheeta Dravya. Ksheera Basti (Sarjarasa, Yastimadhu, Jingini, Rasanjana Kalka). Madhura-Amla Rasa pradhana diet.',
    'Parisrava (rectal discharge)':
        'Piccha Basti (Shalmali Pushpa Vrunta + Aja Dugdha or Vatankura + Aja Dugdha). Madhura Gana Sheetala Kwatha Sechana over Guda. Rakta Pitta-Atisara Nashaka Chikitsa.',
  };

  // Anuvasan Vyapada — 6 options
  static const List<String> anuvasanVyapadas = [
    'None observed',
    'Vatavruta Sneha',
    'Pittavruta Sneha',
    'Kaphavruta Sneha',
    'Anna Vruta Sneha',
    'Purisha Vruta Sneha',
    'Abhukta Pranita',
  ];

  static const Map<String, String> anuvasanChikitsa = {
    'Vatavruta Sneha':
        'Rasnadi Tikshna Basti, Rasnadi Siddha Taila Anuvasana Basti',
    'Pittavruta Sneha': 'Basti with Swadu-Tikta Dravyas',
    'Kaphavruta Sneha': 'Tikshna Basti',
    'Anna Vruta Sneha':
        'Pachana with Katu and Lavana Churna and Kwatha. Mrudu Virechana. Amaharan Kriya.',
    'Purisha Vruta Sneha':
        'Snehana, Swedana, Varti. Shyamadibilwadi Siddha Niruha and Anuvasana Basti.',
    'Abhukta Pranita':
        'Niruha Basti prepared with Kashaya Dravyas (Shyama, Trivrutta, Yava, Kola, Kulattha, Gomutra). Anuvasana Basti with the same drugs.',
  };

  final selectedNiruhaVyapada = Rxn<String>();
  final selectedAnuvasanVyapada = Rxn<String>();

  String? get niruhaChikitsaText =>
      selectedNiruhaVyapada.value != null &&
          selectedNiruhaVyapada.value != 'None observed'
      ? niruhaChikitsa[selectedNiruhaVyapada.value]
      : null;

  String? get anuvasanChikitsaText =>
      selectedAnuvasanVyapada.value != null &&
          selectedAnuvasanVyapada.value != 'None observed'
      ? anuvasanChikitsa[selectedAnuvasanVyapada.value]
      : null;

  /// Fetches existing Paschata Karma assessment from the backend and populates the UI.
  Future<void> loadPaschatkarma() async {
    if (patientId == null || patientId!.isEmpty) return;
    if (isLoadingPaschatkarma.value) return;
    isLoadingPaschatkarma.value = true;
    try {
      final existing = await _paschataRepo.getPaschataKarma(patientId!);
      if (existing != null) {
        selectedNiruhaVyapada.value = existing.niruhaUiLabel;
        selectedAnuvasanVyapada.value = existing.anuvasanaUiLabel;
        paschatkarmaComplete.value = true;
      }
    } catch (_) {
      // Graceful degradation: offline or network issue does not block assessment review
    } finally {
      isLoadingPaschatkarma.value = false;
    }
  }

  // ── Paschatkarma save / load state ────────────────────────────────────────
  final paschatkarmaError = RxnString();

  /// Persists Paschata Karma assessment to the backend via PUT /paschata-karma/:patientId.
  ///
  /// Returns `true` on successful save (or when [patientId] is null/empty).
  /// Returns `false` on API failure so caller can block navigation and show Retry UI.
  Future<bool> savePaschatkarma() async {
    paschatkarmaError.value = null;
    if (isSavingPaschatkarma.value) return false;
    if (patientId == null || patientId!.isEmpty) {
      paschatkarmaComplete.value = true;
      return true;
    }
    isSavingPaschatkarma.value = true;
    try {
      final niruha = selectedNiruhaVyapada.value ?? 'None observed';
      final anuvasana = selectedAnuvasanVyapada.value ?? 'None observed';
      await _paschataRepo.savePaschataKarma(
        patientId!,
        niruhaVyapada: niruha,
        anuvasanaVyapada: anuvasana,
      );
      paschatkarmaComplete.value = true;

      if (Get.isRegistered<PatientController>()) {
        final pc = Get.find<PatientController>();
        final curr = pc.currentPatient.value;
        if (curr != null && curr.id == patientId) {
          pc.currentPatient.value = curr.copyWith(paschataKarmaCompleted: true);
        }
      }
      return true;
    } catch (e) {
      paschatkarmaError.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSavingPaschatkarma.value = false;
    }
  }

  // Parihara vishaya checklist (always shown, read-only)
  static const List<String> pariharaItems = [
    'Take light and easily digestible food (Laghu Supachya Ahara)',
    'Avoid excessive sitting',
    'Avoid standing for a long time',
    'Avoid travelling',
    'Avoid daytime sleeping',
    'Avoid sexual intercourse',
    'Avoid suppression of natural urges',
    'Avoid indulgence in cold things',
    'Avoid sunlight exposure',
    'Avoid worrying',
    'Avoid anger',
    'Avoid untimely food',
    'Avoid unwholesome food',
    'Follow restrictions for double the duration of treatment',
  ];

  @override
  void onClose() {
    dravyaDoseCtrl.dispose();
    formulationCtrl.dispose();
    scheduleCtrl.dispose();
    for (final s in sessions) {
      s.dispose();
    }
    super.onClose();
  }
}
