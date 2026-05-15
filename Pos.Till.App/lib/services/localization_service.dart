import '../state/device_state.dart';

/// Per-surface product/category name resolution.
///
/// Each output surface (cashier UI, kitchen ticket, receipt, customer
/// display) has its own [NameLang] preference. The till's UI chrome stays
/// English in v1 — only product *names* are bilingual.
///
/// Rules:
/// * `en` → always the primary [name]
/// * `vi` → [nameLocalized] if non-empty, else fall back to [name]
/// * `both` → primary on top, alt underneath, joined by `\n` (callers
///   render the second line smaller for receipt/display surfaces)
class LocalizationService {
  const LocalizationService();

  /// Returns a single rendered string. For `both` the result contains a
  /// `\n` separator so receipts/kitchen tickets can stack lines while the
  /// customer-display can pick the split apart and render the second line
  /// at a smaller size.
  String resolve({
    required String name,
    String? nameLocalized,
    required NameLang lang,
  }) {
    final String alt = (nameLocalized ?? '').trim();
    switch (lang) {
      case NameLang.en:
        return name;
      case NameLang.vi:
        return alt.isEmpty ? name : alt;
      case NameLang.both:
        return alt.isEmpty ? name : '$name\n$alt';
    }
  }

  /// Splits a `both`-rendered string back into (primary, alt). Useful for
  /// the customer display which wants to size the two lines differently.
  ({String primary, String? alt}) splitBoth(String rendered) {
    final int nl = rendered.indexOf('\n');
    if (nl < 0) return (primary: rendered, alt: null);
    return (
      primary: rendered.substring(0, nl),
      alt: rendered.substring(nl + 1),
    );
  }
}
