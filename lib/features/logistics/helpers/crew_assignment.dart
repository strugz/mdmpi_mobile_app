import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// Who may run the courier steps (Dispatch / Drop Off) of a Standard Delivery
/// or Hotline Direct request.
///
/// The rule, decided 2026-09-10: once a request reaches `Item Prepared` the
/// courier actions belong to the assigned crew — the **driver or the helper**.
/// A user whose only operating role is Courier must not even see another
/// crew's `Item Prepared` / `For Delivery` requests; users who also hold a
/// back-office role (Release, Admin) keep full visibility but still get the
/// view/reassign modal rather than the courier actions on requests they are
/// not crew of.
///
/// Every gate (list filter, tap routing, action button, status update) asks
/// this one class so the answer cannot drift between surfaces.
abstract final class CrewAssignment {
  /// Case-insensitive, whitespace-tolerant equality that never matches empty
  /// values — otherwise an unassigned helper slot (`''`) would "match" a user
  /// whose initial is missing.
  static bool _same(String a, String b) {
    final left = a.trim();
    if (left.isEmpty) return false;
    return left.toLowerCase() == b.trim().toLowerCase();
  }

  /// True when [userInitial] is the request's driver or helper.
  static bool isCrew({
    required String driver,
    required String helper,
    required String userInitial,
  }) {
    if (userInitial.trim().isEmpty) return false;
    return _same(driver, userInitial) || _same(helper, userInitial);
  }

  /// Statuses whose courier actions are reserved for the assigned crew.
  static bool isCrewOnlyStatus(String status) =>
      status == BTexts.statusItemPrepared ||
      status == BTexts.statusForDelivery;

  /// Courier is the user's only *operating* role. Viewer is read-only and
  /// does not widen what a courier may act on, so it is ignored here.
  static bool isCourierOnly(Iterable<String> roles) {
    final operating = roles
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty && r != BTexts.roleViewer)
        .toSet();
    return operating.length == 1 && operating.contains(BTexts.roleCourier);
  }

  /// Whether [userInitial] may run the courier action for [request] in its
  /// current status: always true before `Item Prepared`, crew-only afterwards.
  static bool canOperate(
    StandardDeliveryModel request, {
    required String userInitial,
  }) {
    if (!isCrewOnlyStatus(request.status)) return true;
    return isCrew(
      driver: request.deliveredBy,
      helper: request.helper,
      userInitial: userInitial,
    );
  }

  /// "BPT" or "BPT / JDC" — for the "assigned to" note shown to non-crew.
  static String describeCrew(StandardDeliveryModel request) {
    final parts = [request.deliveredBy.trim(), request.helper.trim()]
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.join(' / ');
  }
}
