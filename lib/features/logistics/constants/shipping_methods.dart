/// Canonical mode-of-shipment values shared by every request form that asks
/// for one (Standard Delivery, Hotline Direct, Air / Sea / Land).
///
/// The backend validates `ShippingMethod` against exactly these strings, so
/// keep the casing and add new modes here rather than in a form.
abstract final class ShippingMethods {
  static const String land = 'Land';
  static const String air = 'Air';
  static const String sea = 'Sea';

  /// Display/order used by the dropdowns.
  static const List<String> all = [land, air, sea];
}
