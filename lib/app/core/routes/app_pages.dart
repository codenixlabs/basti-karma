import 'package:get/get.dart';

import '../../../features/assessment/controller/assessment_controller.dart';
import '../../../features/assessment/controller/treatment_plan_controller.dart';
import '../../../features/assessment/screens/assessment_dashboard.dart';
import '../../../features/auth/bindings/auth_binding.dart';
import '../../../features/auth/screens/forgot_password_screen.dart';
import '../../../features/auth/screens/login_screen.dart';
import '../../../features/auth/screens/register_screen.dart';
import '../../../features/home/controller/home_controller.dart';
import '../../../features/patients/controller/add_patient_controller.dart';
import '../../../features/patients/controller/patient_controller.dart';
import '../../../features/patients/screen/add_patient_screen.dart';
import '../../data/repositories/api_patient_repository.dart';
import '../../data/repositories/patient_repository.dart';
import '../../shared/widgets/bottom_navbar.dart';
import '../../../features/profile/controller/profile_controller.dart';
import '../../../features/profile/screen/change_password_screen.dart';
import '../../../features/profile/screen/edit_profile_screen.dart';

import 'auth_guard.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String addPatient = '/add-patient';
  static const String assessment = '/assessment';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
}

class AppPages {
  static const String initialRoute = AppRoutes.login;

  static String getInitialRoute(bool isAuthenticated) =>
      isAuthenticated ? AppRoutes.home : AppRoutes.login;

  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
      binding: AuthBinding(),
      middlewares: [GuestGuard()],
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      transition: Transition.fadeIn,
      binding: AuthBinding(),
      middlewares: [GuestGuard()],
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.fadeIn,
      binding: AuthBinding(),
      middlewares: [GuestGuard()],
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
      middlewares: [AuthGuard()],
      bindings: [
        BindingsBuilder(() {
          Get.lazyPut(() => HomeController());
          if (!Get.isRegistered<PatientRepository>()) {
            Get.put<PatientRepository>(ApiPatientRepository(), permanent: true);
          }
          if (!Get.isRegistered<PatientController>()) {
            Get.put(PatientController(), permanent: true);
          }
          if (!Get.isRegistered<TreatmentPlanController>()) {
            Get.put(TreatmentPlanController(), permanent: true);
          }
          if (!Get.isRegistered<ProfileController>()) {
            Get.lazyPut(() => ProfileController());
          }
        }),
      ],
    ),
    GetPage(
      name: AppRoutes.addPatient,
      page: () => const AddPatientScreen(),
      transition: Transition.rightToLeft,
      middlewares: [AuthGuard()],
      bindings: [
        BindingsBuilder(() => Get.lazyPut(() => AddPatientController())),
      ],
    ),
    GetPage(
      name: AppRoutes.assessment,
      page: () => const AssessmentDashboardScreen(),
      transition: Transition.rightToLeft,
      middlewares: [AuthGuard()],
      bindings: [
        BindingsBuilder(
          () {
            final patientCtrl = Get.isRegistered<PatientController>()
                ? Get.find<PatientController>()
                : null;
            final currentPatient = patientCtrl?.currentPatient.value;

            // Register TreatmentPlanController for the entire assessment session
            if (!Get.isRegistered<TreatmentPlanController>()) {
              Get.lazyPut(() => TreatmentPlanController());
            }
            final tpc = Get.isRegistered<TreatmentPlanController>()
                ? Get.find<TreatmentPlanController>()
                : null;
            final currentPlan = tpc?.currentPlan.value;
            final initialPlan =
                currentPlan?.patientId == currentPatient?.id ? currentPlan : null;

            Get.lazyPut(
              () => AssessmentController(
                patientId: currentPatient?.id,
                patientName: currentPatient?.name ?? '',
                patientAge: currentPatient?.age ?? 0,
                prakriti: currentPatient?.prakriti ?? '',
                sarataha: currentPatient?.sarataha ?? '',
                sanhanan: currentPatient?.sanhanan ?? '',
                pramana: currentPatient?.pramana ?? '',
                satva: currentPatient?.satva ?? '',
                satmya: currentPatient?.satmya ?? '',
                aharaShakti: currentPatient?.aharaShakti ?? '',
                vyayamaShakti: currentPatient?.vyayamaShakti ?? '',
                vaya: currentPatient?.vaya ?? '',
                jihwa: currentPatient?.jihwa ?? '',
                initialPlan: initialPlan,
                initialPoorvaKarmaCompleted:
                    currentPatient?.poorvaKarmaCompleted ?? false,
                initialPradhanaKarmaCompleted:
                    currentPatient?.pradhanaKarmaCompleted ?? false,
                initialPaschataKarmaCompleted:
                    currentPatient?.paschataKarmaCompleted ?? false,
              ),
            );
          },
        ),
      ],
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileScreen(),
      transition: Transition.rightToLeft,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordScreen(),
      transition: Transition.rightToLeft,
      middlewares: [AuthGuard()],
    ),
  ];
}