import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:get/get.dart';

import 'package:scraper/app/data/scrapper.dart';
import 'package:scraper/app/modules/workflow/workflow_executor.dart';
import 'package:scraper/io/logger.dart';
import 'package:scraper/utils/preferences.dart';

import 'package:intl/intl.dart';

enum InputType {numbers, billing, general, raw}


class HomeController extends GetxController {
  AppPreferences prefs;
  String phoneText = "";
  var singleLandline = "".obs;
  var log = "Logs of last run:".obs;
  String input;
  var inputType = InputType.numbers.obs;
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
  void startWeb() async {
    WorkflowExector wfe;
    StreamSubscription pl, cl, jil;
    try {
      if (isRunning.value) {
        writeLogLine("can't start workflow while another one is not finished");
        return;
      }
      var dir = Directory(Platform.resolvedExecutable).parent.path;
      final billingCSVPath =
          "$dir/billing_${DateFormat("y-M-d H-m").format(DateTime.now())}.csv";
      final generalCSVPath =
          "$dir/general_${DateFormat("y-M-d H-m").format(DateTime.now())}.csv";
      final logPath =
          "$dir/log_${DateFormat("y-M-d H-m").format(DateTime.now())}.txt";
      wfe = WorkflowExector({
        "jobs": [
          {
            "name": "home defaut workflow",
            "input": input,
            "inputType": inputType.value.name,
            "providers": [
              ...(allowEtisalat ? ['etisalat'] : []),
              ...(allowVodafone ? ['vodafone'] : []),
              ...(allowOrange ? ['orange'] : []),
              ...(allowWe ? ['we'] : []),
              ...(allowArdy ? ['billing'] : []),
            ],
            "filters": {"variables": [], "summation": "or"},
            "filterStrategy": "conserve",
            "output_billing": billingCSVPath,
            "output_general": generalCSVPath,
            "output_log": logPath,
          },
        ],
      }, writeLog: writeLogLine);
      pl = wfe.progress.listen(progress);
      cl = wfe.current.listen(current);
      isRunning(true);
      await wfe.start();
    } catch (e, s) {
      print(s);
      RunLogger().newLine("start default home workflow error: $e");
      writeLogLine("start default workflow error: $e");
    } finally {
      isRunning(false);
      pl?.cancel();
      cl?.cancel();
      jil?.cancel();
    }
  }

  writeLogLine(String line) {
    print("AMMAR:: write log line: " + line);
    log(log.value + "\n$line");
    refineLog();
    RunLogger().newLine(line);
  }

  Future<void> pickFile() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['csv'],
      type: FileType.custom,
    );

    if (result != null) {
      file = File(result.files.single.path);

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
    prefs = await AppPreferences.getInstance();
    super.onInit();
  }

  void refineLog() {
    if (log.value.length > prefs.logMaxCharCount) {
      log.value = log.value.substring(log.value.length - prefs.logMaxCharCount);
    }
  }

  void testInputFile() {
    input = file.path;
    inputType(InputType.numbers);
    startWeb();
  }

  void testSingleLine() {
    input = singleLandline.value;
    inputType(InputType.raw);
    startWeb();
  }
}
