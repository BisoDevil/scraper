import 'package:get/get.dart';
import 'package:scraper/utils/preferences.dart';

class SettingsController extends GetxController {
  String username, password, sid, etisalatUsername, etisalatPassword;
  int maxPooling, batchCapacity, logMaxCharCount, numTrialsOnError;

  Future<void> saveSettings() async {
    AppPreferences prefs = await AppPreferences.getInstance();
    await prefs.setVodafoneUsername(username);
    await prefs.setVodafonePassword(password);
    await prefs.setVodafoneSID(sid);
    await prefs.setEtisalatUsername(etisalatUsername);
    await prefs.setEtisalatPassword(etisalatPassword);
    await prefs.setMaxPooling(maxPooling);
    await prefs.setBatchCapacity(batchCapacity);
    await prefs.setLogMaxCharCount(logMaxCharCount);
    await prefs.setNumTrialsOnError(numTrialsOnError);
    Get.back();
  }

  @override
  void onInit() {
    loadData();
    super.onInit();
  }

  loadData() async {
    AppPreferences prefs = await AppPreferences.getInstance();
    username = prefs.vodafoneUsername;
    password = prefs.vodafonePassword;
    sid = prefs.vodafoneSID;
    etisalatUsername = prefs.etisalatUsername;
    etisalatPassword = prefs.etisalatPassword;
    maxPooling = prefs.maxPooling;
    batchCapacity = prefs.batchCapacity;
    logMaxCharCount = prefs.logMaxCharCount;
    numTrialsOnError = prefs.numTrialsOnError;
    update();
  }
}
