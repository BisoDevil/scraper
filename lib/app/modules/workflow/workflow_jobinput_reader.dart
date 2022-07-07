import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class JobInputReader {
  static WorkflowInput read(String input, String type) {
    switch (type) {
      case "billing":
        return readBilling(input);
      case "numbers":
        return readNumbers(input);
      case "general":
        return readGeneral(input);
      case "raw":
        return readRow(input);
      default:
        throw ("type $type is not valid. only accept billing, numbers or general");
    }
  }

  static WorkflowInput readRow(String input) {
    final numbers = input.split(';');
    return WorkflowInput(numbers: numbers);
  }

  static WorkflowInput readNumbers(String path) {
    final file = File(path);
    var content = file.readAsStringSync();
    final phoneText = content.replaceAll(",", "-");
    var ls = LineSplitter();
    final lines = ls.convert(phoneText.trim());
    return WorkflowInput(numbers: lines);
  }

  static WorkflowInput readBilling(String path) {
    final file = File(path);
    var content = file.readAsStringSync();
    var ls = LineSplitter();
    final lines = ls.convert(content.trim());
    final headers = lines[0].split(",").map((e) => e.trim()).toList();
    Map<String, dynamic> params = {};
    final numbers = List<String>.filled(lines.length - 1, null);
    for (var i = 1; i < lines.length; i++) {
      final currentLine = lines[i];
      final values = currentLine.split(",").map((e) => e.trim()).toList();
      // id, countryCode, landline, TEBills, Comment, error message, LastBillAmount, CustomerCategory, billExistenceDays, DEPOSIT, CC, LL
      // 0      1             2        3        4           5             6                 7               8                9     10  11
      final number = "${values[1]}-${values[2]}";
      final id = values[0];
      params[id] = {
        "number": number,
        "id": id,
        "code": values[1],
        "landline": values[2],
        "billing": values[3],
        "comment": values[4],
        "errorMessage": values[5],
        "lastBillAmount": values[6],
        "customerCategory": values[7],
        "billExistenceDays": values[8],
        "DEPOSIT": values[9],
        "CC": values[10],
        "LL": values[11],
        "status": values[3] == 'wrongNumber' ||
                values[3] == 'pin' ||
                values[3] == 'twoOrMoreBills' ||
                values[3] == 'billMoreGracePeriod'
            ? "excludedNumber"
            : "notReserved",
      };
      numbers[i - 1] = id;
    }
    return WorkflowInput(numbers: numbers, params: params);
  }

  static WorkflowInput readGeneral(String path) {
    final file = File(path);
    var content = file.readAsStringSync();
    var ls = LineSplitter();
    final lines = ls.convert(content.trim());
    final headers = lines[0].split(",").map((e) => e.trim()).toList();
    Map<String, dynamic> params = {};
    final numbers = List<String>.filled(lines.length - 1, null);
    for (var i = 1; i < lines.length; i++) {
      final currentLine = lines[i];
      final values = currentLine.split(",").map((e) => e.trim()).toList();
      //ID	countryCode	landline	comment	billing	      we	        etisalat	       orange	        vodafone	         we error	etisalat error	orange error	vodafone error	Status
      // 0      1          2        3        4           5             6                 7               8                9           10            11             12           13
      final number = "${values[1]}-${values[2]}";
      final id = values[0];
      params[id] = {
        "number": number,
        "id": id,
        "code": values[1],
        "landline": values[2],
        "Comment": values[3],
        "billing": values[4],
        "we": values[5],
        "etisalat": values[6],
        "orange": values[7],
        "vodafone": values[8],
        "we_error": values[9],
        "etisalat_error": values[10],
        "orange_error": values[11],
        "vodafone_error": values[12],
        "status": values[13],
      };
      numbers[i - 1] = id;
    }
    return WorkflowInput(numbers: numbers, params: params);
  }
}

class WorkflowInput {
  List<String> numbers;
  Map<String, dynamic> params;
  WorkflowInput({@required this.numbers, this.params}) {
    if (params == null) {
      params = {};
      for (var i = 0; i < numbers.length; i++) {
        final number = numbers[i];
        final id = (i + 1).toString();
        numbers[i] = id;
        params[id] = {
          "id": id,
          "landline": number,
          "number": number,
        };
      }
    }
  }
}
