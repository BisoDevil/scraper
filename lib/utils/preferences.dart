import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static AppPreferences _instance;

static const _kvun =   "vodafone_username";
static const _kvup = "vodafone_password";
static const _kvsid = "vodafone_sid";
static const _keun = "etisalat_username";
static const _keup = "etisalat_password";
static const _kmp = "max_pooling";
static const _kntoe = "num_trials_on_error";
static const _kbc = "batch_capacity";
static const _klmcc = "log_max_char_count";

  SharedPreferences internalPreferences;
  static Future<AppPreferences> getInstance() async {
    if(_instance == null) {
      // initialize for first time
      final internalPreferences = await SharedPreferences.getInstance();
      _instance = AppPreferences._internal(internalPreferences);
    }
    return _instance;
  }

  AppPreferences._internal(this.internalPreferences);

  String get vodafoneUsername => internalPreferences.getString(_kvun) ?? "ASK";
  String get vodafonePassword => internalPreferences.getString(_kvup) ?? "5e625052";
  String get vodafoneSID => internalPreferences.getString(_kvsid) ?? "A94004088";
  String get etisalatUsername => internalPreferences.getString(_keun) ?? "ISP1087";
  String get etisalatPassword => internalPreferences.getString(_keup) ?? "maryam00000";
  int get maxPooling => internalPreferences.getInt(_kmp) ?? 20;
  int get numTrialsOnError => internalPreferences.getInt(_kntoe) ?? 1;
  int get batchCapacity => internalPreferences.getInt(_kbc) ?? 100;
  int get logMaxCharCount => internalPreferences.getInt(_klmcc) ?? 4000;


  Future<bool> setVodafoneUsername(String v) => internalPreferences.setString(_kvun, v);
  Future<bool> setVodafonePassword(String v) => internalPreferences.setString(_kvup, v);
  Future<bool> setVodafoneSID(String v) => internalPreferences.setString(_kvsid, v);
  Future<bool> setEtisalatUsername(String v) => internalPreferences.setString(_keun, v);
  Future<bool> setEtisalatPassword(String v) => internalPreferences.setString(_keup, v);
  Future<bool> setMaxPooling(int v) => internalPreferences.setInt(_kmp, v);
  Future<bool> setNumTrialsOnError(int v) => internalPreferences.setInt(_kntoe, v);
  Future<bool> setBatchCapacity(int v) => internalPreferences.setInt(_kbc, v);
  Future<bool> setLogMaxCharCount(int v) => internalPreferences.setInt(_klmcc, v);
}
