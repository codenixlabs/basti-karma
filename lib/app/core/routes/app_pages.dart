import 'package:get/get.dart';
import 'package:bastikarma/features/auth/screens/login_screen.dart';
import 'package:bastikarma/features/auth/screens/register_screen.dart';
import 'package:bastikarma/features/auth/controller/auth_controller.dart';
import 'package:bastikarma/features/home/controller/home_controller.dart';

import '../../../features/patients/screen/add_patient_screen.dart';
import '../../shared/widgets/bottom_navbar.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String addPatient = '/add-patient';
}

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
      bindings: [BindingsBuilder(() => Get.lazyPut(() => AuthController()))],
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
      bindings: [BindingsBuilder(() => Get.lazyPut(() => HomeController()))],
    ),
    GetPage(
      name: AppRoutes.addPatient,
      page: () => const AddPatientScreen(),
    ),
  ];

  static const String initialRoute = AppRoutes.home;
}
