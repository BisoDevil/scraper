import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:get/get.dart';
import 'package:scraper/app/data/billing.dart';
import 'package:scraper/app/data/etisalat.dart';

import 'package:scraper/app/data/scrapper.dart';
import 'package:pool/pool.dart';
import 'package:scraper/app/data/vodafone.dart';
import 'package:scraper/io/logger.dart';
import 'package:scraper/io/writer.dart';
import 'package:scraper/utils/preferences.dart';

import 'package:intl/intl.dart';

class HomeController extends GetxController {
  AppPreferences prefs;
  String phoneText = "";
  var singleLandline = "".obs;
  var log = "Logs of last run:".obs;
  File file;
  var progress = 0.0.obs;
  var current = "".obs;
  bool allowVodafone = false,
      allowWe = false,
      allowOrange = false,
      allowEtisalat = false,
      allowArdy = false;
  final isRunning = false.obs;

  List<LandlineProvidersResponse> responses = [];
  DateTime startTime;
  DateTime endTime;
  String billingCSVPath;
  String generalCSVPath;
  void startWeb() async {
    try {
      isRunning(true);
      log.value = "";
      progress.value = 0;
      current.value = "";
      startTime = DateTime.now();
      var dir = Directory(Platform.resolvedExecutable).parent.path;
      billingCSVPath =
          "$dir/billing_${DateFormat("y-M-d H-m").format(DateTime.now())}.csv";
      generalCSVPath =
          "$dir/general_${DateFormat("y-M-d H-m").format(DateTime.now())}.csv";
      RunLogger().directTo("$dir/log_${DateFormat("y-M-d H-m").format(DateTime.now())}.txt");
      writeLogLine("Start crawling......");
      prefs = await AppPreferences.getInstance();
      if (allowArdy) {
        BillingScrapper().init(gracePeriodDays: prefs.gracePeriodDays);
      }
      if (allowEtisalat) {
        await EtisalatScrapper()
            .init(prefs.etisalatUsername, prefs.etisalatPassword);
      }
      if (allowVodafone) {
        await VodafoneScrapper().init(
            prefs.vodafoneUsername, prefs.vodafonePassword, prefs.vodafoneSID);
      }
      var ls = LineSplitter();
      var lines = ls.convert(phoneText.trim());
      var i = 0;
      // final pool = Pool(prefs.maxPooling, timeout: Duration(days: 2));
      final batchPooler = Pool(prefs.maxPooling, timeout: Duration(days: 2));
      for (var iline = 0; iline < lines.length; iline++) {
        final line = lines[iline];
        final _data = line.split("-");
        final code = _data.first;
        final phone = _data[1];
        final id = (iline + 1).toString();
        final resource = await batchPooler.request();
        LandlineProvidersManager()
            .validateNumber(
          llid: id,
          code: code.startsWith("0") ? code : "0$code",
          phone: phone,
          allowEtisalat: allowEtisalat,
          allowVodafone: allowVodafone,
          allowOrange: allowOrange,
          allowWe: allowWe,
          allowBilling: allowArdy,
          trials: prefs.numTrialsOnError,
          waitAfterErrorMaxMillis: prefs.maxWaitAfterErrorMills,
          waitAfterErrorMinMillis: prefs.minWaitAfterErrorMills,
          writeLog: writeLogLine,
        )
            .then((response) {
          resource.release();
          i++;
          progress.value = i / lines.length;
          current.value = "$i/${lines.length}";
          writeLogLine(
              "[!] 0$line is ${response.status.name} (${response.generalResponse})");
          responses.add(response);
          if (i >= lines.length) {
            endTime = DateTime.now();
            writeLogLine(
                "Finished...... (Takes ${endTime.difference(startTime).toString()})");
            writeBatch();
            isRunning(false);
          } else if ((i - 1) % prefs.batchCapacity == 0) {
            // write each 1000 billingResponses in batches in the excel sheet
            writeBatch();
            refineLog();
          }
        }).catchError((e) {
          print("Error in handling validate number response: ${e.toString()}");
          writeLogLine(
              "error in handling validate number response. ${e.toString()}");
        });
      }
    } catch (e) {
      print("Error in starting crawling: ${e.toString()}");
      writeLogLine("error in starting crawling. ${e.toString()}");
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
    if ([allowEtisalat, allowOrange, allowVodafone, allowWe]
        .any((element) => element)) {
      // write responses of providers
      Writer().writeGeneralExcelSheet(responses,
          path: generalCSVPath, shouldContinue: true);
    }
    responses.clear();
  }

  writeLogLine(String line) {
    print("AMMAR:: write log line: " + line);
    log(log.value + "\n$line");
    // TODO: take care of thread-safe
    RunLogger().newLine(line);
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
      writeLogLine("files read successfully with $numLines numbers");
      current("0/" + numLines.toString());
      progress(0.0);
      update();
    } else {
      // User canceled the picker
    }
  }

  @override
  void onInit() async {
    // TODO: implement onInit
    prefs = await AppPreferences.getInstance();
    super.onInit();
  }

  void refineLog() {
    if (log.value.length > prefs.logMaxCharCount) {
      log.value = log.value.substring(log.value.length - prefs.logMaxCharCount);
    }
  }

  void testSingleLine() {
    phoneText = singleLandline.value;
    startWeb();
  }

  void updateSingleLine(String v) {
    singleLandline(v);
  }
}
