class EnumParser {
  const EnumParser._();

  static T fromName<T extends Enum>({required List<T> values, required String? name, required T fallback}) {
    if (name == null || name.isEmpty) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
