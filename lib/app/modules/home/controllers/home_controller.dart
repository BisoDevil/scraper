import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:get/get.dart';
import 'package:scraper/app/data/etisalat.dart';

import 'package:scraper/app/data/scrapper.dart';
import 'package:pool/pool.dart';
import 'package:scraper/app/data/vodafone.dart';
import 'package:scraper/app/data/vodafone2.dart';
import 'package:scraper/io/writer.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class HomeController extends GetxController {
  static const maxLogCharLength = 4000;

  /// each batchCapacity, we will write result in the excel sheet and make a checkpoint
  static const batchCapacity = 1000;
  String phoneText = "";
  var log = "Logs of last run:".obs;
  File file, logFile;
  var progress = 0.0.obs;
  var current = "".obs;
  bool allowVodafone = true,
      allowWe = true,
      allowOrange = true,
      allowEtisalat = true,
      allowVodafoneSecondStep = true,
      allowArdy = true;

  List<LandlineProvidersResponse> responses = [];
  DateTime startTime;
  DateTime endTime;
  String billingCSVPath;
  String generalCSVPath;
  void startWeb() async {
    log.value = "";
    progress.value = 0;
    current.value = "";
    startTime = DateTime.now();
    var dir = Directory(Platform.resolvedExecutable).parent.path;
    billingCSVPath =
        "$dir/billing_${DateFormat("y-M-d H-m").format(DateTime.now())}.csv";
    generalCSVPath =
        "$dir/general_${DateFormat("y-M-d H-m").format(DateTime.now())}.csv";
    logFile =
        File("$dir/log_${DateFormat("y-M-d H-m").format(DateTime.now())}.txt");
    writeLogLine("Start crawling......");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var username = prefs.getString("vodafone_username") ?? "ASK";
    var password = prefs.getString("vodafone_password") ?? "5e625052";
    var etisalatUsername = prefs.getString("etisalat_username") ?? "ISP1087";
    var etisalatPassword =
        prefs.getString("etisalat_password") ?? "maryam00000";
    var sfid = prefs.getString("vodafone_sid") ?? "A94004088";
    EtisalatScrapper().init(etisalatUsername, etisalatPassword);
    VodafoneScrapper().init(username, password, sfid);
    Vodafone2Scrapper().init(username, password, sfid);
    var maxPooling = prefs.getInt("max_pooling") ?? 20;
    var ls = LineSplitter();
    var lines = ls.convert(phoneText.trim());
    var i = 0;
    // List<LandlineProvidersResponse> responses = [];
    final pool = Pool(maxPooling, timeout: Duration(seconds: 100));

    for (var iline = 0; iline < lines.length; iline++) {
      final line = lines[iline];
      final _data = line.split("-");
      final code = _data.first;
      final phone = _data[1];
      final id = (iline + 1).toString();
      pool.withResource(() async {
        final response = await LandlineProvidersManager().validateNumber(
          llid: id,
          code: code.startsWith("0") ? code : "0$code",
          phone: phone,
          allowEtisalat: allowEtisalat,
          allowVodafone: allowVodafone,
          allowOrange: allowOrange,
          allowVodafoneSecondStep: allowVodafoneSecondStep,
          allowWe: allowWe,
          allowBilling: allowArdy,
        );
        i++;
        progress.value = i / lines.length;
        current.value = "$i/${lines.length}";
        writeLogLine(
            "[!] 0$line is ${response.status.toString()} (${response.generalResponse})");
        responses.add(response);
        if (i == lines.length) {
          endTime = DateTime.now();
          writeLogLine(
              "Finished...... (Takes ${endTime.difference(startTime).toString()})");
          writeBatch();
        }
        if ((i - 1) % batchCapacity == 0) {
          // write each 1000 billingResponses in batches in the excel sheet
          writeBatch();
          refineLog();
        }
      });
    }
  }

  writeBatch() {
    if (allowArdy) {
      final list = responses.map((e) => e.billingResponse).toList();
      Writer().writeBillingExcelSheet(
        list,
        path: billingCSVPath,
        shouldContinue: true,
      );
    }
    if ([
      allowEtisalat,
      allowOrange,
      allowVodafone,
      allowVodafoneSecondStep,
      allowWe
    ].any((element) => element)) {
      // write responses of providers
      Writer().writeGeneralExcelSheet(responses,
          path: generalCSVPath, shouldContinue: true);
    }
    responses.clear();
  }

  writeLogLine(String line) {
    log.value += "\n$line";
    // logFile.writeAsStringSync(logFile.readAsStringSync() + "\n$line");
  }

  Future<void> pickFile() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['csv'],
      type: FileType.custom,
    );

    if (result != null) {
      file = File(result.files.single.path);

      var content = await file.readAsString();

      phoneText = content.replaceAll(",", "-");

      var ls = LineSplitter();
      var numLines = ls.convert(phoneText.trim()).length;
      current("0/" + numLines.toString());
      progress(0.0);
      update();
    } else {
      // User canceled the picker
    }
  }

  void refineLog() {
    if (log.value.length > maxLogCharLength) {
      log.value = log.value.substring(log.value.length - maxLogCharLength);
    }
  }
}
