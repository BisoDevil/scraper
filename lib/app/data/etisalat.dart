import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:requests/requests.dart' as requests;
import 'package:enough_convert/enough_convert.dart';

enum EtisalatStatus { notReserved, reserved, error }

class EtisalatResponse {
  EtisalatStatus status;
  String id;
  String countryCode;
  String landline;
  String errorMessage = "";
  String comment = "";

  Map<String, dynamic> extras = {};

  EtisalatResponse({
    @required this.status,
    @required this.id,
    @required this.countryCode,
    @required this.landline,
    this.errorMessage,
    this.comment,
    this.extras,
  });
}

/// Ardy scrapping
class EtisalatScrapper {
  static final EtisalatScrapper _instance = EtisalatScrapper._internal();

  static const defaultTimeOutSeconds = 30;
  factory EtisalatScrapper() {
    return _instance;
  }
  EtisalatScrapper._internal();

  String username;
  String password;
  bool stopIfInvalidCredentials = true;
  int id = 1;
  String etisalatCookie = "";
  String loginErr;

  Future<void> init(
    String username,
    String password, {
    bool stopIfInvalidCredentials = true,
  }) async {
    this.username = username;
    this.password = password;
    this.stopIfInvalidCredentials = stopIfInvalidCredentials;

    try {
      await _updateCookie();
    } catch (e) {
      print("error in init etisalat ${e.toString()}");
      throw("Can't initialize etisalat scrapper, error: ${e.toString()}");
    }
  }

  Future<EtisalatResponse> scrape(
      String landlineID, String code, String phone) async {
    String currentId = landlineID ?? (id++).toString();
    return _scrape(currentId, code, phone);
  }

  Future<EtisalatResponse> _scrape(
    String currentId,
    String code,
    String phone,
  ) async {
    try {
      if (etisalatCookie.isEmpty) {
        return EtisalatResponse(
          countryCode: code,
          id: currentId,
          landline: phone,
          errorMessage: "Can't authenticate user. not valid cookie",
          status: EtisalatStatus.error,
        );
      }
      var res = await _request(code, phone);
      res.raiseForStatus();
      if (res.statusCode == 302) {
        print("AMMAR:: Empty response waiting one second...");
        // await _updateCookie();
        return Future.delayed(Duration(seconds: 1), () => _scrape(currentId, code, phone));
        // return Future.delayed(
        //     Duration(seconds: 1),
        //     () => EtisalatResponse(
        //           status: EtisalatStatus.error,
        //           id: currentId,
        //           countryCode: code,
        //           landline: phone,
        //           errorMessage: "302 redirected",
        //         ));
      }
      var resContent = Windows1256Codec(allowInvalid: true).decode(res.bytes());
      if (resContent.contains("customerBasicData")) {
        return EtisalatResponse(
          countryCode: code,
          id: currentId,
          landline: phone,
          comment: "contains customerBasicData",
          status: EtisalatStatus.notReserved,
        );
      }
      if (resContent.contains("errorMessage")) {
        var istart = resContent.lastIndexOf("errorMessage");
        istart = resContent.indexOf(">", istart); // close the tag label
        final iend = resContent.indexOf("<", istart);
        final msg = resContent.substring(istart, iend);
        print("AMMAR::: $msg");
        return EtisalatResponse(
          countryCode: code,
          id: currentId,
          landline: phone,
          comment: "contains errorMessage ($msg)",
          status: EtisalatStatus.reserved,
        );
      }
      if (resContent.contains("j_security_check") &&
          resContent.contains("mdl-login-forget")) {
        final errorCookie = etisalatCookie;
        if (stopIfInvalidCredentials) {
          etisalatCookie = "";
        }
        return EtisalatResponse(
          countryCode: code,
          id: currentId,
          landline: phone,
          comment: "redirected to login page",
          errorMessage: "Can't authenticate user. not valid cookie",
          status: EtisalatStatus.error,
          extras: {'error-cookie': errorCookie},
        );
      }
      print("AMMAR:: Empty response");
      print(resContent);
      print(res.statusCode);
      return EtisalatResponse(
        countryCode: code,
        id: currentId,
        landline: phone,
        comment: "Empty. please check manually !",
        status: EtisalatStatus.notReserved,
        errorMessage: resContent,
      );
    } catch (e) {
      print(e.toString());
      return EtisalatResponse(
        id: currentId,
        countryCode: code,
        landline: phone,
        status: EtisalatStatus.error,
        errorMessage: "error: " + e.toString(),
      );
    }
  }

  Future<requests.Response> _request(String code, String phone) async {
    return requests.Requests.post(
      "https://newextranet.etisalat.com.eg/pages/dsl/newDslReqLandLine.dts",
      timeoutSeconds: 30,
      body: {
        "_Invoker": "jspx_generated_4",
        "_EventName": "IsDslServiceAvailableForLandLine",
        "_EventArgs": "undefined",
        "_EventType": "undefined",
        "_Group": "x",
        "JSPX_CONVERSATION_SCOPE_ID":
            DateTime.now().millisecondsSinceEpoch.toString(),
        "landLine": "$code$phone",
        "landLineType": "MSAN"
      },
      bodyEncoding: requests.RequestBodyEncoding.FormURLEncoded,
    );
  }

  Future<void> _updateCookie() async {
    var r1 = await requests.Requests.post(
      "https://newextranet.etisalat.com.eg/j_security_check",
      body: {"j_username": username, "j_password": password},
      bodyEncoding: requests.RequestBodyEncoding.FormURLEncoded,
      timeoutSeconds: defaultTimeOutSeconds,
    );
    if (r1.statusCode == 403 ||
        r1.content().contains("اسم المستخدم او كلمة السر خطأ")) {
      etisalatCookie = "";
    } else {
      etisalatCookie = r1.headers[HttpHeaders.setCookieHeader];
    }
  }
}
