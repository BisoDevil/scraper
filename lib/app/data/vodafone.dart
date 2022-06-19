import 'package:flutter/cupertino.dart';
import 'package:requests/requests.dart' as requests;
import 'package:scraper/app/data/common.dart';
import 'package:scraper/io/logger.dart';

class VodafoneStatus extends GStatus {
  VodafoneStatus(String s) : super(s);
  VodafoneStatus.of(GStatus s): this(s.value);
}

class VodafoneResponse extends GScrapperResponse<VodafoneStatus> {
  VodafoneResponse({
    @required VodafoneStatus status,
    @required String id,
    @required String countryCode,
    @required String landline,
    String errorMessage,
    String comment,
    Map<String, dynamic> extras,
  }) : super(
          countryCode: countryCode,
          id: id,
          landline: landline,
          status: status,
          comment: comment,
          errorMessage: errorMessage,
          extras: extras,
        );

  @override
  String get name => "Vodafone";
}

/// Ardy scrapping
class VodafoneScrapper extends GScrapper<VodafoneResponse> {
  static final VodafoneScrapper _instance = VodafoneScrapper._internal();

  static const defaultTimeOutSeconds = 30;
  factory VodafoneScrapper() {
    return _instance;
  }
  VodafoneScrapper._internal();

  String vodafoneToken = "";
  int id = 1;
  String username;
  String password;
  String sfid;
  Future<void> init(String username, String password, String sfid) async {
    this.username = username;
    this.password = password;
    this.sfid = sfid;

    await _updateToken();
  }

  @override
  Future<VodafoneResponse> scrape(
    String landlineID,
    String code,
    String phone,
  ) {
    String currentId = landlineID ?? (id++).toString();
    return _scrape(currentId, code, phone);
  }

  Future<VodafoneResponse> _scrape(
    String currentId,
    String code,
    String phone,
  ) async {
    try {
      if (vodafoneToken.isEmpty) {
        throw ("Can't authenticate user. not valid token");
      }
      final currentToken = await _getToken(currentId);
      var res = await _request(code, phone, token: currentToken);
      if (res.statusCode == 401 || res.statusCode == 403) {
        RunLogger().newLine(">$currentId vodafone - token expired or not valid, scrape again");
        // await _updateToken();
        return _scrape(currentId, code, phone);
      }
      final errObj = (res.json() ?? {})['error'];
      if (errObj == null) {
        throw ("errObj not exist in result or result is empty. ${res.statusCode} ${res.content()}");
      }
      String msg = errObj['errorMessage'];
      if (msg == null || msg.isEmpty) {
        return VodafoneResponse(
          status: VodafoneStatus.of(GStatus.notReserved()),
          id: currentId,
          countryCode: code,
          landline: phone,
        );
      } else {
        print(msg);
        final isErrorMesg = msg.contains("لم تنجح العملية");
        return VodafoneResponse(
          // status: isErrorMesg ? GStatus.error() : GStatus.reserved(),
          status: VodafoneStatus.of(GStatus.reserved()),
          id: currentId,
          countryCode: code,
          landline: phone,
          comment: isErrorMesg ? "" : msg,
          errorMessage: isErrorMesg ? msg : "",
        );
      }
    } catch (e) {
      print("Catch vodafone error: " + e.toString());
      return VodafoneResponse(
        status: VodafoneStatus.of(GStatus.error()),
        id: currentId,
        countryCode: code,
        landline: phone,
        errorMessage: "Error: " + e.toString(),
      );
    }
  }

  Future<requests.Response> _request(String code, String phone,
      {String token}) async {
    final t = token ?? vodafoneToken;
    return requests.Requests.post(
        "https://extranet.vodafone.com.eg/dealerAdsl/DealerAdsl/sendCustomerDetails",
        headers: {
          "Authorization": "Bearer $t",
          "Accept": "application/json, text/plain, */*",
          "channel": '1'
        },
        timeoutSeconds: defaultTimeOutSeconds,
        json: {
          "loggedUser": {
            "sfid": "A94004088",
            "username": "ASK",
          },
          "username": "TKA",
          "password": "TKA",
          "areaCodes": [
            {"areaCode": "092", "landlineLength": "7"},
            {"areaCode": "069", "landlineLength": "7"},
            {"areaCode": "065", "landlineLength": "7"},
            {"areaCode": "02", "landlineLength": "8"},
            {"areaCode": "03", "landlineLength": "7"},
            {"areaCode": "082", "landlineLength": "7"},
            {"areaCode": "048", "landlineLength": "7"},
            {"areaCode": "045", "landlineLength": "7"},
            {"areaCode": "068", "landlineLength": "7"},
            {"areaCode": "055", "landlineLength": "7"},
            {"areaCode": "015", "landlineLength": "6"},
            {"areaCode": "046", "landlineLength": "7"},
            {"areaCode": "040", "landlineLength": "7"},
            {"areaCode": "050", "landlineLength": "7"},
            {"areaCode": "084", "landlineLength": "7"},
            {"areaCode": "013", "landlineLength": "7"},
            {"areaCode": "047", "landlineLength": "7"},
            {"areaCode": "057", "landlineLength": "7"},
            {"areaCode": "086", "landlineLength": "7"},
            {"areaCode": "088", "landlineLength": "7"},
            {"areaCode": "093", "landlineLength": "7"},
            {"areaCode": "096", "landlineLength": "7"},
            {"areaCode": "095", "landlineLength": "7"},
            {"areaCode": "097", "landlineLength": "7"},
            {"areaCode": "066", "landlineLength": "7"},
            {"areaCode": "064", "landlineLength": "7"},
            {"areaCode": "062", "landlineLength": "7"}
          ],
          "selectedArea": code,
          "clientFullName": "سيبنىنتىبيس",
          "landLineOwnerName": "سيبنىنتىبيس",
          "msisdn": "08981342",
          "selectedMobilePrefix": "010",
          "additionalContactNumber": "11111111111",
          "nationalId": "00000000000000",
          "address": "asdasd",
          "dealerName": "أسك",
          "dealerMobileNumber": "78981520",
          "selectedDealerMobilePrefix": "010",
          "captcha":
              "iVBORw0KGgoAAAANSUhEUgAAAEsAAAAjCAIAAABTi2CKAAAAyUlEQVR42u2XwQ6AMAhD+f+f1sSbh7FSOjWzXGVkL7bA4tg9woQmNKEJTWhCE64hjCvANDC5WpwnjHvQl0DqPE0Y46AJ1wmEJBwxfxZP4MNfEyZ/eKRw3OG4gUOLN7LrlBCxN54m66XJ15KMQT8jxZdPC/yioBYEnm9KtM8TabxJmNy1lAMS8pNJTljNKa14zGohVKnQhKrBCxHmI6Ep2mSyEcVbhGAbqLYK8Cy4D/MqVc3i6bKSH+SeI34Bm9CEJjShCU1owh3iBPAfE2mbfkLKAAAAAElFTkSuQmCC",
          "captchaValue": "3bfeb",
          "customerType": "1",
          "routerPickupOption": false,
          "hasRouter": false,
          "mobilePrefixList": ["010", "011", "012"],
          "dealerSFID": "A94004088",
          "landLineNumber": "$code$phone",
          "entityId": "199498",
          "userId": "72318",
          "adslSrCreated": false,
          "cleared": false,
          "encCap": "592d758e2e0f0b3c4a2c5bd5e2dfef34",
          "fiberLandline": true,
          "userVerified": false
        });
  }

  Future<void> _updateToken() async {
    print("_update token called");
    var res = await requests.Requests.post(
      "https://extranet.vodafone.com.eg/jwt/authenticate",
      headers: {
        'channel': '1',
      },
      timeoutSeconds: 30,
      json: {
        "username": username,
        "password": password,
        "sfid": sfid,
      },
    );
    if (res.statusCode == 401) {
      print("update token is not authorizd");
      vodafoneToken = "";
    } else {
      vodafoneToken = res.json()["access_token"] ?? "";
      print("vodafone token: $vodafoneToken");
      if (vodafoneToken.isEmpty) {
        print("vodafone token is empty ${res.json()}");
      }
    }
  }

  Future<String> _getToken(String currentId) async {
    print("_getToken called");
    RunLogger().newLine(">$currentId get new token for vodafone");
    var t = "";
    var res = await requests.Requests.post(
      "https://extranet.vodafone.com.eg/jwt/authenticate",
      headers: {
        'channel': '1',
      },
      timeoutSeconds: 30,
      json: {
        "username": username,
        "password": password,
        "sfid": sfid,
      },
    );
    if (res.statusCode == 401) {
      print("get token is not authorizd");
    } else {
      t = res.json()["access_token"] ?? "";
      print("get token vodafone token: $t");
      if (t.isEmpty) {
        RunLogger().newLine(">$currentId get token for vodafone returned empty access token ${res.content()}");
        print("get token vodafone token is empty ${res.json()}");
      }
    }
    return t;
  }

  @override
  String toString() {
    return "Vodafone";
  }
}
