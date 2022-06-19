import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scraper/app/data/billing.dart';
import 'package:scraper/app/data/etisalat.dart';
import 'package:scraper/app/data/orange.dart';
import 'package:scraper/app/data/vodafone.dart';
import 'package:scraper/app/data/we.dart';

enum LandlineProvidersStatus { excludedNumber, reserved, notReserved, error }

class LandlineProvidersResponse {
  String generalResponse;
  LandlineProvidersStatus status;
  BillingResponse billingResponse;
  VodafoneResponse vodafoneResponse;
  EtisalatResponse etisalatResponse;
  OrangeResponse orangeResponse;
  WeResponse weResponse;

  LandlineProvidersResponse(
    this.status, {
    this.generalResponse,
    this.billingResponse,
    this.vodafoneResponse,
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
  void Function(String) log;

  Future<LandlineProvidersResponse> validateNumber({
    @required String llid,
    @required String code,
    @required String phone,
    @required bool allowVodafone,
    @required bool allowEtisalat,
    @required bool allowOrange,
    @required bool allowBilling,
    @required bool allowWe,
    int trials = 1,
    int waitAfterErrorMinMillis = 0,
    int waitAfterErrorMaxMillis = 0,
    bool useConcurrency = false,
    void Function(String) writeLog,
  }) async {
    log = writeLog;
    try {
// var dir = Directory(Platform.resolvedExecutable).parent.path;
      // logFile = File("$dir/log_${DateFormat("y-M-d H-m").format(DateTime.now())}.txt");
      BillingResponse billingResponse;
      VodafoneResponse vodafoneResponse;
      EtisalatResponse etisalatResponse;
      OrangeResponse orangeResponse;
      WeResponse weResponse;
      // trials = 1 + trialsOnError
      trials += 1;

      //* Billing
      if (allowBilling) {
        for (int tryIndex = 0; tryIndex < trials; tryIndex++) {
          log("SCAPPER:: scrape billing $tryIndex");
          billingResponse = await BillingScrapper().scrape(llid, code, phone);
          if (billingResponse.status != BillingStatus.error) {
            break;
          }
          await waitAfterError(waitAfterErrorMinMillis, waitAfterErrorMaxMillis);
        }
        if (billingResponse.status == BillingStatus.wrongNumber || billingResponse.status == BillingStatus.billMore55 || billingResponse.status == BillingStatus.twoOrMoreBills) {
          return LandlineProvidersResponse(
            LandlineProvidersStatus.excludedNumber,
            billingResponse: billingResponse,
            generalResponse: "billing excludes this customer",
          );
        }
      }
      bool reserved = false;
      String ownerProvider = "";

      //* We
      if (!reserved && allowWe) {
        for (int tryIndex = 0; tryIndex < trials; tryIndex++) {
          log("SCAPPER:: scrape we $tryIndex");
          weResponse = await WeScrapper().scrape(llid, code, phone);
          if (weResponse.status != WeStatus.error) {
            break;
          }
          await waitAfterError(waitAfterErrorMinMillis, waitAfterErrorMaxMillis);
        }
        reserved = weResponse.status == WeStatus.reserved;
        ownerProvider = "we";
      }

      //* Etisalat
      if (!reserved && allowEtisalat) {
        for (int tryIndex = 0; tryIndex < trials; tryIndex++) {
          log("SCAPPER:: scrape etisalat $tryIndex");
          etisalatResponse = await EtisalatScrapper().scrape(llid, code, phone);
          if (etisalatResponse.status != EtisalatStatus.error) {
            break;
          }
          await waitAfterError(waitAfterErrorMinMillis, waitAfterErrorMaxMillis);
        }
        reserved = etisalatResponse.status == EtisalatStatus.reserved;
        ownerProvider = "etisalat";
      }

      //* Orange
      if (!reserved && allowOrange) {
        for (int tryIndex = 0; tryIndex < trials; tryIndex++) {
          log("SCAPPER:: scrape orange $tryIndex");
          orangeResponse = await OrangeScrapper().scrape(llid, code, phone);
          if (orangeResponse.status != OrangeStatus.error) {
            break;
          }
          await waitAfterError(waitAfterErrorMinMillis, waitAfterErrorMaxMillis);
        }
        reserved = orangeResponse.status == OrangeStatus.reserved;
        ownerProvider = "orange";
      }

      //* Vodafone
      if (!reserved && allowVodafone) {
        for (int tryIndex = 0; tryIndex < trials; tryIndex++) {
          log("SCAPPER:: scrape vodafone $tryIndex");
          vodafoneResponse =
              await VodafoneScrapper().scrape(llid, code, phone);
          if (vodafoneResponse.status != VodafoneStatus.error) {
            break;
          }
          await waitAfterError(waitAfterErrorMinMillis, waitAfterErrorMaxMillis);
        }
        reserved = vodafoneResponse.status == VodafoneStatus.reserved;
        ownerProvider = "vodafone";
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
        weResponse: weResponse,
      );
    } catch (e) {
      log("SCRAPPER:: " + e.toString());
      return LandlineProvidersResponse(
        LandlineProvidersStatus.error,
        generalResponse: "Error: " + e.toString(),
      );
    }
  }

  Future<void> waitAfterError(int min, int max) async {
    final waitTime = min + Random().nextInt(1 + max - min);
    log("will wait after error for $waitTime ms");
    return Future.delayed(Duration(milliseconds: waitTime));
  }
}
