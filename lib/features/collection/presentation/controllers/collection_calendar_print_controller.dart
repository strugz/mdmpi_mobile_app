import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_calendar_print_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/data/services/report_export_service.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Loads one month of the printout for [collector].
typedef CalendarPdfLoader = Future<Result<Uint8List>> Function(
    {required String collector, required DateTime month, String? notedBy});

/// Shares the PDF; Success(false) when the sheet was dismissed.
typedef CalendarPdfSharer = Future<Result<bool>> Function(Uint8List bytes,
    {required String fileName});

/// Calendar → Print: fetches the collector's month as the Collection
/// Calendar PDF (made on MDMPI.App) and opens the share sheet, from which
/// they print it or send it for reimbursement. "Noted by" is their Head from
/// Settings → My Head.
class CollectionCalendarPrintController extends GetxController {
  CollectionCalendarPrintController({
    CalendarPdfLoader? load,
    CalendarPdfSharer? share,
    String Function()? collectorCode,
    String Function()? headName,
  })  : _load = load ?? _loadFromRepository,
        _share = share ?? _shareWithExporter,
        _collectorCode = collectorCode ?? _defaultCode,
        _headName = headName ?? _defaultHead;

  static CollectionCalendarPrintController get instance => Get.find();

  final CalendarPdfLoader _load;
  final CalendarPdfSharer _share;
  final String Function() _collectorCode;
  final String Function() _headName;

  /// True while a printout is loading; the button shows a spinner.
  final RxBool isBusy = false.obs;

  static String fileNameFor(String collector, DateTime month) =>
      'Collection-Calendar-${collector.trim()}-'
      '${CollectionCalendarPrintRepository.monthKey(month)}.pdf';

  /// Fetches and shares [month]'s printout; a second tap while busy is ignored.
  /// Returns the failure message, or null when shared or dismissed.
  Future<String?> printMonth(DateTime month) async {
    if (isBusy.value) return null;
    isBusy.value = true;
    try {
      final code = _collectorCode();
      final head = _headName().trim();
      final pdf = await _load(
          collector: code, month: month, notedBy: head.isEmpty ? null : head);
      final error = await pdf.fold<Future<String?>>(
        onSuccess: (bytes) async =>
            (await _share(bytes, fileName: fileNameFor(code, month)))
                .fold(onSuccess: (_) => null, onFailure: (e) => e),
        onFailure: (e) async => e,
      );
      if (error != null) {
        BLoaders.errorSnackBar(title: 'Could not print', message: error);
      }
      return error;
    } finally {
      isBusy.value = false;
    }
  }

  static Future<Result<Uint8List>> _loadFromRepository(
          {required String collector,
          required DateTime month,
          String? notedBy}) =>
      CollectionCalendarPrintRepository.instance
          .load(collector: collector, month: month, notedBy: notedBy);

  static Future<Result<bool>> _shareWithExporter(Uint8List bytes,
          {required String fileName}) =>
      ReportExportService.instance.sharePdf(bytes, fileName: fileName);

  static String _defaultCode() => Get.isRegistered<CollectionRepository>()
      ? CollectionRepository.instance.collectorCode
      : '';

  static String _defaultHead() => Get.isRegistered<UserController>()
      ? UserController.instance.user.value.headName
      : '';
}
