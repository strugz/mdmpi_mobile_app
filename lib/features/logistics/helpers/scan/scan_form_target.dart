import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/utils/role_resolver.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/delivery_document_type.dart';

/// Which request form a scanned document opens (scan first, decision
/// 2026-10-15): the document's type gives the forms it belongs to, the
/// user's role narrows that to the forms they may create.
class ScanFormTarget {
  ScanFormTarget._();

  /// The app's form category for [form]. "Air/Sea" in the document list is
  /// the Air / Sea / Land HD form.
  static FormCategoryType categoryFor(DeliveryRequestForm form) =>
      switch (form) {
        DeliveryRequestForm.standardDelivery => FormCategoryType.standardDelivery,
        DeliveryRequestForm.airSeaLand => FormCategoryType.airSea,
        DeliveryRequestForm.airSea => FormCategoryType.airSeaHd,
        DeliveryRequestForm.hotlineDirect => FormCategoryType.hotlineDirect,
        DeliveryRequestForm.pullOut => FormCategoryType.pullOutReturn,
      };

  /// The scan form for an open form category, or null for categories no
  /// document belongs to (Pick Up, Stock Receive).
  static DeliveryRequestForm? formFor(FormCategoryType? category) =>
      switch (category) {
        FormCategoryType.standardDelivery => DeliveryRequestForm.standardDelivery,
        FormCategoryType.airSea => DeliveryRequestForm.airSeaLand,
        FormCategoryType.airSeaHd => DeliveryRequestForm.airSea,
        FormCategoryType.hotlineDirect => DeliveryRequestForm.hotlineDirect,
        FormCategoryType.pullOutReturn => DeliveryRequestForm.pullOut,
        _ => null,
      };

  /// Whether [role] may create a request on [form]. Same rule as the
  /// Request screen's + button: Air / Sea / Land HD needs the HD role,
  /// Hotline Direct the Request or Courier role, the rest the Request role.
  static bool canCreate(DeliveryRequestForm form, String role) =>
      switch (form) {
        DeliveryRequestForm.airSea =>
          RoleResolver.hasRole(RoleResolver.parseRoles(role), BTexts.roleHd),
        DeliveryRequestForm.hotlineDirect => role.contains(BTexts.roleRequest) ||
            role.contains(BTexts.roleCourier),
        _ => role.contains(BTexts.roleRequest),
      };

  /// The forms a scanned [type] can open for [role], in the app's order.
  /// An unreadable title offers every form the user may create.
  static List<DeliveryRequestForm> choicesFor(
      DeliveryDocumentType type, String role) {
    return [
      for (final form in DeliveryRequestForm.values)
        if ((type == DeliveryDocumentType.unknown || type.forms.contains(form)) &&
            canCreate(form, role))
          form,
    ];
  }

  /// Whether a scan can open any form for [role] (shows the Request screen's
  /// scan button).
  static bool canScanAny(String role) =>
      DeliveryRequestForm.values.any((f) => canCreate(f, role));

  /// Whether [form] saves scanned items. All five do since Air/Sea gained
  /// items (plan LOGISTICS_AIR_SEA_ITEMS_PLAN.md); kept as the one place to
  /// change should a form ever take none.
  static bool takesItems(DeliveryRequestForm form) => true;
}
