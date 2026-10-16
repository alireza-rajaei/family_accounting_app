/// Extracts a membership number embedded in user name fields.
class MembershipNumberParser {
  static final RegExp _trailingNumber = RegExp(
    r'^(.*?)[\s\-]*([0-9۰-۹٠-٩]+)\s*$',
  );
  static final RegExp _leadingNumber = RegExp(
    r'^\s*([0-9۰-۹٠-٩]+)[\s\-]*(.+)$',
  );

  /// Strips a trailing digit sequence from [value].
  /// Leaves the value unchanged when the whole string is digits.
  static ({String name, String? number}) stripTrailing(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return (name: trimmed, number: null);
    final match = _trailingNumber.firstMatch(trimmed);
    if (match == null) return (name: trimmed, number: null);
    final namePart = match.group(1)!.trim();
    final number = match.group(2)!;
    if (namePart.isEmpty) return (name: trimmed, number: null);
    return (name: namePart, number: number);
  }

  /// Strips a leading digit sequence from [value].
  static ({String name, String? number}) stripLeading(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return (name: trimmed, number: null);
    final match = _leadingNumber.firstMatch(trimmed);
    if (match == null) return (name: trimmed, number: null);
    return (name: match.group(2)!.trim(), number: match.group(1)!);
  }

  /// Pulls a membership number from names.
  /// Prefers trailing digits (end of last/first name), then leading digits
  /// (front of first/last name). If [existingMembership] is set, names stay.
  static ({String firstName, String lastName, String? membershipNumber})
  extractFromNames({
    required String firstName,
    required String lastName,
    String? existingMembership,
  }) {
    final existing = existingMembership?.trim();
    if (existing != null && existing.isNotEmpty) {
      return (
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        membershipNumber: existing,
      );
    }

    final fromLastTrailing = stripTrailing(lastName);
    if (fromLastTrailing.number != null) {
      return (
        firstName: firstName.trim(),
        lastName: fromLastTrailing.name,
        membershipNumber: fromLastTrailing.number,
      );
    }

    final fromFirstTrailing = stripTrailing(firstName);
    if (fromFirstTrailing.number != null) {
      return (
        firstName: fromFirstTrailing.name,
        lastName: lastName.trim(),
        membershipNumber: fromFirstTrailing.number,
      );
    }

    final fromFirstLeading = stripLeading(firstName);
    if (fromFirstLeading.number != null) {
      return (
        firstName: fromFirstLeading.name,
        lastName: lastName.trim(),
        membershipNumber: fromFirstLeading.number,
      );
    }

    final fromLastLeading = stripLeading(lastName);
    if (fromLastLeading.number != null) {
      return (
        firstName: firstName.trim(),
        lastName: fromLastLeading.name,
        membershipNumber: fromLastLeading.number,
      );
    }

    return (
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      membershipNumber: null,
    );
  }
}
