import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get_connect.dart';
import 'package:requests/requests.dart' as requests;

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
  GetHttpClient client = GetHttpClient(
    timeout: Duration(seconds: defaultTimeOutSeconds),
    allowAutoSignedCert: true,
  );
  int id = 1;
  String etisalatCookie = "";

  void init(String username, String password) {
    this.username = username;
    this.password = password;
  }

  Future<EtisalatResponse> scrape(String landlineID, String code, String phone) {
    String currentId = landlineID ?? (id++).toString();
    return _scrape(currentId, code, phone);
  }

  Future<EtisalatResponse> _scrape(
    String currentId,
    String code,
    String phone,
  ) async {
    try {
      await _updateCookie(code, phone);
      var res = await _request(code, phone);
      res.raiseForStatus();
      var resContent = res.content();
      if (resContent.contains("customerBasicData")) {
        return EtisalatResponse(
          countryCode: code,
          id: currentId,
          landline: phone,
          comment: "contains customerBasicData",
          status: EtisalatStatus.reserved,
        );
      }
      if (resContent.contains("errorMessage")) {
        return EtisalatResponse(
          countryCode: code,
          id: currentId,
          landline: phone,
          comment: "contains error",
          status: EtisalatStatus.notReserved,
        );
      }
      return EtisalatResponse(
        countryCode: code,
        id: currentId,
        landline: phone,
        comment: "Empty",
        status: EtisalatStatus.reserved,
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

  Future<void> _updateCookie(String code, String phone) async {
    if (etisalatCookie.isEmpty) {
      var r1 = await requests.Requests.post(
          "https://newextranet.etisalat.com.eg/j_security_check",
          body: {"j_username": username, "j_password": password},
          bodyEncoding: requests.RequestBodyEncoding.FormURLEncoded);
      r1.raiseForStatus();
      etisalatCookie = r1.headers[HttpHeaders.setCookieHeader];
    }
  }
}
