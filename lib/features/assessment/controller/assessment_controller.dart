import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  final niruhaAnswers = List<bool?>.filled(16, null).obs;

  static const List<String> niruhaQuestions = [
    'Is the patient pregnant?',
    'Is the patient having an ulcer in the lung?',
    'Is the patient emaciated or dehydrated due to Shodhana?',
    'Is the patient excessively weak, debilitated or unconscious?',
    'Is the patient currently undergoing or just after Vamana, Virechana or Nasya?',
    'Does the patient have history of recent or excessive internal Snehana?',
    'Does the patient have continuous vomiting?',
    'Does the patient have abdominal distension (Adhmana)?',
    'Does the patient have Ama-Atisara (diarrhoea due to indigestion)?',
    'Does the patient have Alasaka (intestinal torpor)?',
    'Does the patient have Visuchika (gastroenteritis)?',
    'Does the patient have intestinal obstruction?',
    'Does the patient have perforation of intestine?',
    'Does the patient have ascites?',
    'Does the patient have history of miscarriage?',
    'Does the patient have uncontrolled diabetes, hypertension, or chronic kidney disease?',
  ];

  void setNiruhaAnswer(int index, bool value) {
    niruhaAnswers[index] = value;
    niruhaAnswers.refresh();
  }

  bool get isNiruhaEligible => niruhaAnswers.every((a) => a == false);

  bool get niruhaAllAnswered => niruhaAnswers.every((a) => a != null);

  // ── A. Yogya/Ayogya — Anuvasan contraindications ─────────────────────────
  final anuvasanAnswers = List<bool?>.filled(23, null).obs;

  static const List<String> anuvasanQuestions = [
    'Does the patient have Niruha Basti contraindication conditions?',
    'Does the patient have impaired digestion (Agnimandya)?',
    'Does the patient have diarrhoea (Atisara)?',
    'Does the patient have hard bowel or constipation with obstruction?',
    'Does the patient have intestinal worms (Krimi)?',
    'Does the patient have splenic disorders or splenomegaly (Pleeha Roga)?',
    'Does the patient have Kapha-dominant Udara Roga (abdominal disorders)?',
    'Does the patient have Abhishyandi conditions of Pitta and Kapha?',
    'Does the patient have anorexia (Aruchi)?',
    'Does the patient have acute poisoning?',
    'Does the patient have coryza or rhinitis (Pratishyaya)?',
    'Does the patient have recent fever (Nava Jvara)?',
    'Does the patient have anaemia (Pandu)?',
    'Does the patient have jaundice (Kamala)?',
    'Does the patient have polyuria (excessive urination)?',
    'Does the patient have piles (Arsha)?',
    'Does the patient have Urustambha?',
    'Does the patient have elephantiasis (Shleepada)?',
    'Does the patient have goitre (Galaganda)?',
    'Does the patient have lymphadenitis (Granthi / Apachi)?',
    'Does the patient have general debility or weakness?',
    'Does the patient have Kushta (chronic skin diseases)?',
    'Does the patient have obesity (Sthaulya)?',
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

  // ── Purvakarma overall completion ────────────────────────────────────────
  bool get canCompletePurvakarma =>
      niruhaAllAnswered &&
      anuvasanAllAnswered &&
      parikshAllFilled &&
      agniAllAnswered &&
      koshthaAllAnswered &&
      saamaAllAnswered;

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

  // Observation log
  final adanaKalaCtrl = TextEditingController();
  final pratyagamanaCtrl = TextEditingController();
  final vegaCtrl = TextEditingController();
  final samyakLakshanaCtrl = TextEditingController();
  final atiyogaLakshanaCtrl = TextEditingController();
  final ayogaLakshanaCtrl = TextEditingController();

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
    'Abhukta Pranita': 'Consult senior physician for management.',
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
    adanaKalaCtrl.dispose();
    pratyagamanaCtrl.dispose();
    vegaCtrl.dispose();
    samyakLakshanaCtrl.dispose();
    atiyogaLakshanaCtrl.dispose();
    ayogaLakshanaCtrl.dispose();
    super.onClose();
  }
}
