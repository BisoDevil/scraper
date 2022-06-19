List<DateTime> ticks = [];
String tick() {
  ticks.add(DateTime.now());
  return ticks.length.toString();
}


Duration tock() {
  final endTime = DateTime.now();
  final startTime = ticks.removeLast();
  return endTime.difference(startTime);
}

String tockStr({String title = ""}) {
  final d = tock();
  return title + d.toString() + " (" + d.inMilliseconds.toString() + " millis)";
}