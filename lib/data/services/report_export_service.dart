import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/csv_writer.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/models/report_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Asks where to save [bytes] as [fileName]; the saved path, or null when the
/// user backs out.
typedef SaveFileFn = Future<String?> Function(
    {required String fileName, required Uint8List bytes});

/// Opens the share sheet for [bytes] as [fileName]; false when dismissed.
typedef ShareFileFn = Future<bool> Function(
    {required String fileName, required Uint8List bytes});

/// Gets a report off the phone as CSV: saved where the user picks (Android's
/// "Save as" dialog: Downloads, Drive…, no storage permission needed) or
/// shared (Viber, email…). Reports hold client names and amounts, so nothing
/// is written anywhere the user did not choose.
class ReportExportService extends GetxService {
  ReportExportService({SaveFileFn? save, ShareFileFn? share})
      : _save = save ?? _saveWithPicker,
        _share = share ?? _shareWithSheet;

  static ReportExportService get instance => Get.find();

  final SaveFileFn _save;
  final ShareFileFn _share;

  /// Success(path) when saved, Success(null) when the user cancelled.
  Future<Result<String?>> saveCsv(ReportTable table,
      {required String fileName}) async {
    try {
      return Result.success(
          await _save(fileName: fileName, bytes: BCsv.bytes(table)));
    } catch (e) {
      logDebug('ReportExportService.saveCsv error: $e');
      return Result.failure('Could not save the report: $e');
    }
  }

  /// Success(true) when shared, Success(false) when the sheet was dismissed.
  Future<Result<bool>> shareCsv(ReportTable table,
      {required String fileName}) async {
    try {
      return Result.success(
          await _share(fileName: fileName, bytes: BCsv.bytes(table)));
    } catch (e) {
      logDebug('ReportExportService.shareCsv error: $e');
      return Result.failure('Could not share the report: $e');
    }
  }

  // On Android file_picker writes [bytes] itself through the system dialog;
  // on desktop it only returns the chosen path, so the file is written here.
  static Future<String?> _saveWithPicker(
      {required String fileName, required Uint8List bytes}) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save report',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: bytes,
    );
    if (path == null || Platform.isAndroid || Platform.isIOS) return path;
    final out = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    await File(out).writeAsBytes(bytes, flush: true);
    return out;
  }

  // The share sheet needs a real file: written to the app's temp folder,
  // which the OS clears.
  static Future<bool> _shareWithSheet(
      {required String fileName, required Uint8List bytes}) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    final result = await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: fileName,
    ));
    return result.status != ShareResultStatus.dismissed;
  }
}
