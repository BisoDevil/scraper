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
      "billExistenceDays",
      "DEPOSIT",
      "CC",
      "LL",
    ];
    if (!xfile.existsSync()) {
      xfile.createSync();
      lines.add("\n");
      lines.add(headers.join(","));
    }
    for (var billResponse in billingResponses) {
      var billExistenceDays = "";
      if (billResponse.extras?.containsKey("billExistenceDays") ?? false) {
        billExistenceDays = billResponse.extras['billExistenceDays'];
      }
      var values = [
        billResponse.id,
        billResponse.countryCode,
        billResponse.landline,
        billResponse.status.value,
        (billResponse.comment ?? " ").toString(),
        (billResponse.errorMessage ?? " ").toString(),
        (billResponse.lastBillAmount ?? " ").toString(),
        (billResponse.customerCategory ?? " ").toString(),
        billExistenceDays,
        (billResponse.deposit ?? " ").toString(),
        billResponse.countryCode,
        billResponse.newLandlineNumber ?? billResponse.landline,
      ];
      values = values
          .map((e) => e
              .replaceAll(",", ".")
              .replaceAll("\r", ". ")
              .replaceAll("\n", ""))
          .toList();
      lines.add(values.join(","));
    }
    final fmode = shouldContinue ? FileMode.writeOnlyAppend : FileMode.write;
    xfile.writeAsStringSync(lines.join("\n") + "\n", mode: fmode);
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
      "comment",
      "billing",
      "we",
      "etisalat",
      "orange",
      "vodafone",
      "we error",
      "etisalat error",
      "orange error",
      "vodafone error",
      "Status",
    ];
    if (!xfile.existsSync()) {
      xfile.createSync();
      lines.add("\n");
      lines.add(headers.join(","));
    }
    for (var response in responses) {
      
      final validID = response.firstID;
      final validCode = response.firstCountryCode ?? "";
      final validPhone = response.firstPhone ?? "";
      final validComment = response.comment ?? "";
      var values = [
        validID,
        validCode,
        validPhone,
        validComment,
        response.billingResponse?.status?.value ?? "null",
        response.weResponse?.status?.value ?? "null",
        response.etisalatResponse?.status?.value ?? "null",
        response.orangeResponse?.status?.value ?? "null",
        response.vodafoneResponse?.status?.value ?? "null",
        response.weResponse?.errorMessage ?? "",
        response.etisalatResponse?.errorMessage ?? "",
        response.orangeResponse?.errorMessage ?? "",
        response.vodafoneResponse?.errorMessage ?? "",
        response.status.name,
      ];
      values = values
          .map((e) => (e ?? "")
              .replaceAll(",", ".")
              .replaceAll("\r", ". ")
              .replaceAll("\n", ""))
          .toList();
      lines.add(values.join(","));
    }
    final fmode = shouldContinue ? FileMode.writeOnlyAppend : FileMode.write;
    xfile.writeAsStringSync(lines.join("\n") + "\n", mode: fmode);
  }
}
