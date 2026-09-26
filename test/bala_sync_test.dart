import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:bastikarma/app/data/repositories/api_poorva_karma_repository.dart';
import 'package:bastikarma/features/assessment/controller/assessment_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bala Normalization & AssessmentController Tests', () {
    test('ApiPoorvaKarmaRepository.normalizeBala normalizes variants accurately', () {
      expect(ApiPoorvaKarmaRepository.normalizeBala('Madhyam'), 'Madhyama');
      expect(ApiPoorvaKarmaRepository.normalizeBala('madhyama'), 'Madhyama');
      expect(ApiPoorvaKarmaRepository.normalizeBala('Pravara (Superior)'), 'Pravara');
      expect(ApiPoorvaKarmaRepository.normalizeBala('pravar'), 'Pravara');
      expect(ApiPoorvaKarmaRepository.normalizeBala('Avara (Mild)'), 'Avara');
      expect(ApiPoorvaKarmaRepository.normalizeBala('avar'), 'Avara');
      expect(ApiPoorvaKarmaRepository.normalizeBala(''), 'Madhyama');
    });

    test('AssessmentController initializes with baseline Bala derived from Rogi Pariksha', () {
      final ctrlPravara = AssessmentController(
        patientId: 'p_123',
        patientName: 'Test Patient',
        patientAge: 35,
        prakriti: 'Vata',
        sarataha: 'Pravara',
        sanhanan: 'Pravara',
        pramana: 'Madhyama',
        satva: 'Pravara',
        satmya: 'Pravara',
        aharaShakti: 'Pravara',
        vyayamaShakti: 'Pravara',
        vaya: 'Madhyam',
        jihwa: 'Nirlipta',
      );

      expect(ctrlPravara.bala.value, 'Pravara');

      final ctrlAvara = AssessmentController(
        patientId: 'p_456',
        patientName: 'Test Patient 2',
        patientAge: 65,
        prakriti: 'Pitta',
        sarataha: 'Avara',
        sanhanan: 'Avara',
        pramana: 'Avara',
        satva: 'Avara',
        satmya: 'Avara',
        aharaShakti: 'Avara',
        vyayamaShakti: 'Avara',
        vaya: 'Vriddha',
        jihwa: 'Lipta',
      );

      expect(ctrlAvara.bala.value, 'Avara');

      final ctrlMadhyama = AssessmentController(
        patientId: 'p_789',
        patientName: 'Test Patient 3',
        patientAge: 40,
        prakriti: 'Kapha',
        sarataha: 'Madhyama',
        sanhanan: 'Madhyama',
        pramana: 'Madhyama',
        satva: 'Madhyama',
        satmya: 'Madhyama',
        aharaShakti: 'Madhyama',
        vyayamaShakti: 'Madhyama',
        vaya: 'Madhyam',
        jihwa: 'Nirlipta',
      );

      expect(ctrlMadhyama.bala.value, 'Madhyama');
    });

    test('AssessmentController exposes 3 standard Bala options', () {
      expect(AssessmentController.balaOptions, containsAll(['Pravara', 'Madhyama', 'Avara']));
    });
  });
}
