import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/utils/role_resolver.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_ids.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/crew_assignment.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/unfinished/unfinished_request.dart';

/// Which Logistics requests are unfinished, and which of them a user should
/// hear about (docs/application/UNFINISHED_REQUESTS_REMINDER_PLAN.md).
///
/// Pure: no GetX, no storage. Statuses compare trimmed and case-insensitive,
/// like the DAOs' status maps.
abstract final class BUnfinishedRequests {
  /// Statuses that end a request, per type. Everything else is unfinished.
  static final Map<FormCategoryType, Set<String>> finalStatuses = {
    FormCategoryType.standardDelivery: _lower(_deliveryFinal),
    FormCategoryType.hotlineDirect: _lower(_deliveryFinal),
    FormCategoryType.pullOutReturn: _lower(_pullOutFinal),
    FormCategoryType.stockReceive: _lower(_pullOutFinal),
    FormCategoryType.pickUp:
        _lower(const [BTexts.statusReceived, BTexts.statusCancelled]),
    FormCategoryType.airSea: _lower(_airSeaFinal),
    FormCategoryType.airSeaHd: _lower(_airSeaFinal),
  };

  static const _deliveryFinal = [
    BTexts.statusDoneDelivery,
    BTexts.statusCancelled,
  ];
  static const _pullOutFinal = [
    BTexts.statusTakenOut,
    'Picked-up',
    BTexts.statusCancelled,
  ];

  /// Received and Drop Off end the main leg; the Air / Sea list treats them
  /// as done too (no remarks on long press).
  static const _airSeaFinal = [
    BTexts.statusReceived,
    BTexts.statusDropOff,
    BTexts.statusProvincialDelivered,
    BTexts.statusCancelled,
  ];

  /// Which role moves a request on from each unfinished status. Matches the
  /// lists' own status → role maps. Courier means the assigned crew only.
  static final Map<FormCategoryType, Map<String, String>> _actingRole = {
    FormCategoryType.standardDelivery: _lowerKeys(_deliveryRoles),
    FormCategoryType.hotlineDirect: _lowerKeys(_deliveryRoles),
    FormCategoryType.pullOutReturn: _lowerKeys(const {
      BTexts.statusNewRequest: BTexts.roleRelease,
      BTexts.statusForPullOut: BTexts.roleCourier,
      BTexts.statusInTransit: BTexts.roleCourier,
    }),
    FormCategoryType.stockReceive: _lowerKeys(const {
      BTexts.statusNewRequest: BTexts.roleCourier,
      BTexts.statusInTransit: BTexts.roleCourier,
    }),
    FormCategoryType.pickUp: _lowerKeys(const {
      BTexts.statusNewRequest: BTexts.roleRelease,
      BTexts.statusGettingSuppliesReady: BTexts.roleRelease,
      BTexts.statusItemPrepared: BTexts.roleRelease,
      BTexts.statusItemPacked: BTexts.roleRelease,
    }),
    FormCategoryType.airSea: _lowerKeys(_airSeaRoles),
    FormCategoryType.airSeaHd: _lowerKeys(_airSeaRoles),
  };

  static const _deliveryRoles = {
    BTexts.statusNewRequest: BTexts.roleRelease,
    BTexts.statusGettingSuppliesReady: BTexts.roleRelease,
    BTexts.statusBackLoad: BTexts.roleRelease,
    BTexts.statusItemPrepared: BTexts.roleCourier,
    BTexts.statusForDelivery: BTexts.roleCourier,
  };

  static const _airSeaRoles = {
    BTexts.statusNewRequest: BTexts.roleRelease,
    BTexts.statusGettingSuppliesReady: BTexts.roleRelease,
    BTexts.statusItemPacked: BTexts.roleRelease,
    BTexts.statusEndorsedToGuard: BTexts.roleRelease,
    BTexts.statusForDispatch: BTexts.roleCourier,
    BTexts.statusDispatch: BTexts.roleCourier,
    BTexts.statusProvincialPickUp: BTexts.roleProvincial,
    BTexts.statusProvincialInTransit: BTexts.roleProvincial,
  };

  static Set<String> _lower(List<String> statuses) =>
      statuses.map(_key).toSet();

  static Map<String, String> _lowerKeys(Map<String, String> map) =>
      {for (final e in map.entries) _key(e.key): e.value};

  static String _key(String s) => s.trim().toLowerCase();

  static bool _same(String a, String b) {
    final left = a.trim();
    return left.isNotEmpty && left.toLowerCase() == b.trim().toLowerCase();
  }

  /// True when [status] ends a request of [type]. A blank status is treated
  /// as finished: there is nothing to tell anyone about it.
  static bool isFinished(FormCategoryType type, String status) {
    final s = _key(status);
    if (s.isEmpty) return true;
    return finalStatuses[type]?.contains(s) ?? true;
  }

  /// The role that moves [request] on, or null when the status is unknown.
  static String? actingRole(UnfinishedRequest request) =>
      _actingRole[request.type]?[_key(request.status)];

  /// Whether a user with [roles] and [initial] should hear about [request].
  ///
  /// - Admin and Viewer: every unfinished request.
  /// - Request: the ones they raised.
  /// - Release / Provincial: the ones waiting on that role.
  /// - Courier: the ones waiting on a courier where they are the crew.
  static bool isVisibleTo(
    UnfinishedRequest request, {
    required List<String> roles,
    required String initial,
  }) {
    if (roles.contains(BTexts.roleAdmin) ||
        roles.contains(BTexts.roleViewer)) {
      return true;
    }
    if (roles.contains(BTexts.roleRequest) &&
        _same(request.createdBy, initial)) {
      return true;
    }
    final acting = actingRole(request);
    if (acting == null) return false;
    if (acting == BTexts.roleCourier) {
      return roles.contains(BTexts.roleCourier) &&
          CrewAssignment.isCrew(
              driver: request.driver,
              helper: request.helper,
              userInitial: initial);
    }
    return roles.contains(acting);
  }

  /// The unfinished requests in [all] that the user with [roleField] (the
  /// comma-separated role list) and [initial] should hear about, oldest
  /// first. Each request appears once, whatever roles match it.
  static UnfinishedSummary summarize(
    Iterable<UnfinishedRequest> all, {
    required String roleField,
    required String initial,
  }) {
    final roles = RoleResolver.parseRoles(roleField);
    final mine = all
        .where((r) => !isFinished(r.type, r.status))
        .where((r) => isVisibleTo(r, roles: roles, initial: initial))
        .toList()
      ..sort(_oldestFirst);
    return UnfinishedSummary(List.unmodifiable(mine));
  }

  static int _oldestFirst(UnfinishedRequest a, UnfinishedRequest b) {
    final da = DateTime.tryParse(a.createdAt.trim());
    final db = DateTime.tryParse(b.createdAt.trim());
    if (da != null && db != null) return da.compareTo(db);
    if (da != null) return -1;
    if (db != null) return 1;
    return a.id.compareTo(b.id);
  }

  // --------------------------------------------------------------------------
  // From the request models
  // --------------------------------------------------------------------------

  static UnfinishedRequest fromStandardDelivery(StandardDeliveryModel m) =>
      UnfinishedRequest(
        type: m.formCategoryID.trim() == FormCategoryIds.hotlineDirect
            ? FormCategoryType.hotlineDirect
            : FormCategoryType.standardDelivery,
        id: m.id,
        client: m.client.name,
        status: m.status,
        createdAt: m.createdAt,
        createdBy: m.createdBy,
        driver: m.deliveredBy,
        helper: m.helper,
        source: m,
      );

  static UnfinishedRequest fromPullOut(PullOutModel m) => UnfinishedRequest(
        type: m.formCategoryId.trim() == FormCategoryIds.stockReceive
            ? FormCategoryType.stockReceive
            : FormCategoryType.pullOutReturn,
        id: m.id,
        client: m.client.name,
        status: m.requestStatus,
        createdAt: m.createdAt,
        createdBy: m.createdBy,
        driver: m.driver,
        helper: m.helper,
        source: m,
      );

  static UnfinishedRequest fromPickUp(PickUpModel m) => UnfinishedRequest(
        type: FormCategoryType.pickUp,
        id: m.id,
        client: m.client.name,
        status: m.status,
        createdAt: m.createdAt,
        createdBy: m.createdBy,
        source: m,
      );

  static UnfinishedRequest fromAirSea(AirSeaModel m) => UnfinishedRequest(
        type: m.formCategoryID.trim() == FormCategoryIds.airSeaHd
            ? FormCategoryType.airSeaHd
            : FormCategoryType.airSea,
        id: m.id,
        client: m.client.name,
        status: m.status,
        createdAt: m.createdAt,
        createdBy: m.createdBy,
        driver: m.driver,
        helper: m.helper,
        source: m,
      );
}
