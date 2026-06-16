class DateFormatter {
  /// Formats a Unix timestamp (in seconds) to a standard YYYY-MM-DD string
  static String formatTimestamp(int timestampSeconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
