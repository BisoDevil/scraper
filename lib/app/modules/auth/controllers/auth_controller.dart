import 'package:get/get.dart';
import 'package:scraper/app/modules/auth/controllers/auth_service.dart';
import 'package:scraper/app/routes/app_pages.dart';
import 'package:scraper/utils/preferences.dart';

class AuthController extends GetxController {
  String username, password;

  Future<void> login() async { 
    final user = AuthService.getInstance().getUser(username, password);
    if(user == null) {
      // TODO: show error message for the uesr
      return;
    }
    AuthService.getInstance().setCurrentUser(user);
    Get.offNamed(Routes.HOME);
  }

  @override
  void onInit() async {
    await loadData();
    checkLogin();
    super.onInit();
  }

  void checkLogin() {
    if(username != null && password != null) {
      login();
    }
  }

  Future<void> loadData() async {
    AppPreferences prefs = await AppPreferences.getInstance();
    username = prefs.appUsername;
    password = prefs.appPassword;
    print("in load data $username, $password");
  }
}
