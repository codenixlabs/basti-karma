import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Per-session observation data
class BastiSessionData {
  final int sessionNumber;
  final adanaKala = TextEditingController();
  final pratyagamana = TextEditingController();
  final vega = TextEditingController();
  late final RxList<bool> samyaka;
  late final RxList<bool> ayoga;
  late final RxList<bool> atiyoga;

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
  // ── Patient context (passed from patient list) ───────────────────────────
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

  AssessmentController({
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
  });

  // ── Phase completion tracking ────────────────────────────────────────────
  final purvakarmaComplete = false.obs;
  final pradhankarmaComplete = false.obs;

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

  bool get isNiruhaEligible => niruhaAnswers.every((a) => a == false);

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

  bool get isAnuvasanEligible => anuvasanAnswers.every((a) => a == false);

  bool get anuvasanAllAnswered => anuvasanAnswers.every((a) => a != null);

  // ── B. Pariksha — dropdowns (auto-filled from CRF) ───────────────────────
  late final parikshaPrakriti = Rxn<String>()
    ..value = prakriti.isNotEmpty ? prakriti : null;
  late final parikshaSarataha = Rxn<String>()
    ..value = sarataha.isNotEmpty ? sarataha : null;
  late final parikshaSanhanan = Rxn<String>()
    ..value = sanhanan.isNotEmpty ? sanhanan : null;
  late final parikshaPramana = Rxn<String>()
    ..value = pramana.isNotEmpty ? pramana : null;
  late final parikshaSatva = Rxn<String>()
    ..value = satva.isNotEmpty ? satva : null;
  late final parikshaSatmya = Rxn<String>()
    ..value = satmya.isNotEmpty ? satmya : null;
  late final parikshAhara = Rxn<String>()
    ..value = aharaShakti.isNotEmpty ? aharaShakti : null;
  late final parikshVyayama = Rxn<String>()
    ..value = vyayamaShakti.isNotEmpty ? vyayamaShakti : null;
  late final parikshVaya = Rxn<String>()..value = _inferVaya(patientAge);
  late final parikshJihwa = Rxn<String>()
    ..value = jihwa.isNotEmpty ? jihwa : null;

  static String? _inferVaya(int age) {
    if (age <= 0) return null;
    if (age <= 16) return 'Bala (Child 0–16)';
    if (age <= 60) return 'Madhyama (Adult 16–60)';
    return 'Vriddha (Old 60+)';
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

  // ── C. Agni — hidden scoring ─────────────────────────────────────────────
  // Doctor sees only options; scores 0–5 computed invisibly.
  final _jaranShaktiScore = 0.obs; // 0–5
  final _abhyavaharanaScore = 0.obs; // 0–5
  final _ruchiScore = 0.obs; // 0–5

  // Jaran Shakti: how many of 5 symptoms present (0–5)
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
    _jaranShaktiScore.value = jaranShaktiSelected.length;
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
    _abhyavaharanaScore.value = index;
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
    _ruchiScore.value = index;
  }

  int get _agniTotal =>
      _jaranShaktiScore.value + _abhyavaharanaScore.value + _ruchiScore.value;

  /// What the UI shows — no number, just Ayurvedic category
  String get agniResult {
    final t = _agniTotal;
    if (t <= 5) return 'Avara Agni (Mandagni)';
    if (t <= 10) return 'Madhyam Agni';
    return 'Pravar Agni';
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

  int get _koshthaTotal => koshthaAnswers.fold(0, (s, v) => s + (v ?? 0));

  String get koshthaResult {
    final t = _koshthaTotal;
    if (t <= 5) return 'Krura Koshtha';
    if (t <= 10) return 'Madhyam Koshtha';
    return 'Mridu Koshtha';
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

  bool get hasSaamaLakshana => saamaAnswers.any((a) => a == true);

  bool get saamaAllAnswered => saamaAnswers.every((a) => a != null);

  String get saamaResult =>
      hasSaamaLakshana ? 'Saama Avastha' : 'Nirama Avastha';

  // ── F. Bala Assessment ───────────────────────────────────────────────────
  final bala = Rxn<String>();
  static const List<String> balaOptions = ['Pravara', 'Madhyama', 'Avara'];

  // ── Purvakarma overall completion ────────────────────────────────────────
  bool get canCompletePurvakarma =>
      niruhaAllAnswered &&
      anuvasanAllAnswered &&
      parikshAllFilled &&
      agniAllAnswered &&
      koshthaAllAnswered &&
      saamaAllAnswered &&
      bala.value != null;

  void completePurvakarma() {
    if (!canCompletePurvakarma) return;
    purvakarmaComplete.value = true;
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
      case 'Niruha Basti': return 12;
      case 'Anuvasan Basti': return 18;
      case 'Yoga Basti': return 8;
      case 'Kala Basti': return 16;
      case 'Karma Basti': return 30;
      default: return 12;
    }
  }

  // ── Observation — session list ───────────────────────────────────────────
  final sessions = <BastiSessionData>[].obs;
  final observationTick = 0.obs; // incremented on any symptom toggle

  void _initSessions() {
    for (final s in sessions) s.dispose();
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
    if (type == 'samyaka') session.samyaka[i] = !session.samyaka[i];
    else if (type == 'ayoga') session.ayoga[i] = !session.ayoga[i];
    else if (type == 'atiyoga') session.atiyoga[i] = !session.atiyoga[i];
    observationTick.value++;
  }

  int get loggedSessionCount => sessions.where(
    (s) =>
        s.samyaka.any((v) => v) ||
        s.ayoga.any((v) => v) ||
        s.atiyoga.any((v) => v) ||
        s.adanaKala.text.isNotEmpty,
  ).length;

  @override
  void onInit() {
    super.onInit();
    ever(selectedBastiType, (_) => _initSessions());
  }

  bool get pradhanAllFilled =>
      selectedBastiType.value != null &&
      dravyaDoseCtrl.text.trim().isNotEmpty &&
      scheduleCtrl.text.trim().isNotEmpty;

  void completePradhanKarma() {
    if (!pradhanAllFilled) return;
    pradhankarmaComplete.value = true;
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
    for (final s in sessions) s.dispose();
    super.onClose();
  }
}
