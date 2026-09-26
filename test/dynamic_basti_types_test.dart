import 'package:flutter_test/flutter_test.dart';
import 'package:bastikarma/app/data/models/master/basti_option_model.dart';
import 'package:bastikarma/app/data/models/master/basti_pattern_model.dart';
import 'package:bastikarma/app/data/models/master/dose_rule_model.dart';
import 'package:bastikarma/app/data/models/patient/basti_schedule_day_model.dart';
import 'package:bastikarma/app/data/models/patient/basti_session_model.dart';
import 'package:bastikarma/app/data/services/basti_schedule_generator_service.dart';

void main() {
  group('Dynamic Basti Types (MB & YB) Model Tests', () {
    test('BastiScheduleDayModel handles MB and YB correctly', () {
      final mbDay = BastiScheduleDayModel(
        dayNumber: 1,
        scheduledBastiType: 'Matra Basti',
        bastiTypeCodeShort: 'MB',
        scheduledDose: 60.0,
        doseUnit: 'ml',
        compositionSummary: 'Matra Sneha Basti - 60 ml',
      );

      expect(mbDay.isMatra, isTrue);
      expect(mbDay.isSnehaBased, isTrue);
      expect(mbDay.isNiruha, isFalse);
      expect(mbDay.isYapana, isFalse);
      expect(mbDay.isKwathaBased, isFalse);

      final ybDay = BastiScheduleDayModel(
        dayNumber: 1,
        scheduledBastiType: 'Yapana Basti',
        bastiTypeCodeShort: 'YB',
        scheduledDose: 400.0,
        doseUnit: 'ml',
        compositionSummary: 'Yapana Basti - 400 ml',
      );

      expect(ybDay.isYapana, isTrue);
      expect(ybDay.isKwathaBased, isTrue);
      expect(ybDay.isMatra, isFalse);
      expect(ybDay.isAnuvasana, isFalse);
      expect(ybDay.isSnehaBased, isFalse);
    });

    test('BastiSessionModel handles MB and YB with appropriate symptom categorization', () {
      final mbSession = BastiSessionModel(
        id: 's_1',
        treatmentPlanId: 'p_1',
        dayNumber: 1,
        scheduledBastiType: 'Matra Basti',
        bastiTypeCodeShort: 'MB',
        scheduledDose: 50.0,
        doseUnit: 'ml',
        samyakaSelected: [true, false, false, false, false, false],
        ayogaSelected: List.filled(8, false),
        atiyogaSelected: List.filled(6, false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(mbSession.isMatra, isTrue);
      expect(mbSession.isSnehaBased, isTrue);
      expect(mbSession.isKwathaBased, isFalse);
      // MB should pick Anuvasana/Sneha observation keys
      expect(mbSession.selectedObservationIds, contains('sapurishaSnehaPratyeti'));

      final ybSession = BastiSessionModel(
        id: 's_2',
        treatmentPlanId: 'p_1',
        dayNumber: 2,
        scheduledBastiType: 'Yapana Basti',
        bastiTypeCodeShort: 'YB',
        scheduledDose: 400.0,
        doseUnit: 'ml',
        samyakaSelected: [true, false, false, false, false, false, false],
        ayogaSelected: List.filled(8, false),
        atiyogaSelected: List.filled(10, false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(ybSession.isYapana, isTrue);
      expect(ybSession.isKwathaBased, isTrue);
      // YB should pick Niruha/Kwatha observation keys
      expect(ybSession.selectedObservationIds, contains('prasristaVinaMutra'));
    });
  });

  group('Dynamic Pattern Generation (MB & YB)', () {
    test('Generates 8-day Matra schedule with bastiType = MB', () {
      final matraPattern = BastiPatternModel(
        code: 'matra_avara',
        name: 'Matra Basti (Avara)',
        totalDays: 8,
        recommendedBala: 'Avara',
        sequence: ['MB', 'MB', 'MB', 'MB', 'MB', 'MB', 'MB', 'MB'],
        clinicalIndications: 'For Vata Vyadhi in delicate patients',
      );

      final dummyOption = BastiOptionModel(
        id: 'opt_1',
        diseaseId: 'dis_vatavyadhi',
        name: 'Maha Narayana Taila',
        bastiTypeCode: 'Sneha Basti (Anuvasana / Matra)',
        bastiTypeDisplay: 'Sneha Basti',
        indicationStage: 'Vata Vyadhi',
        ingredients: const [],
        formulationDetails: 'Standard formulation',
        classicalReference: 'Charaka',
      );

      final generator = BastiScheduleGeneratorService();
      final schedule = generator.generateSchedule(
        pattern: matraPattern,
        niruhaDose: 400,
        anuvasanaDose: 100,
        matraDose: 60,
        selectedBasti: dummyOption,
      );

      expect(schedule.length, equals(8));
      for (int i = 0; i < 8; i++) {
        expect(schedule[i].bastiTypeCodeShort, equals('MB'));
        expect(schedule[i].scheduledBastiType, equals('Matra Basti'));
        expect(schedule[i].scheduledDose, equals(60.0));
        expect(schedule[i].doseUnit, equals('ml'));
        expect(schedule[i].isMatra, isTrue);
      }
    });

    test('Generates Yapana schedule with bastiType = YB', () {
      final yapanaPattern = BastiPatternModel(
        code: 'yapana_7',
        name: 'Yapana Basti (7 Days)',
        totalDays: 7,
        recommendedBala: 'Madhyama',
        sequence: ['YB', 'YB', 'YB', 'YB', 'YB', 'YB', 'YB'],
        clinicalIndications: 'For Rasayana & Brimhana',
      );

      final dummyOption = BastiOptionModel(
        id: 'opt_2',
        diseaseId: 'dis_raja',
        name: 'Mustadi Yapana Basti',
        bastiTypeCode: 'Yapana Basti',
        bastiTypeDisplay: 'Yapana Basti',
        indicationStage: 'Brimhana',
        ingredients: const [],
        formulationDetails: 'Milk and decoction recipe',
        classicalReference: 'Charaka',
      );

      final generator = BastiScheduleGeneratorService();
      final schedule = generator.generateSchedule(
        pattern: yapanaPattern,
        niruhaDose: 400,
        anuvasanaDose: 100,
        yapanaDose: 350,
        selectedBasti: dummyOption,
      );

      expect(schedule.length, equals(7));
      for (final day in schedule) {
        expect(day.bastiTypeCodeShort, equals('YB'));
        expect(day.scheduledBastiType, equals('Yapana Basti'));
        expect(day.scheduledDose, equals(350.0));
        expect(day.isKwathaBased, isTrue);
      }
    });
  });

  group('Pattern Filtering by Formulation bastiType', () {
    final patterns = [
      BastiPatternModel(
        code: 'yoga',
        name: 'Yoga Basti',
        totalDays: 8,
        recommendedBala: 'Avara',
        sequence: ['A', 'N', 'A', 'N', 'A', 'N', 'A', 'A'],
        clinicalIndications: '',
      ),
      BastiPatternModel(
        code: 'kala',
        name: 'Kala Basti',
        totalDays: 16,
        recommendedBala: 'Madhyama',
        sequence: ['A', 'N', 'A', 'N', 'A', 'N', 'A', 'N', 'A', 'N', 'A', 'N', 'A', 'A', 'A', 'A'],
        clinicalIndications: '',
      ),
      BastiPatternModel(
        code: 'matra_avara',
        name: 'Matra Basti (8 Days)',
        totalDays: 8,
        recommendedBala: 'Avara',
        sequence: ['MB', 'MB', 'MB', 'MB', 'MB', 'MB', 'MB', 'MB'],
        clinicalIndications: '',
      ),
      BastiPatternModel(
        code: 'yapana_kala',
        name: 'Yapana Basti Pattern',
        totalDays: 10,
        recommendedBala: 'Madhyama',
        sequence: ['YB', 'YB', 'YB', 'YB', 'YB', 'YB', 'YB', 'YB', 'YB', 'YB'],
        clinicalIndications: '',
      ),
    ];

    test('Filters to Matra patterns when bastiType is "Sneha Basti (Anuvasana / Matra)"', () {
      final matraMatches = patterns.where((p) => p.matchesBastiType('Sneha Basti (Anuvasana / Matra)')).toList();
      expect(matraMatches.any((p) => p.code == 'matra_avara'), isTrue);
      expect(matraMatches.any((p) => p.code == 'yapana_kala'), isFalse);
    });

    test('Filters to Yapana patterns when bastiType is "Yapana Basti"', () {
      final yapanaMatches = patterns.where((p) => p.matchesBastiType('Yapana Basti')).toList();
      expect(yapanaMatches.any((p) => p.code == 'yapana_kala'), isTrue);
      expect(yapanaMatches.any((p) => p.code == 'matra_avara'), isFalse);
    });

    test('Filters to Yoga / Kala patterns when bastiType is "Niruha Basti + Anuvasana Basti"', () {
      final combinedMatches = patterns.where((p) => p.matchesBastiType('Niruha Basti + Anuvasana Basti')).toList();
      expect(combinedMatches.any((p) => p.code == 'yoga'), isTrue);
      expect(combinedMatches.any((p) => p.code == 'kala'), isTrue);
      expect(combinedMatches.any((p) => p.code == 'matra_avara'), isFalse);
    });
  });

  group('Dose Rules with updated ml units', () {
    test('Parses Sneha components with ml units', () {
      final json = {
        'bastiType': 'Anuvasana',
        'bala': 'Madhyama',
        'totalVolume': 80,
        'unit': 'ml',
        'components': [
          {'name': 'Sneha (Oil / Ghritha)', 'amount': 80, 'unit': 'ml'}
        ],
        'sourceReference': 'Charaka Samhita',
      };

      final rule = DoseRuleModel.fromJson(json);
      expect(rule.unit, equals('ml'));
      expect(rule.components.first.unit, equals('ml'));
      expect(rule.totalVolume, equals(80.0));
    });
  });
}
