import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get_connect.dart';
import 'package:requests/requests.dart' as requests;
import 'package:xml/xml.dart';

enum VodafoneStatus { notReserved, reserved, error }

class VodafoneResponse {
  VodafoneStatus status;
  String id;
  String countryCode;
  String landline;
  String errorMessage = "";
  String comment = "";

  Map<String, dynamic> extras = {};

  VodafoneResponse({
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
class VodafoneScrapper {
  static final VodafoneScrapper _instance = VodafoneScrapper._internal();

  static const defaultTimeOutSeconds = 30;
  factory VodafoneScrapper() {
    return _instance;
  }
  VodafoneScrapper._internal();

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

  Future<VodafoneResponse> scrape(
      String landlineID, String code, String phone) {
    String currentId = landlineID ?? (id++).toString();
    return _scrape(currentId, code, phone);
  }

  Future<VodafoneResponse> _scrape(
    String currentId,
    String code,
    String phone,
  ) async {
    try {
      await _updateToken(code, phone);
      var res = await _request(code, phone);
      if (res.statusCode == 401) {
        vodafoneToken = "";
        return _scrape(currentId, code, phone);
      }
      final document = XmlDocument.parse(res.content());
      String msg = document
          .getElement("ADSLForm")
          ?.getElement("error")
          ?.getElement("errorMessage")
          ?.innerXml;

      if (msg != null && msg.isNotEmpty) {
        if (msg.contains("من الممكن توصيل الخدمة علي هذا الخط للرقم")) {
          return VodafoneResponse(
            status: VodafoneStatus.notReserved,
            id: currentId,
            countryCode: code,
            comment: msg,
            landline: phone,
          );
        } else {
          return VodafoneResponse(
            status: VodafoneStatus.reserved,
            id: currentId,
            countryCode: code,
            landline: phone,
          );
        }
      } else {
        return VodafoneResponse(
          status: VodafoneStatus.notReserved,
          id: currentId,
          countryCode: code,
          landline: phone,
        );
      }
    } catch (e) {
      vodafoneToken = "";
      return VodafoneResponse(
        status: VodafoneStatus.error,
        id: currentId,
        countryCode: code,
        landline: phone,
        errorMessage: "Error: " + e.toString(),
      );
    }
  }

  Future<requests.Response> _request(String code, String phone) async {
    return requests.Requests.post(
        "https://extranet.vodafone.com.eg/dealerAdsl/DealerAdsl/validateLandLine",
        headers: {
          "Authorization": "Bearer $vodafoneToken",
          'channel': '1',
        },
        json: {
          "loggedUser": {"sfid": sfid, "username": username},
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
          "selectedArea": code.trim(),
          "fiberLandline": true,
          "landLineNumber": phone.trim()
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
