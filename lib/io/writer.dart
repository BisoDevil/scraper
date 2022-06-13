import 'dart:io';

import 'package:scraper/app/data/billing.dart';

class Writer {
  static final Writer _instance = Writer._internal();

  factory Writer() {
    return _instance;
  }

  Writer._internal();

  writeBillingExcelSheet(
    List<BillingResponse> billingResponses, {
    String path,
  }) {
    path ??= "./billing " + _getFileNameFromCurrentTime() + ".csv";
    File xfile = File(path);
    if(!xfile.existsSync()) {
      xfile.createSync();
    }
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
    lines.add(headers.join(","));
    for (var billResponse in billingResponses) {
      final values = [
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
      lines.add(values.join(","));
    }
    xfile.writeAsStringSync(lines.join("\n"));
  }

  String _getFileNameFromCurrentTime() {
    final now = DateTime.now();
    return "${now.day}-${now.month}-${now.year} ${now.hour}_${now.minute}";
  }
}
