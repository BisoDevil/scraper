import 'dart:convert';
import 'dart:io';

class RunLogger {
  File _xfile;
  static final _instance = RunLogger._internal();

  factory RunLogger() {
    return _instance;
  }

  /// change writing to a new path
  void directTo(String path) {
    _xfile = File(path);
    if (!_xfile.existsSync()) {
      _xfile.createSync();
    }
  }

  void newLine(String line, {swallowError = true}) {
    try {
      _xfile.writeAsStringSync(line + "\n", mode: FileMode.append);
    } catch (e) {
      print("Can't write log line: " + e.toString());
    }
  }

  RunLogger._internal() {
    _xfile = _DummyFile();
  }
}

class _DummyFile implements File {
  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    return this;
  }

  @override
  void writeAsStringSync(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false}) {
    return;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
