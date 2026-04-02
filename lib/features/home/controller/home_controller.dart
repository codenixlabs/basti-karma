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
    DashboardStat(label: 'Active Treatments', value: 8, iconType: 'treatments'),
  ].obs;

  final RxList<Reminder> reminders = <Reminder>[
    Reminder(
      title: 'Pending Assessments',
      subtitle: '..............',
      badge: 'Urgent',
      isUrgent: true,
      iconType: 'pulse',
    ),
  ].obs;

  void changeTab(int index) => currentIndex.value = index;
}
