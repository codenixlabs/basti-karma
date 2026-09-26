import '../models/master/basti_option_model.dart';
import '../models/master/basti_pattern_model.dart';
import '../models/patient/basti_schedule_day_model.dart';

class BastiScheduleGeneratorService {
  List<BastiScheduleDayModel> generateSchedule({
    required BastiPatternModel pattern,
    required double niruhaDose,
    required double anuvasanaDose,
    double? matraDose,
    double? yapanaDose,
    required BastiOptionModel selectedBasti,
    String niruhaCompositionSummary = '',
    String anuvasanaCompositionSummary = '',
    String matraCompositionSummary = '',
    String yapanaCompositionSummary = '',
  }) {
    final List<BastiScheduleDayModel> scheduleDays = [];

    for (int i = 0; i < pattern.sequence.length; i++) {
      final code = pattern.sequence[i].trim().toUpperCase();
      final dayNumber = i + 1;

      final String scheduledType;
      final double scheduledDose;
      final String composition;

      if (code == 'MB') {
        scheduledType = 'Matra Basti';
        scheduledDose = matraDose ?? (anuvasanaDose > 60 ? anuvasanaDose / 2 : anuvasanaDose);
        composition = matraCompositionSummary.isNotEmpty
            ? matraCompositionSummary
            : '${selectedBasti.name} (Matra Sneha Basti - ${scheduledDose.toInt()} ml)';
      } else if (code == 'YB') {
        scheduledType = 'Yapana Basti';
        scheduledDose = yapanaDose ?? niruhaDose;
        composition = yapanaCompositionSummary.isNotEmpty
            ? yapanaCompositionSummary
            : '${selectedBasti.name} (Yapana Basti - ${scheduledDose.toInt()} ml)';
      } else if (code == 'A') {
        scheduledType = 'Anuvasana';
        scheduledDose = anuvasanaDose;
        composition = anuvasanaCompositionSummary.isNotEmpty
            ? anuvasanaCompositionSummary
            : '${selectedBasti.name} (Anuvasana Sneha Basti - ${anuvasanaDose.toInt()} ml)';
      } else {
        // Default to Niruha ('N')
        scheduledType = 'Niruha';
        scheduledDose = niruhaDose;
        composition = niruhaCompositionSummary.isNotEmpty
            ? niruhaCompositionSummary
            : '${selectedBasti.name} (Niruha Kwatha Basti - ${niruhaDose.toInt()} ml)';
      }

      scheduleDays.add(
        BastiScheduleDayModel(
          dayNumber: dayNumber,
          scheduledBastiType: scheduledType,
          bastiTypeCodeShort: code,
          scheduledDose: scheduledDose,
          doseUnit: 'ml',
          compositionSummary: composition,
          isCompleted: false,
        ),
      );
    }

    return scheduleDays;
  }
}
