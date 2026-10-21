import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:mdmpi_mobile_app/base/utils/b_ocr_orientation.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_extractor.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/client_header_extractor.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/client_matcher.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/delivery_document_type.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/item_table_parser.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/one_scan_reference_patterns.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/client_match_result.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/delivery_document_scan_result.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/item_table_reading.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/scanned_client_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/services/i_delivery_document_scan_service.dart';

/// Plan §4.1: one OCR pass; one retry at the estimated angle, on a smaller
/// copy, only when the first pass found nothing at all; then the client
/// header, references and item table from the same lines, and the client
/// ranking. Everything on the device.
class DeliveryDocumentScanService implements IDeliveryDocumentScanService {
  DeliveryDocumentScanService({
    required ITextExtractor textExtractor,
    required ClientMatcher matcher,
    required Future<List<ClientModel>> Function() clients,
    ITextRecognitionService? textRecognition,
    Future<List<OcrLine>> Function(String path)? readLines,
    Future<String?> Function(String path, int rotation)? rotateForRetry,
  })  : _extractor = textExtractor,
        _matcher = matcher,
        _clients = clients,
        _readLines = readLines ??
            ((path) => textRecognition!
                .processImageLines(InputImage.fromFilePath(path))),
        _rotate = rotateForRetry ?? rotatedCopy;

  final ITextExtractor _extractor;
  final ClientMatcher _matcher;
  final Future<List<ClientModel>> Function() _clients;
  final Future<List<OcrLine>> Function(String path) _readLines;
  final Future<String?> Function(String path, int rotation) _rotate;

  List<OcrLine> _lastLines = const [];

  @override
  List<OcrLine> get lastLines => _lastLines;

  /// Long edge of the downscaled retry copy, in pixels.
  static const int retryLongEdge = 1600;

  @override
  void clearCache() => _matcher.clearCache();

  @override
  Future<Result<DeliveryDocumentScanResult>> scan(File image) async {
    try {
      final watch = Stopwatch()..start();
      // ML Kit applies the photo's EXIF orientation itself when reading
      // from a file path, so pass 1 needs no re-encode.
      final pass1Lines = await _readLines(image.path);
      final pass1Ms = watch.elapsedMilliseconds;
      var reading = _read(pass1Lines);
      _lastLines = pass1Lines;

      int? retryRotation;
      var retryMs = 0;
      if (reading.isEmpty) {
        retryRotation = BOcrOrientation.estimateRetryRotation(pass1Lines);
        if (retryRotation != null) {
          watch.reset();
          final rotatedPath = await _rotate(image.path, retryRotation);
          if (rotatedPath != null) {
            final retryLines = await _readLines(rotatedPath);
            final retry = _read(retryLines);
            // Pass 1 is never thrown away: the retry wins only when it
            // found something, or at least read more text.
            if (!retry.isEmpty || retryLines.length > pass1Lines.length) {
              reading = retry;
              _lastLines = retryLines;
            }
            _deleteQuietly(rotatedPath);
          }
          retryMs = watch.elapsedMilliseconds;
        }
      }
      logDebug('[OneScan] ocr pass1=${pass1Ms}ms retry=${retryMs}ms '
          'angle=${retryRotation ?? '-'} lines=${pass1Lines.length}');

      final clients = await _clients();
      var header = reading.header;
      var match = await _matcher.match(header, clients);
      if (!header.hasName && header.nameCandidates.isNotEmpty) {
        (header, match) = await _matchCandidates(header, clients, match);
      }

      final warnings = <String>[
        if (reading.isEmpty)
          "Couldn't read the client, references or items. Try a straighter photo.",
        if (!reading.isEmpty && !reading.items.headerFound)
          'No item table found. Use Add Item for the items.',
        if (!reading.isEmpty && !header.hasName)
          "Couldn't read the client name. Search for it instead.",
      ];

      return Result.success(DeliveryDocumentScanResult(
        header: header,
        match: match,
        references: reading.references,
        items: reading.items,
        warnings: warnings,
        retryRotation: retryRotation,
        documentType: reading.documentType,
      ));
    } catch (e, st) {
      logDebug('[OneScan] scan failed: $e\n$st');
      return Result.failure('Could not read the document: $e');
    }
  }

  /// No name under a label: each header row that could be the name is
  /// matched against the client list, and the best is taken when it matches
  /// a client strongly ([ClientCandidate.isStrong]: a high score with a
  /// clear lead, or an exact name or learned alias). Otherwise the header and [none] stay as they were. The
  /// user still confirms the client.
  Future<(ScannedClientHeader, ClientMatchResult)> _matchCandidates(
    ScannedClientHeader header,
    List<ClientModel> clients,
    ClientMatchResult none,
  ) async {
    String? bestName;
    ClientMatchResult? best;
    double scoreOf(ClientMatchResult m) => m.kind == ClientMatchKind.exact ||
            m.kind == ClientMatchKind.alias
        ? 2
        : m.candidates.first.score;
    for (final name in header.nameCandidates) {
      final m = await _matcher.match(header.withName(name), clients);
      if (m.candidates.isEmpty) continue;
      if (best == null || scoreOf(m) > scoreOf(best)) {
        best = m;
        bestName = name;
      }
    }
    if (best == null || !best.candidates.first.isStrong) {
      return (header, none);
    }
    logDebug('[OneScan] client name taken from a header row (no label): '
        '${header.nameCandidates.indexOf(bestName!) + 1} of '
        '${header.nameCandidates.length}');
    return (header.withName(bestName), best);
  }

  _Reading _read(List<OcrLine> lines) {
    final header = ClientHeaderExtractor.extract(lines);
    final items = ItemTableParser.parse(lines);
    final type = DeliveryDocumentType.detect(lines);
    final references = type.keepOwnReferences(OneScanReferencePatterns.fromLines(
      lines,
      _extractor,
      excludeTexts: items.tableTexts,
    ));
    return _Reading(header, references, items, type);
  }

  static void _deleteQuietly(String path) {
    try {
      File(path).deleteSync();
    } catch (_) {}
  }

  /// A copy of the photo turned clockwise by [rotation] degrees and shrunk
  /// to [retryLongEdge], written to the temp folder. Null when the image
  /// cannot be decoded. Runs off the UI thread.
  static Future<String?> rotatedCopy(String path, int rotation) async {
    final bytes = await File(path).readAsBytes();
    final out = await Isolate.run(() {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      var turned = img.copyRotate(img.bakeOrientation(decoded), angle: rotation);
      final longEdge = math.max(turned.width, turned.height);
      if (longEdge > retryLongEdge) {
        final scale = retryLongEdge / longEdge;
        turned = img.copyResize(turned,
            width: (turned.width * scale).round(),
            height: (turned.height * scale).round());
      }
      return img.encodeJpg(turned, quality: 90);
    });
    if (out == null) return null;
    final file = File('${Directory.systemTemp.path}/one_scan_retry_'
        '${DateTime.now().microsecondsSinceEpoch}.jpg');
    await file.writeAsBytes(out);
    return file.path;
  }
}

class _Reading {
  const _Reading(this.header, this.references, this.items, this.documentType);

  final ScannedClientHeader header;
  final List<String> references;
  final ItemTableReading items;
  final DeliveryDocumentType documentType;

  bool get isEmpty =>
      DeliveryDocumentScanResult.isEmptyReading(header, references, items);
}
