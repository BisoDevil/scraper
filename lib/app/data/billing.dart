import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get_connect.dart';
import 'package:requests/requests.dart' as requests;

enum BillingStatus {
  wrongNumber,
  noBills,
  twoOrMoreBills,
  billLess55,
  billMore55,
  pin,
  error
}

class BillingResponse {
  BillingStatus status;
  String id;
  String countryCode;
  String landline;
  String newLandlineNumber = "";
  String errorMessage = "";
  String comment = "";
  String customerCategory = "";
  double deposit;
  double lastBillAmount;

  Map<String, dynamic> extras = {};

  BillingResponse({
    @required this.status,
    @required this.id,
    @required this.countryCode,
    @required this.landline,
    this.newLandlineNumber,
    this.errorMessage,
    this.comment,
    this.extras,
    this.customerCategory,
    this.deposit,
    this.lastBillAmount,
  });
}

/// Ardy scrapping
class BillingScrapper {
  static final BillingScrapper _instance = BillingScrapper._internal();

  static const defaultTimeOutSeconds = 20;
  factory BillingScrapper() {
    return _instance;
  }
  BillingScrapper._internal();

  GetHttpClient client = GetHttpClient(
    timeout: Duration(seconds: 30),
    allowAutoSignedCert: true,
    
  );
  String weToken = "";
  int id = 1;

  static const int gracePeriodDays = 55;
  Future<BillingResponse> scrape(String code, String phone) {
    String currentId = (id++).toString();
    return _scrape(currentId, code, phone);
  }

  Future<BillingResponse> _scrape(
    String currentId,
    String code,
    String phone,
  ) async {
    try {
      await _updateToken(code, phone);
      var res = await _request(code, phone);
      String newLandline = "";
      var resContent = res.content();

      // first we should check for new landline number
      if (resContent.contains('telephone does not exist')) {
        // changing numbers may be a series of changes
        do {
          phone = newLandline.isEmpty ? phone : newLandline;
          newLandline = await checkChangedLanline(code, phone);
          // telephone doesn't exist, wrong number or changed
          if (newLandline == null) {
            // wrong number
            return BillingResponse(
              countryCode: code,
              id: currentId,
              landline: phone,
              status: BillingStatus.wrongNumber,
            );
          }
          // number changed, request again with this number
          res = await _request(code, newLandline);
          resContent = res.content();
        } while (resContent.contains('telephone does not exist'));
      }

      if (resContent
          .contains("inquire about this account number in the website")) {
        return BillingResponse(
            countryCode: code,
            id: currentId,
            landline: phone,
            status: BillingStatus.pin,
            comment: resContent);
      }

      print(resContent);
      final resJson = res.json();
      List unPaid = resJson["Account"]["UnPaidInvoices"] ?? [];
      if (unPaid.isEmpty) {
        unPaid = resJson["Account"]["Invoices"] ?? [];
      }
      if (unPaid.length >= 2) {
        return BillingResponse(
          id: currentId,
          countryCode: code,
          landline: phone,
          status: BillingStatus.twoOrMoreBills,
          newLandlineNumber: newLandline,
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
          status: BillingStatus.noBills,
          newLandlineNumber: newLandline,
          comment: newLandline.isNotEmpty ? "number has been changed" : "",
          extras: resJson,
          customerCategory: resJson["Account"]["Customer"]["CategoryName"],
          deposit: resJson["Account"]["Customer"]["DepositValue"],
        );
      }
      if (unPaid.length == 1) {
        var invoice = unPaid.first;
        final dateJson = invoice["BillDateClient"];
        final month = dateJson["Month"],
            year = dateJson["Year"];
        bool isOverAcceptedDuration = checkInvoiceGracePeriod(year, month);
        if (isOverAcceptedDuration) {
          return BillingResponse(
            id: currentId,
            countryCode: code,
            landline: phone,
            status: BillingStatus.billMore55,
            newLandlineNumber: newLandline,
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
          status: BillingStatus.billLess55,
          newLandlineNumber: newLandline,
          comment: newLandline.isNotEmpty ? "number has been changed" : "",
          extras: resJson,
          customerCategory: resJson["Account"]["Customer"]["CategoryName"],
          deposit: resJson["Account"]["Customer"]["DepositValue"],
        );
      }
    } catch (e) {
      weToken = "";
      return BillingResponse(
        id: currentId,
        countryCode: code,
        landline: phone,
        status: BillingStatus.error,
        errorMessage: "error: " + e.toString(),
      );
    }
  }

  Future<void> _updateToken(String code, String phone) async {
    if (weToken.isNotEmpty) {
      return;
    }
    var res = await requests.Requests.get(
        "https://api-my.te.eg/api/user/generatetoken?channelId=WEB_APP");
    weToken = res.json()["body"]["jwt"];
  }

  Future<requests.Response> _request(String code, String phone) async {
    return requests.Requests.post(
      "https://billing.te.eg/api/Account/Inquiry",
      headers: {
        "token": weToken,
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
      },
      body: {
        "AreaCode": code.trim(),
        "PhoneNumber": phone.trim(),
        "InquiryBy": "telephone",
      },
      verify: false,
      timeoutSeconds: defaultTimeOutSeconds,
    );
  }

  Future<String> checkChangedLanline(String code, String phone) async {
    final res = await requests.Requests.post(
      "https://billing.te.eg/api/Account/GetChangedNo",
      headers: {
        "token": weToken,
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
      },
      body: {
        "AreaCode": code.trim(),
        "PhoneNumber": phone.trim(),
        // "InquiryBy": "telephone",
      },
      verify: false,
      timeoutSeconds: defaultTimeOutSeconds,
    );
    final content = res.content();
    if (content.contains("has not changed")) {
      return null;
    }
    return content.split(">")[1].split("<")[0].split("-")[1].trim();
  }

  bool checkInvoiceGracePeriod(int year, int month) {
    final billDate = DateTime.utc(year, month + 1);
    final now = DateTime.now();
    final duration = now.difference(billDate);
    return duration > Duration(days: gracePeriodDays);
  }
}
