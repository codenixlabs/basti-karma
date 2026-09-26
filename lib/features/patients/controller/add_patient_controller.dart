import 'dart:io';
import 'package:bastikarma/app/core/routes/app_pages.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/core/theme/app_theme.dart';
import '../../../app/data/models/master/disease_model.dart';
import '../../../app/data/models/patient/patient_model.dart';
import '../../../app/data/repositories/api_patient_repository.dart';
import '../../../app/data/repositories/basti_clinical_repository.dart';
import '../../../app/shared/utils/custom_snackbar.dart';
import '../screen/patient_detail_screen.dart';
import 'patient_controller.dart';

class AddPatientController extends GetxController {
  // ── Page controller ──────────────────────────────────────────
  final pageController = PageController();

  // ── Step tracking ────────────────────────────────────────────
  final currentStep = 0.obs;

  // ── Edit mode tracking ───────────────────────────────────────
  final editingPatient = Rxn<PatientModel>();
  bool get isEditMode => editingPatient.value != null;

  bool get isFemale => sex.value == 'Female';

  int get totalSteps => isFemale ? 9 : 8;

  List<String> get allStepTitles => [
    'Basic Patient Info',
    'Hospital Information',
    'Clinical Information',
    'Lifestyle & Habits',
    if (isFemale) 'Menstrual & Obstetric',
    'General Examination',
    'Rogi Pariksha',
    'Investigations',
    'Treatment',
  ];

  // ── Validation callbacks ─────────────────────────────────────
  final _validationCallbacks = <int, bool Function()>{};

  void registerValidation(int step, bool Function() validator) {
    _validationCallbacks[step] = validator;
  }

  // ── Step 1 — Basic Info ──────────────────────────────────────
  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final occupationCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  final nameFocus = FocusNode();
  final ageFocus = FocusNode();
  final phoneFocus = FocusNode();
  final occupationFocus = FocusNode();
  final addressFocus = FocusNode();

  final sex = Rxn<String>();
  final religion = Rxn<String>();
  final maritalStatus = Rxn<String>();

  // ── Step 2 — Hospital Info ───────────────────────────────────
  final admissionType = 'OPD'.obs;
  final opdCtrl = TextEditingController();
  final ipdCtrl = TextEditingController();
  final diagnosisCtrl = TextEditingController();
  final selectedDisease = Rxn<DiseaseModel>();
  final availableDiseases = <DiseaseModel>[].obs;

  final opdFocus = FocusNode();
  final ipdFocus = FocusNode();
  final diagnosisFocus = FocusNode();

  @override
  void onInit() {
    super.onInit();
    _loadDiseases();
    weightCtrl.addListener(calcBmi);
    heightCtrl.addListener(calcBmi);
  }

  Future<void> _loadDiseases() async {
    try {
      final repo = BastiClinicalRepository();
      final list = await repo.getDiseases();
      final sortedList = List<DiseaseModel>.from(list)
        ..sort((a, b) => a.displayLabel.trim().toLowerCase().compareTo(b.displayLabel.trim().toLowerCase()));
      availableDiseases.value = sortedList;
      if (editingPatient.value != null) {
        _matchEditingPatientDisease(editingPatient.value!);
      }
    } catch (e, stack) {
      debugPrint('[AddPatientController] Error loading diseases: $e\n$stack');
    }
  }

  void _matchEditingPatientDisease(PatientModel patient) {
    final target = (patient.clinicalDiseaseSelection ?? patient.diagnosis).trim();
    if (target.isEmpty) return;
    final match = availableDiseases.firstWhereOrNull(
      (d) =>
          d.id == patient.diseaseId ||
          d.name.toLowerCase() == target.toLowerCase() ||
          d.displayLabel.toLowerCase() == target.toLowerCase() ||
          d.englishName.toLowerCase() == target.toLowerCase(),
    );
    if (match != null) {
      selectedDisease.value = match;
    } else {
      final newDisease = DiseaseModel(
        id: patient.diseaseId ?? 'disease_${patient.id}',
        name: target,
        englishName: target,
        description: 'Patient Diagnosis',
      );
      availableDiseases.add(newDisease);
      selectedDisease.value = newDisease;
    }
  }

  // ── Edit & Reset Initialization ──────────────────────────────
  void initForEdit(PatientModel patient, {int initialStep = 0}) {
    editingPatient.value = patient;

    // Step 1: Basic Info
    nameCtrl.text = patient.name;
    ageCtrl.text = patient.age > 0 ? patient.age.toString() : '';
    sex.value = patient.sex.isNotEmpty ? patient.sex : null;
    phoneCtrl.text = patient.phoneNo ?? patient.phone ?? '';
    occupationCtrl.text = patient.occupation ?? '';
    addressCtrl.text = patient.address ?? '';
    religion.value = (patient.religion != null && patient.religion!.isNotEmpty)
        ? patient.religion
        : null;
    maritalStatus.value =
        (patient.maritalStatus != null && patient.maritalStatus!.isNotEmpty)
            ? patient.maritalStatus
            : null;

    // Step 2: Hospital Info
    admissionType.value =
        patient.admissionType.isNotEmpty ? patient.admissionType : 'OPD';
    opdCtrl.text = patient.opdNumber ?? patient.opdNo ?? '';
    ipdCtrl.text = patient.ipdNumber ?? patient.ipdNo ?? '';
    diagnosisCtrl.text = patient.customDiagnosis ?? patient.diagnosis;
    if (availableDiseases.isNotEmpty) {
      _matchEditingPatientDisease(patient);
    }

    // Step 3: Clinical Info
    chiefComplaintsCtrl.text = patient.chiefComplaints ?? '';
    presentIllnessCtrl.text = patient.historyOfPresentIllness ?? '';
    pastIllnessCtrl.text = patient.historyOfPastIllness ?? '';
    familyHistoryCtrl.text = patient.familyHistory ?? '';

    // Step 4: Lifestyle
    diet.value = PatientModel.normalizeAharaFromBackend(patient.ahara);
    addictions.clear();
    otherAddictionCtrl.clear();
    final rawAddiction = patient.addiction?.trim();
    if (rawAddiction != null && rawAddiction.isNotEmpty) {
      if (rawAddiction == 'None' ||
          rawAddiction == 'No / NA' ||
          rawAddiction == 'NA' ||
          rawAddiction == 'No') {
        addictions.add('No / NA');
      } else {
        final split = rawAddiction.split(',').map((s) => s.trim()).toList();
        for (final item in split) {
          if (item.toLowerCase().startsWith('others')) {
            addictions.add('Others');
            final match = RegExp(r'\((.*?)\)').firstMatch(item);
            if (match != null) {
              otherAddictionCtrl.text = match.group(1) ?? '';
            }
          } else if (item.isNotEmpty) {
            addictions.add(item);
          }
        }
      }
    }
    bowelHabits.value =
        (patient.bowelHabits != null && patient.bowelHabits!.isNotEmpty)
            ? patient.bowelHabits
            : null;
    nidra.value =
        (patient.nidra != null && patient.nidra!.isNotEmpty)
            ? patient.nidra
            : null;
    bloodGroup.value =
        (patient.bloodGroup != null && patient.bloodGroup!.isNotEmpty)
            ? patient.bloodGroup
            : null;
    urineFreqCtrl.text = patient.urineFrequency ?? '';

    // Step 5: Female History
    menstrualHistoryCtrl.text = patient.menstrualHistory ?? '';
    deliveriesCtrl.text = patient.numberOfDeliveries?.toString() ?? '';
    abortionCtrl.text = patient.abortion?.toString() ?? '';
    surgicalCtrl.text = patient.surgicalIntervention ?? '';

    // Step 6: General Exam
    bpCtrl.text = patient.bp ?? '';
    rrCtrl.text = patient.rr != null ? patient.rr.toString() : '';
    hrCtrl.text = patient.hr != null ? patient.hr.toString() : '';
    tempCtrl.text = patient.temperature != null ? patient.temperature.toString() : '';
    weightCtrl.text = patient.weight != null ? patient.weight.toString() : '';
    heightCtrl.text = patient.height != null ? patient.height.toString() : '';
    calcBmi();

    // Step 7: Rogi Pariksha (mapped to UI options)
    prakriti.value = patient.prakriti.isNotEmpty ? patient.prakriti : null;
    sarataha.value = patient.sarataha.isNotEmpty ? toUiQuality(patient.sarataha) : null;
    sanhanan.value = patient.sanhanan.isNotEmpty ? toUiQuality(patient.sanhanan) : null;
    pramana.value = patient.pramana.isNotEmpty ? toUiQuality(patient.pramana) : null;
    satva.value = patient.satva.isNotEmpty ? toUiQuality(patient.satva) : null;
    satmya.value = patient.satmya.isNotEmpty ? toUiSatmya(patient.satmya) : null;
    aharaShakti.value = patient.aharaShakti.isNotEmpty
        ? (patient.aharaShakti.contains('Madhyam') ? 'Madhyama' : patient.aharaShakti)
        : null;
    vyayamaShakti.value = patient.vyayamaShakti.isNotEmpty
        ? (patient.vyayamaShakti.contains('Madhyam') ? 'Madhyama' : patient.vyayamaShakti)
        : null;
    vaya.value = patient.vaya.isNotEmpty ? toUiVaya(patient.vaya) : null;
    jihwa.value = patient.jihwa.isNotEmpty ? toUiJihwa(patient.jihwa) : null;
    desha.value = patient.desha.isNotEmpty ? toUiDesha(patient.desha) : null;

    // Step 8: Investigations
    pathologicalRadiologicalCtrl.text =
        patient.pathologicalRadiological ?? '';
    if (patient.photoUrl != null && patient.photoUrl!.isNotEmpty) {
      selectedDocumentName.value = 'Existing Document Attached';
    } else {
      selectedDocumentName.value = null;
    }
    selectedDocument.value = null;

    // Step 9: Treatment
    treatmentCtrl.text = patient.treatmentGiven ?? '';

    final maxStep = totalSteps - 1;
    final targetStep = (initialStep >= 0 && initialStep <= maxStep) ? initialStep : 0;
    currentStep.value = targetStep;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.jumpToPage(targetStep);
      }
    });
  }

  void resetForm() {
    editingPatient.value = null;
    currentStep.value = 0;
    nameCtrl.clear();
    ageCtrl.clear();
    phoneCtrl.clear();
    occupationCtrl.clear();
    addressCtrl.clear();
    sex.value = null;
    religion.value = null;
    maritalStatus.value = null;
    admissionType.value = 'OPD';
    opdCtrl.clear();
    ipdCtrl.clear();
    diagnosisCtrl.clear();
    selectedDisease.value = null;
    chiefComplaintsCtrl.clear();
    presentIllnessCtrl.clear();
    pastIllnessCtrl.clear();
    familyHistoryCtrl.clear();
    diet.value = null;
    addictions.clear();
    otherAddictionCtrl.clear();
    bowelHabits.value = null;
    nidra.value = null;
    bloodGroup.value = null;
    urineFreqCtrl.clear();
    menstrualHistoryCtrl.clear();
    deliveriesCtrl.clear();
    abortionCtrl.clear();
    surgicalCtrl.clear();
    bpCtrl.clear();
    rrCtrl.clear();
    hrCtrl.clear();
    tempCtrl.clear();
    weightCtrl.clear();
    heightCtrl.clear();
    bmiDisplay.value = '';
    prakriti.value = null;
    sarataha.value = null;
    sanhanan.value = null;
    pramana.value = null;
    satva.value = null;
    satmya.value = null;
    aharaShakti.value = null;
    vyayamaShakti.value = null;
    vaya.value = null;
    jihwa.value = null;
    desha.value = null;
    pathologicalRadiologicalCtrl.clear();
    selectedDocument.value = null;
    selectedDocumentName.value = null;
    treatmentCtrl.clear();
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
  }

  void goToStep(int step) {
    if (step < 0 || step >= totalSteps) return;
    _dismissKeyboard();
    currentStep.value = step;
    if (pageController.hasClients) {
      pageController.jumpToPage(step);
    }
  }

  void addNewDisease(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final existing = availableDiseases.firstWhereOrNull(
      (d) =>
          d.name.toLowerCase() == trimmed.toLowerCase() ||
          d.displayLabel.toLowerCase() == trimmed.toLowerCase(),
    );
    if (existing != null) {
      selectedDisease.value = existing;
      diagnosisCtrl.text = existing.name;
      return;
    }

    final newDisease = DiseaseModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmed,
      englishName: trimmed,
      description: 'Custom added disease',
    );

    availableDiseases.add(newDisease);
    availableDiseases.sort(
      (a, b) => a.displayLabel.trim().toLowerCase().compareTo(b.displayLabel.trim().toLowerCase()),
    );
    selectedDisease.value = newDisease;
    diagnosisCtrl.text = newDisease.name;
  }

  // ── Step 3 — Clinical Info ───────────────────────────────────
  final chiefComplaintsCtrl = TextEditingController();
  final presentIllnessCtrl = TextEditingController();
  final pastIllnessCtrl = TextEditingController();
  final familyHistoryCtrl = TextEditingController();

  final chiefComplaintsFocus = FocusNode();
  final presentIllnessFocus = FocusNode();
  final pastIllnessFocus = FocusNode();
  final familyHistoryFocus = FocusNode();

  // ── Step 4 — Lifestyle ───────────────────────────────────────
  final diet = Rxn<String>();
  final addictions = <String>{}.obs;
  final otherAddictionCtrl = TextEditingController();
  final bowelHabits = Rxn<String>();
  final nidra = Rxn<String>();
  final bloodGroup = Rxn<String>();
  final urineFreqCtrl = TextEditingController();

  final urineFreqFocus = FocusNode();
  final otherAddictionFocus = FocusNode();

  bool get hasOtherAddiction => addictions.contains('Others');

  void toggleAddiction(String opt) {
    final isNoneOption = opt == 'No / NA' || opt == 'NA' || opt == 'No';
    if (isNoneOption) {
      if (addictions.contains(opt)) {
        addictions.remove(opt);
      } else {
        addictions.clear();
        otherAddictionCtrl.clear();
        addictions.add(opt);
      }
      return;
    }

    addictions.remove('No / NA');
    addictions.remove('NA');
    addictions.remove('No');
    if (addictions.contains(opt)) {
      addictions.remove(opt);
      if (opt == 'Others') otherAddictionCtrl.clear();
    } else {
      addictions.add(opt);
    }
  }

  // ── Step 5 — Female History ──────────────────────────────────
  final menstrualHistoryCtrl = TextEditingController();
  final deliveriesCtrl = TextEditingController();
  final abortionCtrl = TextEditingController();
  final surgicalCtrl = TextEditingController();

  final menstrualHistoryFocus = FocusNode();
  final deliveriesFocus = FocusNode();
  final abortionFocus = FocusNode();
  final surgicalFocus = FocusNode();

  // ── Step 6 — General Exam ────────────────────────────────────
  final bpCtrl = TextEditingController();
  final rrCtrl = TextEditingController();
  final hrCtrl = TextEditingController();
  final tempCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();

  final bpFocus = FocusNode();
  final rrFocus = FocusNode();
  final hrFocus = FocusNode();
  final tempFocus = FocusNode();
  final weightFocus = FocusNode();
  final heightFocus = FocusNode();

  final bmiDisplay = ''.obs;

  void calcBmi() {
    final w = double.tryParse(weightCtrl.text);
    final h = double.tryParse(heightCtrl.text);
    if (w != null && h != null && h > 0) {
      final hm = h / 100;
      final bmi = w / (hm * hm);
      String cat;
      if (bmi < 18.5) {
        cat = 'Underweight';
      } else if (bmi < 25) {
        cat = 'Normal';
      } else if (bmi < 30) {
        cat = 'Overweight';
      } else {
        cat = 'Obese';
      }
      bmiDisplay.value = '${bmi.toStringAsFixed(1)} ($cat)';
    } else {
      bmiDisplay.value = '';
    }
  }

  // ── Step 7 — Rogi Pariksha ───────────────────────────────────
  final prakriti = Rxn<String>();
  final sarataha = Rxn<String>();
  final sanhanan = Rxn<String>();
  final pramana = Rxn<String>();
  final satva = Rxn<String>();
  final satmya = Rxn<String>();
  final aharaShakti = Rxn<String>();
  final vyayamaShakti = Rxn<String>();
  final vaya = Rxn<String>();
  final jihwa = Rxn<String>();
  final desha = Rxn<String>();

  void inferVaya() {
    final age = int.tryParse(ageCtrl.text);
    if (age == null) return;
    if (age <= 16) {
      vaya.value = 'Bala (Child 0–16)';
    } else if (age <= 60) {
      vaya.value = 'Madhyama (Adult 16–60)';
    } else {
      vaya.value = 'Vriddha (Old 60+)';
    }
  }

  static String? toUiVaya(String v) {
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

  static String? toUiQuality(String v) {
    final lower = v.toLowerCase().trim();
    if (lower.contains('pravar') || lower.contains('excellent')) {
      return 'Pravara (Excellent)';
    }
    if (lower.contains('madhyam') || lower.contains('moderate')) {
      return 'Madhyama (Moderate)';
    }
    if (lower.contains('avar') || lower.contains('poor')) {
      return 'Avara (Poor)';
    }
    return v.isNotEmpty ? v : null;
  }

  static String? toUiSatmya(String v) {
    final lower = v.toLowerCase().trim();
    if (lower.contains('sarvarasa') || lower.contains('pravar')) {
      return 'Sarvarasa Satmya';
    }
    if (lower.contains('madhyam')) {
      return 'Madhyama Satmya';
    }
    if (lower.contains('ekarasa') || lower.contains('avar')) {
      return 'Ekarasa Satmya';
    }
    return v.isNotEmpty ? v : null;
  }

  static String? toUiDesha(String v) {
    final lower = v.toLowerCase().trim();
    if (lower.contains('anupa') || lower.contains('marshy')) {
      return 'Anupa (Marshy)';
    }
    if (lower.contains('jangala') || lower.contains('desert') || lower.contains('dry')) {
      return 'Jangala (Dry/Desert)';
    }
    if (lower.contains('sadharan') || lower.contains('normal')) {
      return 'Sadharana (Normal)';
    }
    return v.isNotEmpty ? v : null;
  }

  static String? toUiJihwa(String v) {
    final lower = v.toLowerCase().trim();
    if (lower.contains('ishat')) return 'Ishat lipta';
    if (lower.contains('nirlipta') || lower.contains('clean') || lower.contains('moist')) return 'Nirlipta';
    if (lower.contains('lipta') || lower.contains('coated')) return 'Lipta';
    return v.isNotEmpty ? v : null;
  }

  // ── Step 8 — Investigations ──────────────────────────────────
  final pathologicalRadiologicalCtrl = TextEditingController();
  final pathologicalRadiologicalFocus = FocusNode();

  final selectedDocument = Rxn<File>();
  final selectedDocumentName = RxnString();
  final _picker = ImagePicker();

  /// Maximum allowed file size for document/photo uploads: 5 MB
  static const int maxFileSizeInBytes = 5 * 1024 * 1024;

  Future<void> pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        CustomSnackBar.showWarning(
          'Camera access is required to take photos.',
          title: 'Permission Denied',
        );
        return;
      }
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (file != null) {
        final f = File(file.path);
        final size = await f.length();
        if (size > maxFileSizeInBytes) {
          CustomSnackBar.showError(
            'File size exceeds the 5 MB limit. Please select a smaller file.',
          );
          return;
        }
        selectedDocument.value = f;
        selectedDocumentName.value = file.name;
      }
    } catch (e) {
      CustomSnackBar.showError('Could not pick image. Please try again.');
    }
  }

  Future<void> pickPdf() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (files.isNotEmpty) {
        final platformFile = files.first;
        final path = platformFile.path;
        if (path != null) {
          final file = File(path);
          final size = await file.length();
          if (size > maxFileSizeInBytes) {
            CustomSnackBar.showError(
              'File size exceeds the 5 MB limit. Please select a smaller PDF.',
            );
            return;
          }
          selectedDocument.value = file;
          selectedDocumentName.value = platformFile.name;
        }
      }
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        CustomSnackBar.showError(
          'Please completely stop and restart the app to enable PDF picking.',
        );
      } else {
        CustomSnackBar.showError('Could not pick PDF document: $e');
      }
    }
  }

  void removeDocument() {
    selectedDocument.value = null;
    selectedDocumentName.value = null;
  }

  void showImageSourceSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Upload Document / Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Supported: Camera, Gallery, or PDF (Max 5 MB)',
              style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceTile(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () {
                      Get.back();
                      pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImageSourceTile(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: () {
                      Get.back();
                      pickImage(ImageSource.gallery);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImageSourceTile(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF File',
                    onTap: () {
                      Get.back();
                      pickPdf();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Step 9 — Treatment ───────────────────────────────────────
  final treatmentCtrl = TextEditingController();
  final treatmentFocus = FocusNode();



  // ── Navigation ───────────────────────────────────────────────
  final isSubmitting = false.obs;

  /// Dismiss keyboard before any page transition so focus nodes
  /// from the previous step don't linger into the next step.
  void _dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  void next() {
    _dismissKeyboard();
    if (currentStep.value >= totalSteps - 1) return;
    currentStep.value++;
    pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void validateAndNext() {
    final validator = _validationCallbacks[currentStep.value];
    if (validator != null && !validator()) return;
    if (currentStep.value == 0) inferVaya();
    next();
  }

  void submitForm() async {
    if (isSubmitting.value) return;
    final validator = _validationCallbacks[currentStep.value];
    if (validator != null && !validator()) return;

    if (nameCtrl.text.trim().isEmpty) {
      CustomSnackBar.showError('Patient name cannot be empty');
      return;
    }

    _dismissKeyboard();
    isSubmitting.value = true;

    try {
      // ── Persist patient via PatientController ─────────────────────────────
      final clinicalDisease = selectedDisease.value?.name ??
          (diagnosisCtrl.text.trim().isNotEmpty ? diagnosisCtrl.text.trim() : '');
      final customDiag = diagnosisCtrl.text.trim().isNotEmpty
          ? diagnosisCtrl.text.trim()
          : (selectedDisease.value?.name ?? '');

      // Combine addictions
      String? combinedAddiction;
      if (addictions.isNotEmpty) {
        if (addictions.any((a) => a == 'No / NA' || a == 'NA' || a == 'No')) {
          combinedAddiction = 'None';
        } else {
          final list = addictions.map((a) => a == 'Others' && otherAddictionCtrl.text.trim().isNotEmpty
              ? 'Others (${otherAddictionCtrl.text.trim()})'
              : a).toList();
          combinedAddiction = list.join(', ');
        }
      }

      // Calculate BMI
      num? parsedBmi;
      final w = double.tryParse(weightCtrl.text.trim());
      final h = double.tryParse(heightCtrl.text.trim());
      if (w != null && h != null && h > 0) {
        final hm = h / 100;
        parsedBmi = double.parse((w / (hm * hm)).toStringAsFixed(1));
      }

      final isEditing = isEditMode;
      final existing = editingPatient.value;

      final patient = PatientModel(
        id: existing != null
            ? existing.id
            : 'pat_${DateTime.now().millisecondsSinceEpoch}',
        name: nameCtrl.text.trim(),
        age: int.tryParse(ageCtrl.text) ?? 0,
        sex: sex.value ?? (existing?.sex ?? ''),
        phoneNo: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        occupation:
            occupationCtrl.text.trim().isEmpty ? null : occupationCtrl.text.trim(),
        address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
        religion: religion.value,
        maritalStatus: maritalStatus.value,
        admissionType: admissionType.value,
        opdNumber: opdCtrl.text.trim().isEmpty ? null : opdCtrl.text.trim(),
        ipdNumber: ipdCtrl.text.trim().isEmpty ? null : ipdCtrl.text.trim(),
        clinicalDiseaseSelection: clinicalDisease.isNotEmpty ? clinicalDisease : null,
        customDiagnosis: customDiag.isNotEmpty ? customDiag : null,
        diagnosis: customDiag.isNotEmpty
            ? customDiag
            : (clinicalDisease.isNotEmpty ? clinicalDisease : 'Ayurvedic Treatment'),
        diseaseId: selectedDisease.value?.id ?? existing?.diseaseId,
        chiefComplaints: chiefComplaintsCtrl.text.trim().isNotEmpty
            ? chiefComplaintsCtrl.text.trim()
            : (diagnosisCtrl.text.trim().isNotEmpty ? diagnosisCtrl.text.trim() : null),
        historyOfPresentIllness:
            presentIllnessCtrl.text.trim().isNotEmpty ? presentIllnessCtrl.text.trim() : null,
        historyOfPastIllness:
            pastIllnessCtrl.text.trim().isNotEmpty ? pastIllnessCtrl.text.trim() : null,
        familyHistory:
            familyHistoryCtrl.text.trim().isNotEmpty ? familyHistoryCtrl.text.trim() : null,
        ahara: PatientModel.normalizeAharaToBackend(diet.value),
        vihara: 'Sedentary',
        addiction: (combinedAddiction != null && combinedAddiction.isNotEmpty)
            ? combinedAddiction
            : 'None',
        bowelHabits: bowelHabits.value,
        nidra: nidra.value,
        urineFrequency:
            urineFreqCtrl.text.trim().isNotEmpty ? urineFreqCtrl.text.trim() : null,
        bloodGroup: bloodGroup.value,
        bp: bpCtrl.text.trim().isNotEmpty ? bpCtrl.text.trim() : null,
        rr: rrCtrl.text.trim().isNotEmpty ? rrCtrl.text.trim() : null,
        hr: hrCtrl.text.trim().isNotEmpty ? hrCtrl.text.trim() : null,
        temperature: tempCtrl.text.trim().isNotEmpty ? tempCtrl.text.trim() : null,
        weight: w,
        height: h,
        bmi: parsedBmi,
        prakriti: prakriti.value ?? '',
        sarataha: sarataha.value ?? '',
        sanhanan: sanhanan.value ?? '',
        pramana: pramana.value ?? '',
        satva: satva.value ?? '',
        satmya: satmya.value ?? '',
        aharaShakti: aharaShakti.value ?? '',
        vyayamaShakti: vyayamaShakti.value ?? '',
        vaya: vaya.value ?? '',
        jihwa: jihwa.value ?? '',
        desha: desha.value ?? '',
        menstrualHistory:
            isFemale && menstrualHistoryCtrl.text.trim().isNotEmpty
                ? menstrualHistoryCtrl.text.trim()
                : null,
        numberOfDeliveries:
            isFemale ? int.tryParse(deliveriesCtrl.text.trim()) : null,
        abortion: isFemale ? int.tryParse(abortionCtrl.text.trim()) : null,
        surgicalIntervention:
            isFemale && surgicalCtrl.text.trim().isNotEmpty
                ? surgicalCtrl.text.trim()
                : null,
        pathologicalRadiological:
            pathologicalRadiologicalCtrl.text.trim().isEmpty
                ? null
                : pathologicalRadiologicalCtrl.text.trim(),
        photoUrl: selectedDocument.value != null ? null : existing?.photoUrl,
        treatmentGiven:
            treatmentCtrl.text.trim().isEmpty ? null : treatmentCtrl.text.trim(),
        poorvaKarmaCompleted: existing?.poorvaKarmaCompleted ?? false,
        pradhanaKarmaCompleted: existing?.pradhanaKarmaCompleted ?? false,
        paschataKarmaCompleted: existing?.paschataKarmaCompleted ?? false,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );

      if (isEditing) {
        if (Get.isRegistered<PatientController>()) {
          final pCtrl = Get.find<PatientController>();
          await pCtrl.updatePatient(
            patient,
            photoFile: selectedDocument.value,
          );
        } else {
          final repo = ApiPatientRepository();
          await repo.updatePatient(patient, photoFile: selectedDocument.value);
        }

        CustomSnackBar.showSuccess('Patient details updated successfully');
        Get.back(result: patient);
        return;
      }

      PatientModel createdPatient = patient;
      if (Get.isRegistered<PatientController>()) {
        final pCtrl = Get.find<PatientController>();
        final generatedId = await pCtrl.addPatient(
          patient,
          photoFile: selectedDocument.value,
        );
        createdPatient = patient.copyWith(id: generatedId);
        pCtrl.selectPatient(createdPatient);
      }

      CustomSnackBar.showSuccess('Patient record created successfully');
      Get.offAllNamed(AppRoutes.home);
      Get.to(() => PatientDetailScreen(patient: createdPatient));
    } catch (e) {
      CustomSnackBar.showError('Failed to save patient: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  void prev() {
    _dismissKeyboard();
    if (currentStep.value == 0) {
      Get.back();
      return;
    }
    currentStep.value--;
    pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  String get stepTitle {
    final titles = allStepTitles;
    final i = currentStep.value;
    return i < titles.length
        ? titles[i]
        : (isEditMode ? 'Edit Patient Details' : 'Add New Patient');
  }

  Map<String, dynamic> buildPayload() => {
    'name': nameCtrl.text.trim(),
    'age': int.tryParse(ageCtrl.text),
    'sex': sex.value,
    'phone': phoneCtrl.text.trim(),
    'occupation': occupationCtrl.text.trim(),
    'address': addressCtrl.text.trim(),
    'religion': religion.value,
    'maritalStatus': maritalStatus.value,
    'admissionType': admissionType.value,
    'opdNo': opdCtrl.text.trim(),
    'ipdNo': ipdCtrl.text.trim(),
    'diagnosis': diagnosisCtrl.text.trim(),
    'chiefComplaints': chiefComplaintsCtrl.text.trim(),
    'historyPresentIllness': presentIllnessCtrl.text.trim(),
    'historyPastIllness': pastIllnessCtrl.text.trim(),
    'familyHistory': familyHistoryCtrl.text.trim(),
    'diet': PatientModel.normalizeAharaToBackend(diet.value),
    'addictions': addictions.toList(),
    'otherAddiction': otherAddictionCtrl.text.trim(),
    'bowelHabits': bowelHabits.value,
    'nidra': nidra.value,
    'bloodGroup': bloodGroup.value,
    'urineFrequency': urineFreqCtrl.text.trim(),
    if (isFemale) ...{
      'menstrualHistory': menstrualHistoryCtrl.text.trim(),
      'numberOfDeliveries': int.tryParse(deliveriesCtrl.text),
      'abortion': int.tryParse(abortionCtrl.text),
      'surgicalIntervention': surgicalCtrl.text.trim(),
    },
    'bp': bpCtrl.text.trim(),
    'rr': double.tryParse(rrCtrl.text),
    'hr': double.tryParse(hrCtrl.text),
    'temperature': double.tryParse(tempCtrl.text),
    'weight': double.tryParse(weightCtrl.text),
    'height': double.tryParse(heightCtrl.text),
    'bmi': bmiDisplay.value,
    'prakriti': prakriti.value,
    'sarataha': sarataha.value,
    'sanhanan': sanhanan.value,
    'pramana': pramana.value,
    'satva': satva.value,
    'satmya': satmya.value,
    'aharaShakti': aharaShakti.value,
    'vyayamaShakti': vyayamaShakti.value,
    'vaya': vaya.value,
    'jihwa': jihwa.value,
    'desha': desha.value,
    'pathologicalRadiological': pathologicalRadiologicalCtrl.text.trim(),
    'photo': selectedDocumentName.value,
    'treatmentGiven': treatmentCtrl.text.trim(),
  };

  @override
  void onClose() {
    pageController.dispose();
    for (final c in [
      nameCtrl,
      ageCtrl,
      phoneCtrl,
      occupationCtrl,
      addressCtrl,
      opdCtrl,
      ipdCtrl,
      diagnosisCtrl,
      chiefComplaintsCtrl,
      presentIllnessCtrl,
      pastIllnessCtrl,
      familyHistoryCtrl,
      otherAddictionCtrl,
      urineFreqCtrl,
      menstrualHistoryCtrl,
      deliveriesCtrl,
      abortionCtrl,
      surgicalCtrl,
      bpCtrl,
      rrCtrl,
      hrCtrl,
      tempCtrl,
      weightCtrl,
      heightCtrl,
      pathologicalRadiologicalCtrl,
      treatmentCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      nameFocus,
      ageFocus,
      phoneFocus,
      occupationFocus,
      addressFocus,
      opdFocus,
      ipdFocus,
      diagnosisFocus,
      chiefComplaintsFocus,
      presentIllnessFocus,
      pastIllnessFocus,
      familyHistoryFocus,
      otherAddictionFocus,
      urineFreqFocus,
      menstrualHistoryFocus,
      deliveriesFocus,
      abortionFocus,
      surgicalFocus,
      bpFocus,
      rrFocus,
      hrFocus,
      tempFocus,
      weightFocus,
      heightFocus,
      pathologicalRadiologicalFocus,
      treatmentFocus,
    ]) {
      f.dispose();
    }
    super.onClose();
  }
}

class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2E7D4F).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: const Color(0xFF2E7D4F)),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2E7D4F),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
