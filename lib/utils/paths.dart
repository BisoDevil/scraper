String getFileNameFromCurrentTime() {
  final now = DateTime.now();
  return "${now.day}-${now.month}-${now.year} ${now.hour}_${now.minute}";
}
