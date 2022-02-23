import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get_connect.dart';
import 'package:intl/intl.dart';
import 'package:windows_ocr/windows_ocr.dart';
import 'package:xml/xml.dart';
import 'package:requests/requests.dart';

class Scrapper {
  GetHttpClient client = GetHttpClient(
    timeout: Duration(seconds: 30),
  );
  File xFile;
  String weToken = "", vodafoneToken = '', etisalatCookie = '';
  Webview webview;
  static bool browserInitialized = false;

  Future<String> validateNumber(
      {@required String code,
      @required String phone,
      @required String username,
      @required String password,
      @required String etisalatUsername,
      @required String etisalatPassword,
      @required bool allowVodafone,
      @required bool allowEtisalat,
      @required bool allowVodafoneSecondStep,
      @required bool allowOrange,
      @required bool allowWe,
      @required String sfid}) async {
    /// open browser for orange
    var dir = Directory(Platform.resolvedExecutable).parent.path;
    xFile = File("$dir/log_${DateFormat.MMMEd().format(DateTime.now())}.txt");

    if (allowOrange && !browserInitialized) {
      webview = await WebviewWindow.create(
        configuration: CreateConfiguration(
          windowHeight: 5,
          windowWidth: 280,
          titleBarHeight: 1,
        ),
      );

      webview.launch("https://dsl.orange.eg/en/myaccount/pay-bill");
      await Future.delayed(Duration(seconds: 15));
      browserInitialized = true;
    }

    if (allowWe && !await _scraperWe(code, phone)) {
      return "Reserved in WE";
    } else if (allowVodafone &&
        !await _scraperVodafone(
          code: code,
          phone: phone,
          username: username,
          password: password,
          sfid: sfid,
        )) {
      return "Reserved in Vodafone";
    } else if (allowVodafoneSecondStep &&
        !await _scraperVodafoneSecondStep(
          code: code,
          phone: phone,
          username: username,
          password: password,
          sfid: sfid,
        )) {
      return "Reserved in Vodafone second step";
    } else if (allowEtisalat &&
        !await _scraperEtisalat(
          code: code,
          phone: phone,
          username: etisalatUsername,
          password: etisalatPassword,
        )) {
      return "Reserved in Etisalat";
    } else if (allowOrange &&
        !await _scraperOrange(
          code: code,
          phone: phone,
        )) {
      return "Reserved in Orange";
    } else {
      return "Will check in other Provider";
    }
  }

  /// Scape We
  Future<bool> _scraperWe(String code, String phone) async {
    try {
      if (weToken.isEmpty) {
        var res = await client.get<Map>(
            "https://api-my.te.eg/api/user/generatetoken?channelId=WEB_APP");
        weToken = res.body["body"]["jwt"];
      }

      var res = await client.post(
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
      if (res.body["body"] == null) {
        String msg = res.body["header"]["responseMessage"];
        writeLine("$code,$phone,$msg");
        print(msg);
        if (msg.contains("Subscriber information is not exist")) {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<String> scraperArdy(String code, String phone) async {
    var res = await client.post(
      "https://billing.te.eg/api/Account/Inquiry",
      body: FormData(
        {
          "AreaCode": code.trim(),
          "PhoneNumber": phone.trim(),
          "InquiryBy": "telephone",
        },
      ),
    );
    List unPaid = res.body["Account"]["UnPaidInvoices"];
    if (unPaid.isEmpty) {
      return "No unpaid Invoice";
    } else {
      return "${unPaid.length} Inovice(s)";
    }
  }

  /// Scarpper Vodafone first step
  Future<bool> _scraperVodafone(
      {@required String code,
      @required String phone,
      @required String username,
      @required String password,
      @required String sfid}) async {
    try {
      if (vodafoneToken.isEmpty) {
        var res = await Requests.post(
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

      var res = await Requests.post(
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

      if (res.statusCode == 401) {
        vodafoneToken = "";
        return _scraperVodafone(
            code: code,
            phone: phone,
            username: username,
            password: password,
            sfid: sfid);
      }
      final document = XmlDocument.parse(res.content());
      String msg = document
          .getElement("ADSLForm")
          ?.getElement("error")
          ?.getElement("errorMessage")
          ?.innerXml;

      writeLine("$code,$phone,$msg");
      if (msg != null && msg.isNotEmpty) {
        if (msg.contains("من الممكن توصيل الخدمة علي هذا الخط للرقم")) {
          return true;
        } else {
          return false;
        }
      } else {
        return true;
      }
    } catch (e) {
      vodafoneToken = "";
      return _scraperVodafone(
          code: code,
          phone: phone,
          username: username,
          password: password,
          sfid: sfid);
    }
  }

  /// Scrape Vodafone Second Step
  Future<bool> _scraperVodafoneSecondStep({
    @required String code,
    @required String phone,
    @required String username,
    @required String password,
    @required String sfid,
  }) async {
    try {
      if (vodafoneToken.isEmpty) {
        var res = await Requests.post(
          "https://extranet.vodafone.com.eg/jwt/authenticate",
          headers: {
            'channel': '1',
          },
          json: {
            "username": username,
            "password": password,
            "sfid": sfid,
          },
        );
        vodafoneToken = res.json()["access_token"];
      }

      var res = await Requests.post(
        "https://extranet.vodafone.com.eg/dealerAdsl/DealerAdsl/customerDetails",
        timeoutSeconds: 30,
        headers: {
          "Authorization": "Bearer $vodafoneToken",
          'channel': '1',
        },
        json: {
          "loggedUser": {"sfid": "A94004088", "username": "ASK"},
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
          "dealerName": "أسك",
          "customerType": "1",
          "routerPickupOption": false,
          "hasRouter": false,
          "dealerSFID": "A94004088",
          "landLineNumber": "${code.trim()}${phone.trim()}",
          "entityId": "199498",
          "userId": "72318",
          "adslSrCreated": false,
          "cleared": false,
          "fiberLandline": true,
          "userVerified": false
        },
      );
      print(res.statusCode == 401);
      if (res.statusCode == 401) {
        vodafoneToken = "";
        return _scraperVodafoneSecondStep(
            code: code,
            phone: phone,
            username: username,
            password: password,
            sfid: sfid);
      }

      var document = XmlDocument.parse(res.content());
      String captcha =
          document.getElement("ADSLForm")?.getElement("captcha")?.innerXml;
      Uint8List bytes = base64Decode(captcha);
      var captchaFile = File("captcha.jpg")..writeAsBytesSync(bytes);
      var captchValue = await WindowsOcr.getOcr(captchaFile.path);
      captchValue = captchValue.split("\n").first;
      print(captchValue);
      res = await Requests.post(
          "https://extranet.vodafone.com.eg/dealerAdsl/DealerAdsl/sendCustomerDetails",
          headers: {"Authorization": "Bearer $vodafoneToken"},
          timeoutSeconds: 30,
          json: {
            "loggedUser": {"sfid": "A94004088", "username": "ASK"},
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
            "clientFullName": "assds",
            "landLineOwnerName": "asdss",
            "msisdn": "08981342",
            "selectedMobilePrefix": "010",
            "additionalContactNumber": "00000000000",
            "nationalId": "00000000000000",
            "address": "dfs",
            "dealerMobileNumber": "00000000",
            "selectedDealerMobilePrefix": "010",
            "captcha": captcha,
            "captchaValue": captchValue.trim(),
            "customerType": "1",
            "routerPickupOption": false,
            "hasRouter": false,
            "mobilePrefixList": ["010", "011", "012"],
            "dealerSFID": "A94004088",
            "landLineNumber": "${code.trim()}${phone.trim()}",
            "adslSrCreated": false,
            "cleared": false,
            "fiberLandline": true,
            "userVerified": false
          });

      document = XmlDocument.parse(res.content());
      String msg = document
          .getElement("ADSLForm")
          ?.getElement("error")
          ?.getElement("errorMessage")
          ?.innerXml;
      print(msg);
      writeLine("$code,$phone,$msg");
      if (msg != null && msg.isEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      vodafoneToken = "";
      return _scraperVodafoneSecondStep(
          code: code,
          phone: phone,
          username: username,
          password: password,
          sfid: sfid);
    }
  }

  /// Scrap Etisalat
  Future<bool> _scraperEtisalat(
      {@required String code,
      @required String phone,
      @required String username,
      @required String password}) async {
    try {
      if (etisalatCookie.isEmpty) {
        var r1 = await Requests.post(
            "https://newextranet.etisalat.com.eg/j_security_check",
            body: {"j_username": username, "j_password": password},
            bodyEncoding: RequestBodyEncoding.FormURLEncoded);
        r1.raiseForStatus();
        etisalatCookie = r1.headers[HttpHeaders.setCookieHeader];
      }

      var res = await Requests.post(
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
          bodyEncoding: RequestBodyEncoding.FormURLEncoded);
      res.raiseForStatus();
      if (res.content().contains("customerBasicData")) {
        print("contain customerBasicData ");
        return true;
      } else if (res.content().contains("errorMessage")) {
        print("contain errorMessage ");

        return false;
      } else {
        print("Empty");
        return true;
      }
    } catch (e) {
      etisalatCookie = "";
      writeLine(e.toString());
      print(e.toString());
      return _scraperEtisalat(
          code: code, phone: phone, username: username, password: password);
    }
  }

  Future<bool> _scraperOrange({String code, String phone}) async {
    await webview.evaluateJavaScript(
        'document.getElementById("ctl00_ctl33_g_3755bda3_055d_40fd_9835_23ecc6ff2207_ctl00_txtLineNumber").value = "$code$phone"');
    await webview.evaluateJavaScript(
        'document.getElementById("ctl00_ctl33_g_3755bda3_055d_40fd_9835_23ecc6ff2207_ctl00_btnGetUserBills").click()');
    await Future.delayed(Duration(seconds: 10));
    var res = await webview.evaluateJavaScript(
        'document.getElementById("ctl00_ctl33_g_3755bda3_055d_40fd_9835_23ecc6ff2207_ctl00_lblErrorMsg").innerHTML');

    if (!res.contains(
        "The service is temporarily unavailable. Please try again later")) {
      writeLine(
          "$code,$phone,The service is temporarily unavailable. Please try again later");
      return false;
    } else {
      return true;
    }
  }

  writeLine(String line) async {
    if (!await xFile.exists()) {
      xFile.createSync();
    }

    String content = xFile.readAsStringSync();
    content += "\n$line";
    xFile.writeAsStringSync(content);
  }
}