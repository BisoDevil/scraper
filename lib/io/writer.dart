import 'dart:io';

import 'package:scraper/app/data/billing.dart';
import 'package:scraper/app/data/scrapper.dart';
import 'package:scraper/utils/paths.dart';

class Writer {
  static final Writer _instance = Writer._internal();

  factory Writer() {
    return _instance;
  }

  Writer._internal();

  void writeBillingExcelSheet(
    List<BillingResponse> billingResponses, {
    String path,
    bool shouldContinue = false,
  }) {
    path ??= "./billing " + getFileNameFromCurrentTime() + ".csv";
    File xfile = File(path);
    List<String> lines = [];
    final headers = [
      "ID",
      "country code",
      "landline",
      "TEBills",
      "Comment",
      "error message",
      "LastBillAmount",
      "CustomerCategory",
      "DEPOSIT",
      "CC",
      "LL",
    ];
    String oldContent = "";
    if (!xfile.existsSync()) {
      xfile.createSync();
      lines.add("\n");
      lines.add(headers.join(","));
    } else if (shouldContinue) {
      oldContent = xfile.readAsStringSync() + "\n";
    }
    for (var billResponse in billingResponses) {
      var values = [
        billResponse.id,
        billResponse.countryCode,
        billResponse.landline,
        billResponse.status.toString(),
        (billResponse.comment ?? " ").toString(),
        (billResponse.errorMessage ?? " ").toString(),
        (billResponse.lastBillAmount ?? " ").toString(),
        (billResponse.customerCategory ?? " ").toString(),
        (billResponse.deposit ?? " ").toString(),
        (billResponse.countryCode ?? " ").toString(),
        (billResponse.newLandlineNumber ?? " ").toString(),
      ];
      values = values
          .map((e) => e
              .replaceAll(",", ".")
              .replaceAll("\r", ". ")
              .replaceAll("\n", ""))
          .toList();
      lines.add(values.join(","));
    }
    xfile.writeAsStringSync(oldContent + lines.join("\n"));
  }

  void writeGeneralExcelSheet(
    List<LandlineProvidersResponse> responses, {
    String path,
    bool shouldContinue = false,
  }) {
    path ??= "./general " + getFileNameFromCurrentTime() + ".csv";
    File xfile = File(path);
    List<String> lines = [];
    final headers = [
      "ID",
      "country code",
      "landline",
      "Status",
      "comment",
      "orange",
      "we",
      "vodafone",
      "vodafone2",
      "etisalat",
    ];
    String oldContent = "";
    if (!xfile.existsSync()) {
      xfile.createSync();
      lines.add("\n");
      lines.add(headers.join(","));
    } else if (shouldContinue) {
      oldContent = xfile.readAsStringSync() + "\n";
    }
    for (var response in responses) {
      // TODO: make base class and extend in all classes
      final validID = response.billingResponse?.id ??
          response.etisalatResponse?.id ??
          response.orangeResponse?.id ??
          response.vodafoneResponse?.id ??
          response.vodafone2Response?.id ??
          response.weResponse?.id;
      final validCode = response.billingResponse?.countryCode ??
          response.etisalatResponse?.countryCode ??
          response.orangeResponse?.countryCode ??
          response.vodafoneResponse?.countryCode ??
          response.vodafone2Response?.countryCode ??
          response.weResponse?.countryCode;
      final validPhone = response.billingResponse?.landline ??
          response.etisalatResponse?.landline ??
          response.orangeResponse?.landline ??
          response.vodafoneResponse?.landline ??
          response.vodafone2Response?.landline ??
          response.weResponse?.landline;
      final validComment = (response.billingResponse?.comment ?? "") +
          (response.etisalatResponse?.comment ?? "") +
          (response.orangeResponse?.comment ?? "") +
          (response.vodafoneResponse?.comment ?? "") +
          (response.vodafone2Response?.comment ?? "") +
          (response.weResponse?.comment ?? "");
      var values = [
        validID,
        validCode,
        validPhone,
        response.status.name,
        validComment,
        response.orangeResponse?.status?.name ?? "null",
        response.weResponse?.status?.name ?? "null",
        response.vodafoneResponse?.status?.name ?? "null",
        response.vodafone2Response?.status?.name ?? "null",
        response.etisalatResponse?.status?.name ?? "null",
      ];
      values = values
          .map((e) => e
              .replaceAll(",", ".")
              .replaceAll("\r", ". ")
              .replaceAll("\n", ""))
          .toList();
      lines.add(values.join(","));
    }
    xfile.writeAsStringSync(oldContent + lines.join("\n"));
  }
}
