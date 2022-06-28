import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get_connect.dart';
import 'package:requests/requests.dart' as requests;
import 'package:scraper/app/data/common.dart';
import 'package:scraper/io/logger.dart';

class WeStatus extends GStatus {
  WeStatus(String s) : super(s);
  WeStatus.of(GStatus s): this(s.value);
}

class WeResponse extends GScrapperResponse<WeStatus> {
  WeResponse({
    @required WeStatus status,
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
  String get name => "We";
}

/// Ardy scrapping
class WeScrapper extends GScrapper<WeResponse> {
  static final WeScrapper _instance = WeScrapper._internal();

  static const defaultTimeOutSeconds = 30;
  factory WeScrapper() {
    return _instance;
  }
  WeScrapper._internal();

  GetHttpClient client = GetHttpClient(
    timeout: Duration(seconds: defaultTimeOutSeconds),
    allowAutoSignedCert: true,
  );
  String weToken = "";
  int id = 1;

  @override
  Future<WeResponse> scrape(String landlineID, String code, String phone) {
    String currentId = landlineID ?? (id++).toString();
    return _scrape(currentId, code, phone);
  }

  Future<WeResponse> _scrape(
    String currentId,
    String code,
    String phone,
  ) async {
    var resContent = "";
    try {
      await _updateToken(code, phone);
      var res = await _request(code, phone);
      resContent = res.bodyString;
      final body = res.body;
      if(res.hasError) {
        throw("unexpected response, status code ${res.statusCode}, statusText ${res.statusText}");
      }
      if (body["body"] == null) {
        String msg = body["header"]["responseMessage"];
        if (msg.contains("Subscriber information is not exist")) {
          return WeResponse(
            status: WeStatus.of(GStatus.notReserved()),
            id: currentId,
            countryCode: code,
            landline: phone,
            comment: msg
          );
        } else {
          return WeResponse(
            status: WeStatus.of(GStatus.reserved()),
            id: currentId,
            countryCode: code,
            landline: phone,
            errorMessage: msg, 
          );
        }
      } else {
        return WeResponse(
          status: WeStatus.of(GStatus.reserved()),
          id: currentId,
          countryCode: code,
          landline: phone,
          comment: body["header"]["responseMessage"],
        );
      }
    } catch (e, s) {
      RunLogger().newLine(">$currentId #we error: $e while resContent=$resContent with stacktrace $s");
      return WeResponse(
        status: WeStatus.of(GStatus.error()),
        id: currentId,
        countryCode: code,
        landline: phone,
        errorMessage: "Error: " + e.toString(),
      );
    }
  }

  Future<Response> _request(String code, String phone) async {
    return client.post(
      "https://api-my.te.eg/api/line/adsl/amount",
      headers: {"Jwt": weToken},
      body: {
        "header": {"locale": "en"},
        "body": {
          "governmentCode": code.trim(),
          "landLine": phone.trim(),
        }
      },
    );
  }

  Future<void> _updateToken(String code, String phone) async {
    if (weToken.isNotEmpty) {
      return;
    }
    var res = await requests.Requests.get(
        "https://api-my.te.eg/api/user/generatetoken?channelId=WEB_APP");
    weToken = res.json()["body"]["jwt"];
  }

  @override
  String toString() {
    return "We";
  }
}
