import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:mdmpi_mobile_app/base/utils/b_ocr_orientation.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/acr_item_filter.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/item_table_parser.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/acr_verdict.dart';

/// Reads a document with Gemini and maps the result into items.
typedef GeminiItemReader = Future<Result<List<InventoryItemModel>>> Function(
    File file,
    {String? prompt});

/// Who read the items of an Add Item scan.
enum AcrItemSource { acr, gemini }

class AcrItemScanOutcome {
  const AcrItemScanOutcome({
    required this.items,
    required this.source,
    this.verdict = const AcrVerdict(),
    this.aiError,
  });

  final List<InventoryItemModel> items;
  final AcrItemSource source;

  /// The ACR pass's verdict: why Gemini was asked, when it was.
  final AcrVerdict verdict;

  /// Set when Gemini was needed but failed, and the items are the ACR
  /// reading kept anyway for the user to check.
  final String? aiError;
}

/// The Request Form's Add Item scan, ACR first:
///
/// 1. The phone's own text recognition reads the photo, and
///    [ItemTableParser] + [AcrItemFilter] keep only the item table's rows.
/// 2. When every row is complete and the confidence meets the threshold,
///    those items are the result: no network, no Gemini call.
/// 3. Otherwise Gemini reads it, sent only the table's band of the photo
///    (whole photo when there is no table, the page is sideways, or the file
///    is a PDF), to keep the request small.
class AcrItemScanService {
  AcrItemScanService({
    required GeminiItemReader readWithGemini,
    ITextRecognitionService? textRecognition,
    Future<List<OcrLine>> Function(String path)? readLines,
    Future<String?> Function(String path, Rect region)? cropToRegion,
    bool? onDevice,
    Map<String, String>? env,
  })  : _gemini = readWithGemini,
        _readLines = readLines ??
            ((path) => textRecognition!
                .processImageLines(InputImage.fromFilePath(path))),
        _crop = cropToRegion ?? croppedCopy,
        _onDevice = onDevice ?? (Platform.isAndroid || Platform.isIOS),
        _env = env;

  final GeminiItemReader _gemini;
  final Future<List<OcrLine>> Function(String path) _readLines;
  final Future<String?> Function(String path, Rect region) _crop;
  final bool _onDevice;
  final Map<String, String>? _env;

  /// Space kept above and below the table when cropping, as a share of the
  /// photo's height (the header row and a wrapped last line stay in).
  static const double cropMargin = 0.04;

  /// A table band taller than this share of the photo is sent whole: the
  /// crop would save almost nothing.
  static const double maxCropShare = 0.85;

  double get _minConfidence {
    if (_env != null) return AcrItemFilter.minConfidenceFrom(_env);
    try {
      return AcrItemFilter.minConfidenceFrom(dotenv.env);
    } catch (_) {
      return AcrItemFilter.defaultMinConfidence;
    }
  }

  Future<Result<AcrItemScanOutcome>> scan(File file, {String? prompt}) async {
    if (!_onDevice || !_isPhoto(file.path)) {
      return _fallback(file, prompt,
          const AcrVerdict(reasons: [AcrFallbackReason.notReadable]), null);
    }

    final List<OcrLine> lines;
    try {
      lines = await _readLines(file.path);
    } catch (e) {
      logDebug('[ACR] on-device OCR failed, using Gemini: $e');
      return _fallback(file, prompt,
          const AcrVerdict(reasons: [AcrFallbackReason.notReadable]), null);
    }

    final reading = ItemTableParser.parse(lines);
    var verdict =
        AcrItemFilter.evaluate(reading, minConfidence: _minConfidence);
    logDebug('[ACR] lines=${lines.length} items=${verdict.items.length} '
        'dropped=${verdict.droppedRows} '
        'confidence=${verdict.confidence.toStringAsFixed(2)} '
        'reasons=${verdict.reasons.map((r) => r.name).join(',')}');
    if (verdict.accepted) {
      return Result.success(AcrItemScanOutcome(
          items: verdict.items, source: AcrItemSource.acr, verdict: verdict));
    }

    Rect? region = reading.region;
    if (region != null && BOcrOrientation.estimateRetryRotation(lines) != null) {
      // Sideways page: OCR's boxes do not line up with the table.
      region = null;
      verdict = AcrVerdict(
        items: verdict.items,
        confidence: verdict.confidence,
        droppedRows: verdict.droppedRows,
        reasons: [...verdict.reasons, AcrFallbackReason.distorted],
      );
    }
    return _fallback(file, prompt, verdict, region);
  }

  Future<Result<AcrItemScanOutcome>> _fallback(
    File file,
    String? prompt,
    AcrVerdict verdict,
    Rect? region,
  ) async {
    String? croppedPath;
    if (region != null) {
      try {
        croppedPath = await _crop(file.path, region);
      } catch (e) {
        logDebug('[ACR] crop failed, sending the whole photo: $e');
      }
    }

    var sent = croppedPath == null ? 'whole' : 'cropped';
    var ai = await _gemini(
        croppedPath == null ? file : File(croppedPath),
        prompt: prompt);
    if (croppedPath != null) {
      _deleteQuietly(croppedPath);
      // The crop missed the table (OCR boxes off): one more try, whole.
      if (ai.isSuccess && ai.value.isEmpty) {
        sent = 'whole after an empty crop';
        ai = await _gemini(file, prompt: prompt);
      }
    }
    logDebug('[ACR] Gemini fallback ($sent): '
        '${ai.isSuccess ? '${ai.value.length} items' : ai.error}');

    if (ai.isSuccess) {
      return Result.success(AcrItemScanOutcome(
          items: ai.value, source: AcrItemSource.gemini, verdict: verdict));
    }
    // Offline or AI unavailable: what the phone read is better than nothing.
    if (verdict.items.isNotEmpty) {
      return Result.success(AcrItemScanOutcome(
        items: verdict.items,
        source: AcrItemSource.acr,
        verdict: verdict,
        aiError: ai.error,
      ));
    }
    return Result.failure(ai.error);
  }

  static bool _isPhoto(String path) =>
      RegExp(r'\.(jpe?g|png|webp|heic|heif|bmp)$', caseSensitive: false)
          .hasMatch(path);

  static void _deleteQuietly(String path) {
    try {
      File(path).deleteSync();
    } catch (_) {}
  }

  /// A copy of the photo cut to the horizontal band holding [region], full
  /// width (a column OCR missed at an edge stays in), with [cropMargin]
  /// above and below. Null when the image cannot be decoded or the band is
  /// most of the photo anyway. Runs off the UI thread.
  static Future<String?> croppedCopy(String path, Rect region) async {
    final bytes = await File(path).readAsBytes();
    final out = await Isolate.run(() {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      // ML Kit reads a file with its EXIF orientation applied, so its boxes
      // are in the turned image's pixels.
      final page = img.bakeOrientation(decoded);
      final margin = cropMargin * page.height;
      final top = math.max(0, (region.top - margin).floor());
      final bottom =
          math.min(page.height, (region.bottom + margin).ceil());
      if (bottom <= top || bottom - top > maxCropShare * page.height) {
        return null;
      }
      final band =
          img.copyCrop(page, x: 0, y: top, width: page.width, height: bottom - top);
      return img.encodeJpg(band, quality: 90);
    });
    if (out == null) return null;
    final file = File('${Directory.systemTemp.path}/acr_table_'
        '${DateTime.now().microsecondsSinceEpoch}.jpg');
    await file.writeAsBytes(out);
    return file.path;
  }
}
