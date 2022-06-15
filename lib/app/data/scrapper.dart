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
  static final LandlineProvidersManager _instance =
      LandlineProvidersManager._internal();
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
    int trials = 1,
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

      // trials = 1 + trialsOnError
      trials += 1;
      
      //* Billing
      if (allowBilling) {
        for (int tryIndex = 0; tryIndex < trials; tryIndex++) {
          billingResponse = await BillingScrapper().scrape(llid, code, phone);
          if (billingResponse.status != BillingStatus.error) {
            break;
          }
        }
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

      //* We
      if (!reserved && allowWe) {
        print("SCAPPER:: scrape we");
        for (int tryIndex = 0; tryIndex < trials; tryIndex++) {
          weResponse = await WeScrapper().scrape(llid, code, phone);
          if (weResponse.status != WeStatus.error) {
            break;
          }
        }
        reserved = weResponse.status == WeStatus.reserved;
        ownerProvider = "we";
      }

      //* Orange
      if (!reserved && allowOrange) {
        print("SCAPPER:: scrape orange");
        for (int tryIndex = 0; tryIndex < trials; tryIndex++) {
          orangeResponse = await OrangeScrapper().scrape(llid, code, phone);
          if (orangeResponse.status != OrangeStatus.error) {
            break;
          }
        }
        reserved = orangeResponse.status == OrangeStatus.reserved;
        ownerProvider = "orange";
      }

      //* Etisalat
      if (!reserved && allowEtisalat) {
        print("SCAPPER:: scrape etisalat");
        for (int tryIndex = 0; tryIndex < trials; tryIndex++) {
          etisalatResponse = await EtisalatScrapper().scrape(llid, code, phone);
          if (etisalatResponse.status != EtisalatStatus.error) {
            break;
          }
        }
        reserved = etisalatResponse.status == EtisalatStatus.reserved;
        ownerProvider = "etisalat";
      }

      //* Vodafone
      if (!reserved && allowVodafone) {
        for (int tryIndex = 0; tryIndex < trials; tryIndex++) {
          print("SCAPPER:: scrape vodafone");
          vodafoneResponse = await VodafoneScrapper().scrape(llid, code, phone);
          if (vodafoneResponse.status != VodafoneStatus.error) {
            break;
          }
        }
        reserved = vodafoneResponse.status == VodafoneStatus.reserved;
        ownerProvider = "vodafone";
      }
      //* Vodafone2
      if (!reserved && allowVodafoneSecondStep) {
        for (int tryIndex = 0; tryIndex < trials; tryIndex++) {
          print("SCAPPER:: scrape vodafone2");
          vodafone2Response =
              await Vodafone2Scrapper().scrape(llid, code, phone);
          if (vodafone2Response.status != Vodafone2Status.error) {
            break;
          }
        }
        reserved = vodafone2Response.status == Vodafone2Status.reserved;
        ownerProvider = "vodafone2";
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
      print("SCRAPPER:: " + e.toString());
      return LandlineProvidersResponse(
        LandlineProvidersStatus.error,
        generalResponse: "Error: " + e.toString(),
      );
    }
  }
}
