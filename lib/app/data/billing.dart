import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:scraper/app/data/common.dart';
import 'package:scraper/io/logger.dart';

class BillingStatus extends GStatus {
  static const _wrongNumber = "wrongNumber";
  static const _noBills = "noBills";
  static const _twoOrMoreBills = "twoOrMoreBills";
  static const _billLessGracePeriod = "billLessGracePeriod";
  static const _billMoreGracePeriod = "billMoreGracePeriod";
  static const _pin = "pin";

  BillingStatus(String s) : super(s);
  BillingStatus.of(GStatus s) : this(s.value);

  factory BillingStatus.wrongNumber() {
    return BillingStatus(BillingStatus._wrongNumber);
  }
  factory BillingStatus.noBills() {
    return BillingStatus(BillingStatus._noBills);
  }
  factory BillingStatus.twoOrMoreBills() {
    return BillingStatus(BillingStatus._twoOrMoreBills);
  }
  factory BillingStatus.billLessGracePeriod() {
    return BillingStatus(BillingStatus._billLessGracePeriod);
  }
  factory BillingStatus.billMoreGracePeriod() {
    return BillingStatus(BillingStatus._billMoreGracePeriod);
  }
  factory BillingStatus.pin() {
    return BillingStatus(BillingStatus._pin);
  }
}

class BillingResponse extends GScrapperResponse<BillingStatus> {
  String newLandlineNumber = "";
  String customerCategory = "";
  double deposit;
  double lastBillAmount;

  BillingResponse({
    @required BillingStatus status,
    @required String id,
    @required String countryCode,
    @required String landline,
    String errorMessage,
    String comment,
    Map<String, dynamic> extras,
    this.newLandlineNumber,
    this.customerCategory,
    this.deposit,
    this.lastBillAmount,
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
  String get name => "Billing";
}

/// Ardy scrapping
class BillingScrapper extends GScrapper<BillingResponse> {
  static final BillingScrapper _instance = BillingScrapper._internal();

  static const defaultTimeOutSeconds = 30;
  factory BillingScrapper() {
    return _instance;
  }
  BillingScrapper._internal();

  String weToken = "0000000000000000000000000000000000000000";
  int id = 1;

  int gracePeriodDays = 55;

  void init({int gracePeriodDays = 55}) {
    this.gracePeriodDays = gracePeriodDays;
  }

  @override
  Future<BillingResponse> scrape(String landlineID, String code, String phone) {
    String currentId = landlineID ?? (id++).toString();
    return _scrape(currentId, code, phone);
  }

  Future<BillingResponse> _scrape(
    String currentId,
    String code,
    String phone,
  ) async {
    var resContent = "";
    try {
      // await _updateToken(currentId, code, phone);
      var res = await _request(code, phone);
      // raiseForNotCorrectStatus(res);
      String newLandline = "";
      resContent = res.body;

      // first we should check for new landline number
      if (resContent.contains('telephone does not exist')) {
        // changing numbers may be a series of changes
        do {
          phone = newLandline.isEmpty ? phone : newLandline;
          newLandline = await checkChangedLanline(code, phone);
          final wrong = newLandline == null, pin = newLandline == "pin";
          // telephone doesn't exist, wrong number or changed
          if (wrong || pin) {
            // wrong number or pin
            return BillingResponse(
              countryCode: code,
              id: currentId,
              landline: phone,
              newLandlineNumber:
                  (newLandline ?? "").isEmpty ? phone : newLandline,
              status: wrong ? BillingStatus.wrongNumber() : BillingStatus.pin(),
              comment: pin ? "Can't get new number of that number" : "",
            );
          }
          // number changed, request again with this number
          RunLogger().newLine(
              ">$currentId number changed, request again with this number");
          res = await _request(code, newLandline);
          // raiseForNotCorrectStatus(res);
          resContent = res.body;
        } while (resContent.contains('telephone does not exist'));
      }

      if (resContent
          .contains("inquire about this account number in the website")) {
        return BillingResponse(
            countryCode: code,
            id: currentId,
            landline: phone,
            newLandlineNumber:
                (newLandline ?? "").isEmpty ? phone : newLandline,
            status: BillingStatus.pin(),
            comment: resContent);
      }
      if (resContent.contains("An unexcepeted error occurred")) {
        RunLogger().newLine(
            ">$currentId #billing we returned unexcepeted error occurred");
        return BillingResponse(
            id: currentId,
            countryCode: code,
            landline: phone,
            newLandlineNumber: phone,
            status: BillingStatus.pin(),
            errorMessage: "error: An unexcepeted error occurred",
            comment: "call 111");
      }

      final resJson = jsonDecode(resContent);
      if (resJson["Account"] == null) {
        return BillingResponse(
            countryCode: code,
            id: currentId,
            landline: phone,
            newLandlineNumber:
                (newLandline ?? "").isEmpty ? phone : newLandline,
            status: BillingStatus.pin(),
            comment: resContent);
      }
      List unPaid = resJson["Account"]["UnPaidInvoices"] ?? [];
      if (unPaid.isEmpty) {
        unPaid = resJson["Account"]["Invoices"] ?? [];
      }
      if (unPaid.length >= 2) {
        return BillingResponse(
          id: currentId,
          countryCode: code,
          landline: phone,
          status: BillingStatus.twoOrMoreBills(),
          newLandlineNumber: (newLandline ?? "").isEmpty ? phone : newLandline,
          comment: newLandline.isNotEmpty ? "number has been changed" : "",
          extras: resJson,
          customerCategory: resJson["Account"]["Customer"]["CategoryName"],
          deposit: resJson["Account"]["Customer"]["DepositValue"],
          lastBillAmount: unPaid[0]["TotalAmount"],
        );
      }
      if (unPaid.isEmpty) {
        return BillingResponse(
          id: currentId,
          countryCode: code,
          landline: phone,
          status: BillingStatus.noBills(),
          newLandlineNumber: (newLandline ?? "").isEmpty ? phone : newLandline,
          comment: newLandline.isNotEmpty ? "number has been changed" : "",
          extras: resJson,
          customerCategory: resJson["Account"]["Customer"]["CategoryName"],
          deposit: resJson["Account"]["Customer"]["DepositValue"],
        );
      }
      if (unPaid.length == 1) {
        var invoice = unPaid.first;
        final dateJson = invoice["BillDateClient"];
        final month = dateJson["Month"], year = dateJson["Year"];
        Duration invoiceDuration = getInvoiceDuration(year, month);
        bool isOverAcceptedDuration = checkInvoiceGracePeriod(invoiceDuration);
        resJson.update(
            "billExistenceDays", (value) => invoiceDuration.inDays.toString(),
            ifAbsent: () => invoiceDuration.inDays.toString());
        if (isOverAcceptedDuration) {
          return BillingResponse(
            id: currentId,
            countryCode: code,
            landline: phone,
            status: BillingStatus.billMoreGracePeriod(),
            newLandlineNumber:
                (newLandline ?? "").isEmpty ? phone : newLandline,
            comment: newLandline.isNotEmpty ? "number has been changed" : "",
            extras: resJson,
            customerCategory: resJson["Account"]["Customer"]["CategoryName"],
            deposit: resJson["Account"]["Customer"]["DepositValue"],
          );
        }
        return BillingResponse(
          id: currentId,
          countryCode: code,
          landline: phone,
          status: BillingStatus.billLessGracePeriod(),
          // newLandlineNumber: newLandline,
          newLandlineNumber: (newLandline ?? "").isEmpty ? phone : newLandline,
          comment: newLandline.isNotEmpty ? "number has been changed" : "",
          extras: resJson,
          customerCategory: resJson["Account"]["Customer"]["CategoryName"],
          deposit: resJson["Account"]["Customer"]["DepositValue"],
        );
      }
    } catch (e, s) {
      print(e.toString());
      RunLogger().newLine(
          ">$currentId #billing error: $e while the resContent was $resContent. stacktrace $s");
      return BillingResponse(
        id: currentId,
        countryCode: code,
        landline: phone,
        newLandlineNumber: phone,
        status: BillingStatus.of(GStatus.error()),
        errorMessage: "error: " + e.toString(),
      );
    }
  }

  Future<void> _updateToken(String llid, String code, String phone) async {
    if (weToken.isNotEmpty) {
      return;
    }
    RunLogger().newLine(">$llid we token is empty, update token");
    final reqRes = await http.post(
      "https://billing.te.eg/api/Account/Inquiry",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
      },
      body: {
        "AreaCode": "02",
        "PhoneNumber": "37711972",
        "InquiryBy": "telephone",
      },
    );
    weToken = reqRes.headers['set-cookie'].split("token=")[1].split(";")[0];
    RunLogger().newLine(">$llid new we cookie is generated = $weToken");
  }

  Future<http.Response> _request(String code, String phone) async {
    return http.post(
      "https://billing.te.eg/api/Account/Inquiry",
      headers: {
        "token": weToken,
      },
      body: {
        "AreaCode": code.trim(),
        "PhoneNumber": phone.trim(),
        "InquiryBy": "telephone",
      },
    );
  }

  Future<String> checkChangedLanline(String code, String phone) async {
    final res = await http.post(
      "https://billing.te.eg/api/Account/GetChangedNo",
      headers: {
        "token": weToken,
      },
      body: {
        "AreaCode": code.trim(),
        "PhoneNumber": phone.trim(),
        // "InquiryBy": "telephone",
      },
    );
    if (res.headers.containsKey("inquirystatus") &&
        res.headers["inquirystatus"] == "RequirePinCode") {
      return "pin";
    }
    // raiseForNotCorrectStatus(res);
    final content = res.body;
    if (content.contains("has not changed")) {
      return null;
    }
    RunLogger().newLine("$phone has chanched. $content");
    print("content: " + content);
    return content.split(">")[1].split("<")[0].split("-")[1].trim();
  }

  /// get duration that invoice started in till now
  Duration getInvoiceDuration(int year, int month) {
    final billDate = DateTime.utc(year, month + 1);
    final now = DateTime.now();
    return now.difference(billDate);
  }

  bool checkInvoiceGracePeriod(Duration duration) =>
      duration > Duration(days: gracePeriodDays);

  @override
  String toString() {
    return "Billing";
  }

  @override
  Future<void> waitPreferedTime() {
    return Future.delayed(Duration(milliseconds: 0));
  }

  void raiseForNotCorrectStatus(http.Response response) {
    if(response.statusCode >= 400) {
      throw Exception("response is not success (${response.statusCode}). body is: ${response.body}");
    }
  }
}
