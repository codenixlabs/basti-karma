import 'package:get/get.dart';
import 'package:bastikarma/screens/login_screen.dart';
import 'package:bastikarma/screens/register_screen.dart';
import 'package:bastikarma/screens/home_screen.dart';
import 'package:bastikarma/controllers/auth_controller.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
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
    ),
  ];

  static final initialRoute = AppRoutes.login;
}
