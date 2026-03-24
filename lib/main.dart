import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bastikarma/routes/app_pages.dart';
import 'package:bastikarma/theme/app_theme.dart';
import 'package:bastikarma/controllers/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Bastikarma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.initialRoute,
      getPages: AppPages.pages,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController());
      }),
    );
  }
}
