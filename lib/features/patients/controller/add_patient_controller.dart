import 'package:bastikarma/app/core/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AddPatientController extends GetxController {
  // ── Page controller ──────────────────────────────────────────
  final pageController = PageController();

  // ── Step tracking ────────────────────────────────────────────
  final currentStep = 0.obs;

  bool get isFemale => sex.value == 'Female';

  int get totalSteps => isFemale ? 9 : 8;

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

  final opdFocus = FocusNode();
  final ipdFocus = FocusNode();
  final diagnosisFocus = FocusNode();

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
    if (addictions.contains(opt)) {
      addictions.remove(opt);
      if (opt == 'Others') otherAddictionCtrl.clear();
    } else {
      addictions.add(opt);
    }
  }

  // ── Step 5 — Female History ──────────────────────────────────
  final deliveriesCtrl = TextEditingController();
  final abortionCtrl = TextEditingController();
  final surgicalCtrl = TextEditingController();

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

  // ── Step 8 — Investigations ──────────────────────────────────
  final pathologicalCtrl = TextEditingController();
  final radiologicalCtrl = TextEditingController();

  final pathologicalFocus = FocusNode();
  final radiologicalFocus = FocusNode();

  final uploadedPhotos = <String>[].obs;
  final _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    // BUG FIX: On Android 13+ (API 33+), image_picker uses the system photo
    // picker which does NOT require READ_MEDIA_IMAGES / READ_EXTERNAL_STORAGE
    // permission. Requesting Permission.photos on Android 13+ returns
    // PermissionStatus.denied WITHOUT showing a dialog (the OS handles access
    // implicitly through the picker UI), causing our snackbar to fire
    // immediately. Only request permission for camera.
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        Get.snackbar(
          'Permission Denied',
          'Camera access is required to take photos.',
          snackPosition: SnackPosition.BOTTOM,
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
      if (file != null) uploadedPhotos.add(file.path);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not pick image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void removePhoto(String path) => uploadedPhotos.remove(path);

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
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Add Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                const SizedBox(width: 16),
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

  void submitForm() {
    final validator = _validationCallbacks[currentStep.value];
    if (validator != null && !validator()) return;
    _dismissKeyboard();
    isSubmitting.value = true;
    Get.toNamed(AppRoutes.home);
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
    final titles = <String>[
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
    final i = currentStep.value;
    return i < titles.length ? titles[i] : 'Add New Patient';
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
    'diet': diet.value,
    'addictions': addictions.toList(),
    'otherAddiction': otherAddictionCtrl.text.trim(),
    'bowelHabits': bowelHabits.value,
    'nidra': nidra.value,
    'bloodGroup': bloodGroup.value,
    'urineFrequency': urineFreqCtrl.text.trim(),
    if (isFemale) ...{
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
    'pathological': pathologicalCtrl.text.trim(),
    'radiological': radiologicalCtrl.text.trim(),
    'photos': uploadedPhotos.toList(),
    'treatment': treatmentCtrl.text.trim(),
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
      deliveriesCtrl,
      abortionCtrl,
      surgicalCtrl,
      bpCtrl,
      rrCtrl,
      hrCtrl,
      tempCtrl,
      weightCtrl,
      heightCtrl,
      pathologicalCtrl,
      radiologicalCtrl,
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
      deliveriesFocus,
      abortionFocus,
      surgicalFocus,
      bpFocus,
      rrFocus,
      hrFocus,
      tempFocus,
      weightFocus,
      heightFocus,
      pathologicalFocus,
      radiologicalFocus,
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2E7D4F).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF2E7D4F)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2E7D4F),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
