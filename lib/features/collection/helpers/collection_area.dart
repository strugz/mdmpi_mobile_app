/// Area (territory) rules for the Collection bucket.
///
/// Client codes carry their territory as a prefix (`NLN-115`, `ncr-205`, …).
/// The SAP import adds NCR and a long tail of other prefixes (VET, CSAT, …), so
/// the filter needs a case-insensitive match and an "Others" bucket for every
/// code whose prefix is not one of the named territories.
class BCollectionArea {
  BCollectionArea._();

  /// Sentinel selected by the "Others" card.
  static const String others = 'OTHERS';

  /// Territories with their own card in Filter by Area, in display order.
  static const Map<String, String> names = {
    'NLN': 'North Luzon',
    'SLN': 'South Luzon',
    'CLN': 'Central Luzon',
    'NCR': 'NCR',
    'VIS': 'Visayas',
    'MIN': 'Mindanao',
    'RAD': 'Medical Imaging',
    others: 'Others',
  };

  /// Prefixes that are NOT "Others".
  static final Set<String> knownPrefixes =
      names.keys.where((k) => k != others).toSet();

  /// The territory prefix of a client / BP code, uppercased (`ncr-205` → `NCR`).
  static String prefixOf(String code) {
    final trimmed = code.trim().toUpperCase();
    final dash = trimmed.indexOf('-');
    return dash < 0 ? trimmed : trimmed.substring(0, dash);
  }

  /// Whether [code] belongs to [selected]. An empty selection matches everything.
  static bool matches(String code, String selected) {
    final area = selected.trim().toUpperCase();
    if (area.isEmpty) return true;
    final prefix = prefixOf(code);
    if (area == others) return !knownPrefixes.contains(prefix);
    return prefix == area;
  }

  /// Display name for a selected area code (falls back to the code itself).
  static String labelFor(String selected) =>
      names[selected.trim().toUpperCase()] ?? selected;
}
