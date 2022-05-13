import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:get/get.dart';

import 'package:scraper/app/data/scrapper.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class HomeController extends GetxController {
  String phoneText = "";
  var log = "".obs;
  File file, xFile;
  var progress = 0.0.obs;
  var current = "".obs;
  bool allowVodafone = true,
      allowWe = true,
      allowOrange = true,
      allowEtisalat = true,
      allowVodafoneSecondStep = true,
      allowArdy = true;

  void startWeb() async {
    log.value = "";
    progress.value = 0;
    current.value = "";
    var dir = Directory(Platform.resolvedExecutable).parent.path;
    xFile = File("$dir/file_${DateFormat.MMMEd().format(DateTime.now())}.csv");
    writeLog("Start crawling......");
    writeLine("Code,Phone,Mobile,Name,Result");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var username = prefs.getString("vodafone_username") ?? "ASK";
    var password = prefs.getString("vodafone_password") ?? "5e625052";
    var etisalatUsername = prefs.getString("etisalat_username") ?? "ISP1087";
    var etisalatPassword =
        prefs.getString("etisalat_password") ?? "maryam00000";
    var sfid = prefs.getString("vodafone_sid") ?? "A94004088";
    var ls = LineSplitter();
    var lines = ls.convert(phoneText.trim());
    var i = 0;
    var scrapper = Scrapper();
    for (var line in lines) {
      var _data = line.split("-");
      var code = _data.first;
      var phone = _data[1];
      var mobile = _data.asMap().containsKey(2) ? _data[2] : "";
      var name = _data.asMap().containsKey(3) ? _data[3] : "";
      var result = await scrapper.validateNumber(
          code: code.startsWith("0") ? code : "0$code",
          phone: phone,
          username: username,
          password: password,
          etisalatPassword: etisalatPassword,
          etisalatUsername: etisalatUsername,
          allowEtisalat: allowEtisalat,
          allowVodafone: allowVodafone,
          allowOrange: allowOrange,
          allowVodafoneSecondStep: allowVodafoneSecondStep,
          allowWe: allowWe,
          weArdy: allowArdy,
          sfid: sfid);
      i++;
      progress.value = i / lines.length;
      current.value = "$i/${lines.length}";
      writeLog("[!] 0$line is $result");
      writeLine("0$code,$phone,$mobile,$name,$result");
    }

    progress.value = 1;
    writeLog("Finished ......");
  }

  writeLine(String line) async {
    if (!await xFile.exists()) {
      xFile.createSync();
    }

    String content = xFile.readAsStringSync();
    content += "\n$line";
    xFile.writeAsStringSync(content);
  }

  writeLog(String log) {
    this.log.value += "\n$log";
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
      update();
    } else {
      // User canceled the picker
    }
  }
}
