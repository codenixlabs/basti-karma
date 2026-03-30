import 'package:get/get.dart';

class DashboardStat {
  final String label;
  final int value;
  final String iconType;

  DashboardStat({
    required this.label,
    required this.value,
    required this.iconType,
  });
}

class Reminder {
  final String title;
  final String subtitle;
  final String badge;
  final bool isUrgent;
  final String iconType;

  Reminder({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.isUrgent,
    required this.iconType,
  });
}

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxString doctorName = 'Doctor'.obs;

  final RxList<DashboardStat> stats = <DashboardStat>[
    DashboardStat(label: 'Total Patients', value: 24, iconType: 'patients'),
    DashboardStat(
      label: 'Active\nTreatments',
      value: 8,
      iconType: 'treatments',
    ),
    DashboardStat(label: "Today's Doses", value: 3, iconType: 'doses'),
  ].obs;

  final RxList<Reminder> reminders = <Reminder>[
    Reminder(
      title: 'Next Snehapana Dose',
      subtitle: 'Patient: Rajesh Kumar - Due in 2 hours',
      badge: 'Today',
      isUrgent: false,
      iconType: 'bell',
    ),
    Reminder(
      title: 'Pending Assessments',
      subtitle: '3 patients require Snigdha assessment',
      badge: 'Urgent',
      isUrgent: true,
      iconType: 'pulse',
    ),
  ].obs;

  void changeTab(int index) => currentIndex.value = index;
}
