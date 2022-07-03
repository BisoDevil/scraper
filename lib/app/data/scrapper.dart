import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scraper/app/data/billing.dart';
import 'package:scraper/app/data/common.dart';
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

  List<GScrapperResponse<GStatus>> get responses => [billingResponse, weResponse, etisalatResponse, orangeResponse, vodafoneResponse];

  String get firstID {
    String res;
    for (var ele in responses) {
      res ??= ele?.id;
    }
    return res;
  }
  String get firstCountryCode {
    String res;
    for (var ele in responses) {
      res ??= ele?.countryCode;
    }
    return res;
  }
  String get firstPhone {
    String res;
    for (var ele in responses) {
      res ??= ele?.landline;
    }
    return res;
  }
  String get comment {
    String res = "";
    for (var ele in responses) {
      res += (ele?.comment ?? "").isNotEmpty ? "<${ele.name}> ${ele.comment} </${ele.name}>" : "";
    }
    return res;
  }
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
    trials += 1;
    try {
// var dir = Directory(Platform.resolvedExecutable).parent.path;
      // logFile = File("$dir/log_${DateFormat("y-M-d H-m").format(DateTime.now())}.txt");
      List<GScrapperResponse<GStatus>> responsesList = [null, null, null, null, null];
      final allowList = [
        allowBilling,
        allowWe,
        allowEtisalat,
        allowOrange,
        allowVodafone
      ];
      List<GScrapper> scrappers = [
        BillingScrapper(),
        WeScrapper(),
        EtisalatScrapper(),
        OrangeScrapper(),
        VodafoneScrapper()
      ];

      var reserved = false;
      var ownerProvider = "";
      for (var i = 0; i < scrappers.length; i++) {
        if (!allowList[i]) continue;
        final scrapper = scrappers[i];
        GScrapperResponse<GStatus> currentResponse;
        for (int tryIndex = 0; tryIndex < trials; tryIndex++) {
          log("SCAPPER:: <$llid @($code$phone) scrape $scrapper $tryIndex");
          currentResponse = await scrapper.scrape(llid, code, phone);
          log("SCAPPER:: $llid scrape $scrapper $tryIndex returned with ${currentResponse.status.value}");
          if (currentResponse.status == BillingStatus.wrongNumber() ||
              currentResponse.status == BillingStatus.billMoreGracePeriod() ||
              currentResponse.status == BillingStatus.twoOrMoreBills() ||
              currentResponse.status == BillingStatus.pin()) {
            return LandlineProvidersResponse(
              LandlineProvidersStatus.excludedNumber,
              billingResponse: currentResponse,
              generalResponse: "billing excludes this customer",
            );
          }
          if (currentResponse.status != GStatus.error()) {
            break;
          }
          log("SCAPPER:: $llid scrape $scrapper $tryIndex returned error ${currentResponse.errorMessage}");
          await waitAfterError(
              waitAfterErrorMinMillis, waitAfterErrorMaxMillis);
        }
        reserved = currentResponse.status == GStatus.reserved();
        ownerProvider = scrapper.toString();
        responsesList[i] = currentResponse;
        if(reserved) break;
      }

      return LandlineProvidersResponse(
        reserved
            ? LandlineProvidersStatus.reserved
            : LandlineProvidersStatus.notReserved,
        generalResponse:
            reserved ? "reserved in " + ownerProvider : "not reserved",
        billingResponse: responsesList[0],
        weResponse: responsesList[1],
        etisalatResponse: responsesList[2],
        orangeResponse: responsesList[3],
        vodafoneResponse: responsesList[4],
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
