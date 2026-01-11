extension DatetimeExtension on DateTime {
  /// Formats the DateTime to a readable string.
  String toReadableString() {
    final date =
        '$year-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
    final time =
        '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
