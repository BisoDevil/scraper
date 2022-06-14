import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get_connect.dart';
import 'package:intl/intl.dart';
import 'package:scraper/app/data/billing.dart';
import 'package:scraper/app/data/etisalat.dart';
import 'package:scraper/app/data/orange.dart';
import 'package:scraper/app/data/vodafone.dart';
import 'package:scraper/app/data/vodafone2.dart';
import 'package:scraper/app/data/we.dart';

enum LandlineProvidersStatus { wrongNumber, reserved, notReserved, error }

class LandlineProvidersResponse {
  String generalResponse;
  LandlineProvidersStatus status;
  BillingResponse billingResponse;
  VodafoneResponse vodafoneResponse;
  Vodafone2Response vodafone2Response;
  EtisalatResponse etisalatResponse;
  OrangeResponse orangeResponse;
  WeResponse weResponse;

  LandlineProvidersResponse(
    this.status, {
    this.generalResponse,
    this.billingResponse,
    this.vodafoneResponse,
    this.vodafone2Response,
    this.etisalatResponse,
    this.orangeResponse,
    this.weResponse,
  });
}

class LandlineProvidersManager {
  // File logFile;
  static final LandlineProvidersManager _instance = LandlineProvidersManager._internal();
  factory LandlineProvidersManager() {
    return _instance;
  }
  LandlineProvidersManager._internal();


  Future<LandlineProvidersResponse> validateNumber({
    @required String llid,
    @required String code,
    @required String phone,
    @required bool allowVodafone,
    @required bool allowEtisalat,
    @required bool allowVodafoneSecondStep,
    @required bool allowOrange,
    @required bool allowBilling,
    @required bool allowWe,
    bool useConcurrency = false,
  }) async {
    try {
// var dir = Directory(Platform.resolvedExecutable).parent.path;
      // logFile = File("$dir/log_${DateFormat("y-M-d H-m").format(DateTime.now())}.txt");
      BillingResponse billingResponse;
      VodafoneResponse vodafoneResponse;
      Vodafone2Response vodafone2Response;
      EtisalatResponse etisalatResponse;
      OrangeResponse orangeResponse;
      WeResponse weResponse;
      if (allowBilling) {
        billingResponse = await BillingScrapper().scrape(llid, code, phone);
        if (billingResponse.status == BillingStatus.wrongNumber) {
          return LandlineProvidersResponse(
            LandlineProvidersStatus.wrongNumber,
            billingResponse: billingResponse,
            generalResponse: "wrong number",
          );
        }
      }
      bool reserved = false;
      String ownerProvider = "";
      if (allowEtisalat) {
        etisalatResponse = await EtisalatScrapper().scrape(llid, code, phone);
        reserved = etisalatResponse.status == EtisalatStatus.reserved;
        ownerProvider = "etisalat";
      } else if (!reserved && allowOrange) {
        orangeResponse = await OrangeScrapper().scrape(llid, code, phone);
        reserved = orangeResponse.status == OrangeStatus.reserved;
        ownerProvider = "orange";
      } else if (!reserved && allowVodafone) {
        vodafoneResponse = await VodafoneScrapper().scrape(llid, code, phone);
        reserved = vodafoneResponse.status == VodafoneStatus.reserved;
        ownerProvider = "vodafone";
      } else if (!reserved && allowVodafoneSecondStep) {
        vodafone2Response = await Vodafone2Scrapper().scrape(llid, code, phone);
        reserved = vodafone2Response.status == Vodafone2Status.reserved;
        ownerProvider = "vodafone2";
      } else if (!reserved && allowWe) {
        weResponse = await WeScrapper().scrape(llid, code, phone);
        reserved = weResponse.status == WeStatus.reserved;
        ownerProvider = "we";
      }
      return LandlineProvidersResponse(
        reserved
            ? LandlineProvidersStatus.reserved
            : LandlineProvidersStatus.notReserved,
        generalResponse:
            reserved ? "reserved in " + ownerProvider : "not reserved",
        billingResponse: billingResponse,
        etisalatResponse: etisalatResponse,
        orangeResponse: orangeResponse,
        vodafoneResponse: vodafoneResponse,
        vodafone2Response: vodafone2Response,
        weResponse: weResponse,
      );
    } catch (e) {
      return LandlineProvidersResponse(
        LandlineProvidersStatus.error,
        generalResponse: "Error: " + e.toString(),
      );
    }
  }

  // writeLog(String line) async {
  //   if (!await logFile.exists()) {
  //     logFile.createSync();
  //   }

  //   String content = logFile.readAsStringSync();
  //   content += "\n$line";
  //   logFile.writeAsStringSync(content);
  // }
}
