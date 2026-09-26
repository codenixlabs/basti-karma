import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:bastikarma/app/data/models/patient/patient_model.dart';
import 'package:bastikarma/features/patients/widgets/patient_case_sheet_sheet.dart';
import 'package:bastikarma/features/patients/screen/patient_detail_screen.dart';
import 'package:bastikarma/features/assessment/controller/treatment_plan_controller.dart';
import 'package:bastikarma/features/patients/controller/patient_controller.dart';
import 'package:bastikarma/app/data/repositories/patient_repository.dart';

import 'dart:io';

class _FakePatientRepository implements PatientRepository {
  @override
  Future<List<PatientModel>> getAllPatients() async => [];

  @override
  Future<PatientModel?> getPatient(String id) async => null;

  @override
  Future<String> addPatient(PatientModel patient, {File? photoFile}) async => patient.id;

  @override
  Future<void> updatePatient(PatientModel patient, {File? photoFile}) async {}

  @override
  Future<String?> uploadPatientPhoto(String patientId, File photoFile) async => null;

  @override
  Future<void> deletePatient(String id) async {}

  @override
  Future<File> downloadPatientPdfReport(
    String patientId, {
    String? defaultFileName,
    Duration? timeout,
  }) async =>
      File('fake_report.pdf');
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<PatientController>(PatientController(repository: _FakePatientRepository()));
    Get.put<TreatmentPlanController>(TreatmentPlanController());
  });

  tearDown(() {
    Get.reset();
  });

  final testPatient = PatientModel(
    id: 'pat_test_123',
    name: 'Shreya Sharma',
    age: 32,
    sex: 'Female',
    phoneNo: '9876543210',
    admissionType: 'OPD',
    opdNumber: 'OPD-2026-99',
    diagnosis: 'Sandhigata Vata',
    prakriti: 'Vata-Pitta',
    desha: 'Sadharana',
    sarataha: 'Madhyama',
    sanhanan: 'Madhyama',
    pramana: 'Madhyama',
    satva: 'Pravara',
    satmya: 'Vyayamasatmya',
    aharaShakti: 'Pravara',
    vyayamaShakti: 'Madhyama',
    vaya: 'Madhyama',
    jihwa: 'Niram',
    bp: '120/80',
    hr: '72',
    rr: '18',
    temperature: '98.4',
    weight: 58.5,
    height: 162,
    bmi: 22.3,
    ahara: 'Vegetarian, timely meals',
    nidra: 'Sound sleep 7 hours',
    bowelHabits: 'Regular, normal',
    urineFrequency: '4-5 times/day',
    chiefComplaints: 'Knee joint pain and stiffness since 6 months',
    historyOfPresentIllness: 'Gradual onset of pain in both knee joints, aggravated during winter',
    historyOfPastIllness: 'No past major surgical or chronic illness',
    familyHistory: 'Mother had arthritis',
    menstrualHistory: 'Regular 28-day cycle, 4 days duration',
    numberOfDeliveries: 1,
    abortion: 0,
    surgicalIntervention: 'None',
    pathologicalRadiological: 'X-ray bilateral knees: mild joint space narrowing',
    treatmentGiven: 'Yogaraj Guggulu 2 tab BD with lukewarm water',
    createdAt: DateTime(2026, 1, 15),
  );

  testWidgets('PatientCaseSheetSheet displays all clinical data points', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientCaseSheetSheet(patient: testPatient),
        ),
      ),
    );

    // Verify patient header & demographics
    expect(find.text('Shreya Sharma'), findsOneWidget);
    expect(find.text('32 years'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Sandhigata Vata'), findsOneWidget);

    // Verify Vitals
    expect(find.text('120/80'), findsOneWidget);
    expect(find.text('72 bpm'), findsOneWidget);
    expect(find.text('58.5 kg'), findsOneWidget);

    // Verify Female history
    expect(find.text('Regular 28-day cycle, 4 days duration'), findsOneWidget);

    // Verify Rogi Pariksha
    expect(find.text('Vata-Pitta'), findsWidgets);
    expect(find.text('Sadharana'), findsWidgets);

    // Verify Complaints & Findings
    expect(find.text('Knee joint pain and stiffness since 6 months'), findsOneWidget);
    expect(find.text('X-ray bilateral knees: mild joint space narrowing'), findsOneWidget);
  });

  testWidgets('PatientDetailScreen renders 3 tabs and Hero patient card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatientDetailScreen(patient: testPatient),
      ),
    );

    // Pump to settle async loadData
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify hero header
    expect(find.text('Shreya Sharma'), findsWidgets);
    expect(find.text('Full CRF Sheet'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);

    // Verify 3 tabs
    expect(find.text('Medical Record'), findsOneWidget);
    expect(find.text('Basti Therapy'), findsOneWidget);
    expect(find.text('Reports & Media'), findsOneWidget);

    // Verify Medical Record tab content is active
    expect(find.text('VITALS & PHYSICAL EXAMINATION'), findsOneWidget);
    expect(find.text('AYURVEDIC ROGI PARIKSHA (11 METRICS)'), findsOneWidget);
  });
}
