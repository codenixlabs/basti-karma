import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/routes/app_pages.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/repositories/auth_repository.dart';
import 'app/data/services/api_service.dart';
import 'app/data/services/auth_service.dart';
import 'features/auth/controller/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = await Get.putAsync(() => AuthService().init());
  Get.put(ApiService(authService: authService), permanent: true);
  Get.put(AuthRepository(), permanent: true);
  Get.put(AuthController(), permanent: true);

  runApp(MyApp(isLoggedIn: authService.isAuthenticated));
}

class MyApp extends StatelessWidget {
  final bool? isLoggedIn;

  const MyApp({super.key, this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final authenticated =
        isLoggedIn ??
        (Get.isRegistered<AuthService>() &&
            Get.find<AuthService>().isAuthenticated);

    return GetMaterialApp(
      title: 'Bastikarma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.getInitialRoute(authenticated),
      getPages: AppPages.pages,
    );
  }
}
