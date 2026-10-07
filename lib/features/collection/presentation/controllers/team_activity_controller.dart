import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/models/directory_user.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_directory_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_roles.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/team_activity_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/team_engagement.dart';

typedef TeamFeedLoader = Future<Result<TeamActivityFeed>> Function({
  required DateTime from,
  required DateTime to,
  String? collector,
});

/// The user directory (item 14); the picker takes its Collection members.
typedef TeamMembersLoader = Future<Result<List<DirectoryUser>>> Function();

/// Backs the Head's *Team Activity* tab (Collection TODO items 21–22): a
/// calendar of what the team uploaded, for everyone or for one collector.
///
/// One month is loaded at a time, for the month on screen and the picked
/// collector; the day list and the day dots come from that load. The Head
/// also collects, so their own tabs are untouched; this is a fifth one.
class TeamActivityController extends GetxController {
  TeamActivityController(
      {TeamFeedLoader? load,
      TeamMembersLoader? members,
      DateTime Function()? now})
      : _load = load ?? _fromRepository,
        _members = members ?? _membersFromDirectory,
        _now = now ?? DateTime.now;

  static TeamActivityController get instance => Get.find();

  final TeamFeedLoader _load;
  final TeamMembersLoader _members;
  final DateTime Function() _now;

  /// The picker: the Firestore `Users` whose Department is Collection, by
  /// name (decided 2026-09-25: only those, not CNTMST and not "whoever
  /// uploaded"). Keyed by username, which is what uploads are filed under.
  final collectors = <TeamCollector>[].obs;

  List<DirectoryUser> _department = const [];
  bool _departmentLoaded = false;

  /// The picked collector's code; null is everyone.
  final selectedCollector = RxnString();

  /// The first day of the month on screen.
  late final focusedMonth = Rx<DateTime>(_monthOf(_now()));
  late final selectedDay = Rx<DateTime>(_dayOf(_now()));

  final engagements = <TeamEngagement>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  /// When the feed on screen was loaded; null before the first load.
  final loadedAt = Rxn<DateTime>();

  int _generation = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  TeamCollector? get selected => selectedCollector.value == null
      ? null
      : collectors.firstWhereOrNull((c) => c.code == selectedCollector.value);

  /// "All collectors" or the picked collector's name.
  String get selectionLabel =>
      selected?.name ?? selectedCollector.value ?? 'All collectors';

  /// Engagements by day (local date, midnight), newest first within a day.
  Map<DateTime, List<TeamEngagement>> get byDay {
    final map = <DateTime, List<TeamEngagement>>{};
    for (final e in engagements) {
      final day = _parseDay(e.date);
      if (day == null) continue;
      map.putIfAbsent(day, () => []).add(e);
    }
    return map;
  }

  List<TeamEngagement> on(DateTime day) => byDay[_dayOf(day)] ?? const [];

  /// The entries for [day] in the shape the calendar's day list already
  /// renders (see `ActivityHistoryCard`): the history row plus the account
  /// and invoice it is about. `collectorName` is carried on the history row,
  /// so with everyone picked each card says who did it.
  List<Map<String, dynamic>> dayEntries(DateTime day) => [
        for (final e in on(day))
          {
            'history': CollectionHistoryModel(
              date: e.date,
              collectorName: e.collectorLabel,
              status: e.statusLabel,
              remarks: e.remarks.trim().isEmpty ? 'No remarks' : e.remarks,
              totalCollected: e.amount,
              bankName: e.bankName,
              checkNumber: e.referenceNo,
              purposeOfVisit: e.purposeOfVisit,
            ),
            'accountName': e.clientName.trim().isNotEmpty
                ? e.clientName
                : (e.clientCode.trim().isNotEmpty
                    ? e.clientCode
                    : (e.isDeposit
                        ? 'Bank deposit · ${e.bankName ?? ''}'.trim()
                        : '')),
            'invoiceId': e.documentId.trim().isEmpty ? null : e.documentId,
            'kind': e.kind,
            'collectorCode': e.collectorCode,
            'collectorName': e.collectorLabel,
            'key': e.key,
          },
      ];

  /// Sum collected on [day] (deposits are the collector's activity, so they
  /// are not summed; neither is a CWT pick-up, which carries no amount).
  double collectedOn(DateTime day) => on(day)
      .where((e) => !e.isDeposit)
      .fold(0.0, (sum, e) => sum + e.amount);

  Future<void> load() async {
    final generation = ++_generation;
    isLoading.value = true;
    error.value = null;
    if (!_departmentLoaded) await _loadDepartment();
    final month = focusedMonth.value;
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);
    final result =
        await _load(from: from, to: to, collector: selectedCollector.value);
    // A newer load (other month or collector) has started: drop this answer.
    if (generation != _generation) return;
    result.fold(
      onSuccess: (feed) {
        engagements.assignAll(feed.engagements);
        collectors.assignAll(pickerFor(_department, feed.collectors));
        loadedAt.value = _now();
      },
      onFailure: (message) {
        error.value = message;
        if (collectors.isEmpty) {
          collectors.assignAll(pickerFor(_department, const []));
        }
      },
    );
    isLoading.value = false;
  }

  Future<void> _loadDepartment() async {
    try {
      final result = await _members();
      if (result.isSuccess) {
        _department = result.value
            .where((u) =>
                u.inFirestore &&
                BCollectionRoles.isCollectionDepartment(u.department))
            .toList();
        _departmentLoaded = true;
      } else {
        logDebug('TeamActivityController: directory unavailable: ${result.error}');
      }
    } catch (e) {
      logDebug('TeamActivityController: directory unavailable: $e');
    }
  }

  /// Pure: the Collection department by name, keyed by what the backend
  /// knows each person as (username, else directory key). [uploaded] is the
  /// feed's own list; it only supplies a name the directory left blank, it
  /// adds nobody.
  static List<TeamCollector> pickerFor(
      List<DirectoryUser> department, List<TeamCollector> uploaded) {
    final uploadedNames = {
      for (final c in uploaded) c.code.trim().toLowerCase(): c.name,
    };
    final byCode = <String, TeamCollector>{};
    for (final u in department) {
      final code = u.collectorCode.trim();
      if (code.isEmpty) continue;
      final name = u.name.trim().isNotEmpty && u.name != u.key
          ? u.name
          : (uploadedNames[code.toLowerCase()] ?? u.name);
      byCode.putIfAbsent(
          code.toLowerCase(), () => TeamCollector(code: code, name: name));
    }
    return byCode.values.toList()
      ..sort((a, b) {
        final n = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return n != 0 ? n : a.code.compareTo(b.code);
      });
  }

  /// Everyone when [code] is null or blank.
  Future<void> selectCollector(String? code) {
    final next = (code ?? '').trim().isEmpty ? null : code!.trim();
    if (next == selectedCollector.value) return Future.value();
    selectedCollector.value = next;
    return load();
  }

  Future<void> showMonth(DateTime month) {
    final next = _monthOf(month);
    if (next == focusedMonth.value) return Future.value();
    focusedMonth.value = next;
    // Keep a selected day inside the month on screen.
    final day = selectedDay.value;
    if (day.year != next.year || day.month != next.month) {
      final today = _dayOf(_now());
      selectedDay.value = today.year == next.year && today.month == next.month
          ? today
          : next;
    }
    return load();
  }

  Future<void> stepMonth(int delta) {
    final m = focusedMonth.value;
    return showMonth(DateTime(m.year, m.month + delta, 1));
  }

  Future<void> selectDay(DateTime day) {
    final d = _dayOf(day);
    selectedDay.value = d;
    final m = focusedMonth.value;
    if (d.year != m.year || d.month != m.month) return showMonth(d);
    return Future.value();
  }

  Future<void> goToToday() => selectDay(_now());

  bool get isTodaySelected => selectedDay.value == _dayOf(_now());

  static DateTime _monthOf(DateTime d) => DateTime(d.year, d.month, 1);
  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// `yyyy-MM-dd` (a longer stamp's first 10 characters are accepted).
  static DateTime? _parseDay(String value) {
    final s = value.trim();
    if (s.length < 10) return null;
    final y = int.tryParse(s.substring(0, 4));
    final m = int.tryParse(s.substring(5, 7));
    final d = int.tryParse(s.substring(8, 10));
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  static Future<Result<List<DirectoryUser>>> _membersFromDirectory() =>
      UserDirectoryRepository.instance.load();

  static Future<Result<TeamActivityFeed>> _fromRepository({
    required DateTime from,
    required DateTime to,
    String? collector,
  }) =>
      TeamActivityRepository.instance
          .load(from: from, to: to, collector: collector);
}
