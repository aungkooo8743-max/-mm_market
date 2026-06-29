class DateParser {
  const DateParser._();

  static DateTime? fromValue(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      final dynamic dynamicValue = value;
      return dynamicValue.toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}
