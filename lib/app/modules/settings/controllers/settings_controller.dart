import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  String username, password, sid, etisalatUsername, etisalatPassword;

  Future<void> saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("vodafone_username", username);
    await prefs.setString("vodafone_password", password);
    await prefs.setString("vodafone_sid", sid);
    await prefs.setString("etisalat_username", etisalatUsername);
    await prefs.setString("etisalat_password", etisalatPassword);
    Get.back();
  }

  @override
  void onInit() {
    loadData();
    super.onInit();
  }

  loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    username = prefs.getString("vodafone_username");
    password = prefs.getString("vodafone_password");
    sid = prefs.getString("vodafone_sid");
    etisalatUsername = prefs.getString("etisalat_username");
    etisalatPassword = prefs.getString("etisalat_password");
    update();
  }
}
