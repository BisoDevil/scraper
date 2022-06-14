import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get_connect.dart';
import 'package:requests/requests.dart' as requests;
import 'package:xml/xml.dart';

enum Vodafone2Status { notReserved, reserved, error }

class Vodafone2Response {
  Vodafone2Status status;
  String id;
  String countryCode;
  String landline;
  String errorMessage = "";
  String comment = "";

  Map<String, dynamic> extras = {};

  Vodafone2Response({
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
class Vodafone2Scrapper {
  static final Vodafone2Scrapper _instance = Vodafone2Scrapper._internal();

  static const defaultTimeOutSeconds = 30;
  factory Vodafone2Scrapper() {
    return _instance;
  }
  Vodafone2Scrapper._internal();

  GetHttpClient client = GetHttpClient(
    timeout: Duration(seconds: defaultTimeOutSeconds),
    allowAutoSignedCert: true,
  );
  String vodafoneToken = "";
  int id = 1;
  String username;
  String password;
  String sfid;
  void init(String username, String password, String sfid) {
    this.username = username;
    this.password = password;
    this.sfid = sfid;
  }

  Future<Vodafone2Response> scrape(
      String landlineID, String code, String phone) {
    String currentId = landlineID ?? (id++).toString();
    return _scrape(currentId, code, phone);
  }

  Future<Vodafone2Response> _scrape(
    String currentId,
    String code,
    String phone,
  ) async {
    try {
      await _updateToken(code, phone);
      var res = await _request(code, phone);

      var document = XmlDocument.parse(res.content());
      String msg = document
          .getElement("ADSLForm")
          ?.getElement("error")
          ?.getElement("errorMessage")
          ?.innerXml;
      if (msg != null && msg.isEmpty) {
        return Vodafone2Response(
          status: Vodafone2Status.notReserved,
          id: currentId,
          countryCode: code,
          landline: phone,
        );
      } else {
        return Vodafone2Response(
          status: Vodafone2Status.reserved,
          id: currentId,
          countryCode: code,
          landline: phone,
        );
      }
    } catch (e) {
      vodafoneToken = "";
      return Vodafone2Response(
        status: Vodafone2Status.error,
        id: currentId,
        countryCode: code,
        landline: phone,
        errorMessage: "Error: " + e.toString(),
      );
    }
  }

  Future<requests.Response> _request(String code, String phone) async {
    return requests.Requests.post(
        "https://extranet.vodafone.com.eg/dealerAdsl/DealerAdsl/sendCustomerDetails",
        headers: {"Authorization": "Bearer $vodafoneToken"},
        timeoutSeconds: 30,
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

  Future<void> _updateToken(String code, String phone) async {
    if (vodafoneToken.isNotEmpty) {
      return;
    }
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
    vodafoneToken = res.json()["access_token"];
  }
}
