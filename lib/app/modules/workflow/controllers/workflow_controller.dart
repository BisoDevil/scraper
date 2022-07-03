import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:scraper/app/modules/workflow/workflow_executor.dart';
import 'package:scraper/io/logger.dart';
import 'package:scraper/io/reader.dart';
import 'package:scraper/utils/preferences.dart';

class WorkflowController extends GetxController {
  File file;
  Map<String, dynamic> workflow;

  AppPreferences prefs;
  var log = "Logs of last run:".obs;
  var progress = 0.0.obs;
  var current = "".obs;
  final isRunning = false.obs;
  final currentJobIndex = (-1).obs;

  writeLogLine(String line) {
    print("AMMAR:: write log line: " + line);
    log(log.value + "\n$line");
    refineLog();
    RunLogger().newLine(line);
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

  void startWorkflow() async {
    WorkflowExector wfe;
    StreamSubscription pl, cl, jil;
    try {
      if (isRunning.value) {
        writeLogLine("can't start workflow while another one is not finished");
        return;
      }
      wfe = WorkflowExector(workflow, writeLog: writeLogLine);
      pl = wfe.progress.listen(progress);
      cl = wfe.current.listen(current);
      jil = wfe.currentJobIndex.listen((v) {currentJobIndex(v); update();});
      isRunning(true);
      await wfe.start();
    } catch (e, s) {
      print(s);
      RunLogger().newLine("start workflow error: $e");
      writeLogLine("start workflow error: $e");
    } finally {
      isRunning(false);
      pl?.cancel();
      cl?.cancel();
      jil?.cancel();
    }
  }

  Future<void> pickFile() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['wf', 'json'],
      type: FileType.custom,
    );

    if (result != null) {
      file = File(result.files.single.path);
      workflow = WorkFlowReader().readAsJson(result.files.single.path);
      update();
    } else {
      // User canceled the picker
    }
  }
}
