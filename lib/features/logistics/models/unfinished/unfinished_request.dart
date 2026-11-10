import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';

/// One Logistics request that has not reached a final status yet, in the
/// shape the daily unfinished-requests reminder and its list need
/// (docs/application/UNFINISHED_REQUESTS_REMINDER_PLAN.md).
///
/// [source] is the request's own model (StandardDeliveryModel, PullOutModel,
/// PickUpModel or AirSeaModel), kept so a tap can open the request's usual
/// screen.
class UnfinishedRequest {
  const UnfinishedRequest({
    required this.type,
    required this.id,
    required this.client,
    required this.status,
    required this.createdAt,
    this.createdBy = '',
    this.driver = '',
    this.helper = '',
    this.source,
  });

  final FormCategoryType type;
  final String id;
  final String client;
  final String status;

  /// As stored (ISO text); '' when unknown.
  final String createdAt;

  /// Initials of the user who raised it.
  final String createdBy;

  /// Initials of the assigned crew; '' when none.
  final String driver;
  final String helper;

  final Object? source;
}

/// The unfinished requests one user should hear about, counted by type.
class UnfinishedSummary {
  const UnfinishedSummary(this.requests);

  static const UnfinishedSummary empty = UnfinishedSummary([]);

  final List<UnfinishedRequest> requests;

  int get total => requests.length;

  /// Count per type, in the reminder's display order, without zeros.
  Map<FormCategoryType, int> get byType {
    final counts = <FormCategoryType, int>{};
    for (final type in displayOrder) {
      final n = requests.where((r) => r.type == type).length;
      if (n > 0) counts[type] = n;
    }
    return counts;
  }

  /// Notification title: "5 unfinished requests".
  String get title =>
      '$total unfinished request${total == 1 ? '' : 's'}';

  /// Notification body: "Standard Delivery 3 · Pull Out 2. Tap to see them."
  String get body {
    final parts = byType.entries
        .map((e) => '${labelFor(e.key)} ${e.value}')
        .join(' · ');
    return '$parts. Tap to see ${total == 1 ? 'it' : 'them'}.';
  }

  /// The order types are listed in, here and on the list screen.
  static const List<FormCategoryType> displayOrder = [
    FormCategoryType.standardDelivery,
    FormCategoryType.hotlineDirect,
    FormCategoryType.pullOutReturn,
    FormCategoryType.stockReceive,
    FormCategoryType.pickUp,
    FormCategoryType.airSea,
    FormCategoryType.airSeaHd,
  ];

  /// Short user-facing name ("Pull Out", not "Pull Out / Return").
  static String labelFor(FormCategoryType type) {
    switch (type) {
      case FormCategoryType.pullOutReturn:
        return 'Pull Out';
      default:
        return type.categoryName;
    }
  }
}
