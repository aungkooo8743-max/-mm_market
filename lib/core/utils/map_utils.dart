class MapUtils {
  const MapUtils._();

  static String stringValue(Map<String, dynamic> map, String key, {String fallback = ''}) =>
      map[key] as String? ?? fallback;
  static int intValue(Map<String, dynamic> map, String key, {int fallback = 0}) =>
      (map[key] as num?)?.toInt() ?? fallback;
  static double doubleValue(Map<String, dynamic> map, String key, {double fallback = 0}) =>
      (map[key] as num?)?.toDouble() ?? fallback;
  static bool boolValue(Map<String, dynamic> map, String key, {bool fallback = false}) =>
      map[key] as bool? ?? fallback;
  static List<String> stringListValue(Map<String, dynamic> map, String key) =>
      List<String>.from(map[key] as List? ?? const []);
}
