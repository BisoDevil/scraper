import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:requests/requests.dart' as requests;
import 'package:enough_convert/enough_convert.dart';
import 'package:scraper/app/data/common.dart';
import 'package:scraper/io/logger.dart';

class EtisalatStatus extends GStatus {
  EtisalatStatus(String s) : super(s);
  EtisalatStatus.of(GStatus s): this(s.value);
}

class EtisalatResponse extends GScrapperResponse<EtisalatStatus> {
  EtisalatResponse({
    @required EtisalatStatus status,
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
  String get name => "Etisalat";
}

/// Ardy scrapping
class EtisalatScrapper extends GScrapper<EtisalatResponse> {
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
    RunLogger().newLine(">INIT initialize etisalt with $username, $password");

    this.username = username;
    this.password = password;
    this.stopIfInvalidCredentials = stopIfInvalidCredentials;

    try {
      await _updateCookie();
    } catch (e) {
      RunLogger().newLine("error in init etisalat ${e.toString()}");
      throw ("Can't initialize etisalat scrapper, error: ${e.toString()}");
    }
  }

  @override
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
    var resContent = "";
    try {
      if (etisalatCookie.isEmpty) {
        return EtisalatResponse(
          countryCode: code,
          id: currentId,
          landline: phone,
          errorMessage: "Can't authenticate user. not valid cookie",
          status: EtisalatStatus.of(GStatus.error()),
        );
      }
      var res = await _request(code, phone);
      res.raiseForStatus();
      if (res.statusCode == 302) {
        print("AMMAR:: Empty response waiting one second...");
        RunLogger().newLine(">$currentId Etisalat returned Empty response 302, waiting one second");
        // await _updateCookie();
        return Future.delayed(
            Duration(seconds: 1), () => _scrape(currentId, code, phone));
        // return Future.delayed(
        //     Duration(seconds: 1),
        //     () => EtisalatResponse(
        //           status: EtisalatStatus.of(GStatus.error()),
        //           id: currentId,
        //           countryCode: code,
        //           landline: phone,
        //           errorMessage: "302 redirected",
        //         ));
      }
      resContent = Windows1256Codec(allowInvalid: true).decode(res.bytes());
      if (resContent.contains("customerBasicData")) {
        return EtisalatResponse(
          countryCode: code,
          id: currentId,
          landline: phone,
          comment: "contains customerBasicData",
          status: EtisalatStatus.of(GStatus.notReserved()),
        );
      }
      if (resContent.contains("errorMessage")) {
        var istart = resContent.lastIndexOf("errorMessage");
        istart = resContent.indexOf(">", istart); // close the tag label
        final iend = resContent.indexOf("<", istart);
        final msg = resContent.substring(istart, iend);
        return EtisalatResponse(
          countryCode: code,
          id: currentId,
          landline: phone,
          comment: "contains errorMessage ($msg)",
          status: EtisalatStatus.of(GStatus.reserved()),
        );
      }
      if (resContent.contains("j_security_check") &&
          resContent.contains("mdl-login-forget")) {
        final errorCookie = etisalatCookie;
        RunLogger().newLine(">00 etisalat cookie is not correct $errorCookie");
        if (stopIfInvalidCredentials) {
          etisalatCookie = "";
        }
        return EtisalatResponse(
          countryCode: code,
          id: currentId,
          landline: phone,
          comment: "redirected to login page",
          errorMessage: "Can't authenticate user. not valid cookie",
          status: EtisalatStatus.of(GStatus.error()),
          extras: {'error-cookie': errorCookie},
        );
      }
      RunLogger().newLine(">00 Etisalat empty response, content $resContent");
      return EtisalatResponse(
        countryCode: code,
        id: currentId,
        landline: phone,
        comment: "Empty. please check manually !",
        status: EtisalatStatus.of(GStatus.notReserved()),
        errorMessage: resContent,
      );
    } catch (e, s) {
      RunLogger().newLine(">$currentId #etisalat error: $e while resContent=$resContent with stacktrace $s");
      return EtisalatResponse(
        id: currentId,
        countryCode: code,
        landline: phone,
        status: EtisalatStatus.of(GStatus.error()),
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
    RunLogger().newLine(">00 update etisalat cookie");
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

  @override
  String toString() {
    return "Etislat";
  }
}
