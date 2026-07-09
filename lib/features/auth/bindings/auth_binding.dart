import 'package:get/get.dart';
import '../controller/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: true — controller is recreated fresh each time the route is visited
    // after being closed (e.g. login → register → login again starts clean)
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}