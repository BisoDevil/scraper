// read billing, number, general

// read workflow

import 'dart:convert';

import 'dart:io';

class WorkFlowReader {
  static final _instance = WorkFlowReader._internal();
  factory WorkFlowReader() {
    return _instance;
  }
  WorkFlowReader._internal();


  Map<String, dynamic> readAsJson(String path) {
    return json.decode(File(path).readAsStringSync());
  }
}
