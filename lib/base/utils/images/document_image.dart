import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'package:mdmpi_mobile_app/base/utils/logger.dart';

/// A document ready to send to the OCR model.
class BPreparedDocument {
  const BPreparedDocument({
    required this.bytes,
    required this.mimeType,
    required this.wasReoriented,
  });

  final Uint8List bytes;

  /// Mime type describing [bytes], which may differ from the source file's
  /// extension only in that a re-encode keeps the same family.
  final String mimeType;

  /// True when EXIF orientation was baked into the pixels.
  final bool wasReoriented;
}

/// Prepares scanned documents for OCR upload.
///
/// Phone cameras usually store a photo in the sensor's native orientation and
/// record how to display it in an EXIF orientation tag. Many consumers honour
/// that tag, but the OCR model reads raw pixels, so a photo that looks upright
/// in the gallery can reach the model rotated. A rotated table wrecks column
/// alignment, because the model has to establish orientation before it can
/// map values to columns.
///
/// [prepare] rewrites the pixels so they match the intended orientation and
/// drops the tag, giving the model an upright image.
///
/// Note the limit: this corrects orientation recorded in metadata. It cannot
/// tell that a document was physically photographed sideways, because those
/// pixels are genuinely sideways and carry no tag saying so.
class BDocumentImage {
  const BDocumentImage._();

  /// Raster formats the `image` package can decode and re-encode here.
  static const Set<String> reorientableExtensions = {
    'jpg',
    'jpeg',
    'png',
    'tif',
    'tiff',
    'webp',
    'bmp',
  };

  /// Last path segment of [path], tolerating either separator. Windows accepts
  /// both, and picker plugins are inconsistent about which they return.
  static String fileNameOf(String path) {
    final cut = path.lastIndexOf(RegExp(r'[/\\]'));
    return cut == -1 ? path : path.substring(cut + 1);
  }

  static String extensionOf(String path) {
    final name = fileNameOf(path);
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static String mimeTypeFor(String path) {
    switch (extensionOf(path)) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'tif':
      case 'tiff':
        return 'image/tiff';
      case 'bmp':
        return 'image/bmp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// True when [path] names a raster image whose orientation we can correct.
  /// PDFs and unknown formats are passed through untouched.
  static bool canReorient(String path) =>
      reorientableExtensions.contains(extensionOf(path));

  /// Reads [file] and returns bytes with EXIF orientation applied.
  ///
  /// Decoding runs on a separate isolate so a large photo does not stall the
  /// UI. Anything that cannot be handled is returned byte-for-byte as read,
  /// so this never blocks an upload: a failure to reorient degrades to the
  /// previous behaviour rather than to an error.
  static Future<BPreparedDocument> prepare(File file) async {
    final bytes = await file.readAsBytes();
    final sourceMime = mimeTypeFor(file.path);

    if (!canReorient(file.path)) {
      return BPreparedDocument(
        bytes: bytes,
        mimeType: sourceMime,
        wasReoriented: false,
      );
    }

    try {
      final ext = extensionOf(file.path);
      final preferPng = ext == 'png';
      final isJpeg = ext == 'jpg' || ext == 'jpeg';
      final result = await Isolate.run(
        () => _bakeOrientation(bytes, preferPng: preferPng, isJpeg: isJpeg),
      );

      if (result == null) {
        logDebug('BDocumentImage: no reorientation needed for ${file.path}');
        return BPreparedDocument(
          bytes: bytes,
          mimeType: sourceMime,
          wasReoriented: false,
        );
      }

      logDebug('BDocumentImage: baked EXIF orientation for ${file.path} '
          '(${bytes.length} -> ${result.bytes.length} bytes)');
      return result;
    } catch (e) {
      // A malformed or unusual image must not stop the scan.
      logDebug('BDocumentImage: reorientation skipped for ${file.path} – $e');
      return BPreparedDocument(
        bytes: bytes,
        mimeType: sourceMime,
        wasReoriented: false,
      );
    }
  }

  /// Reads the orientation tag from the encoded [bytes] themselves.
  ///
  /// This must come from the container rather than from a decoded image,
  /// because the package's JPEG decoder applies the tag while decoding and
  /// then clears it. Inspecting the decoded image would therefore always
  /// report "upright" and the rotation would never be persisted.
  static int? orientationOf(Uint8List bytes, {required bool isJpeg}) {
    if (isJpeg) {
      final ifd = img.decodeJpgExif(bytes)?.imageIfd;
      if (ifd == null || !ifd.hasOrientation) return null;
      return ifd.orientation;
    }
    final decoded = img.decodeImage(bytes);
    final ifd = decoded?.exif.imageIfd;
    if (ifd == null || !ifd.hasOrientation) return null;
    return ifd.orientation;
  }

  /// Bakes EXIF orientation into [bytes].
  ///
  /// Returns null when there is nothing to do, so the caller can keep the
  /// original bytes and avoid a pointless re-encode. Exposed for tests.
  static BPreparedDocument? bakeOrientationForTest(
    Uint8List bytes, {
    bool preferPng = false,
    bool isJpeg = true,
  }) =>
      _bakeOrientation(bytes, preferPng: preferPng, isJpeg: isJpeg);

  static BPreparedDocument? _bakeOrientation(
    Uint8List bytes, {
    required bool preferPng,
    required bool isJpeg,
  }) {
    // 1 means "already upright"; absent means the camera said nothing.
    final sourceOrientation = orientationOf(bytes, isJpeg: isJpeg);
    if (sourceOrientation == null || sourceOrientation == 1) return null;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // For JPEG the decoder has already applied the tag, so bakeOrientation is
    // a harmless copy. For formats whose decoder preserves the tag, this is
    // what actually performs the rotation. Either way the result carries no
    // orientation tag, so the re-encode cannot double-rotate.
    final baked = img.bakeOrientation(decoded);

    // Re-encode in the same family so the declared mime type stays honest.
    final Uint8List out = preferPng
        ? Uint8List.fromList(img.encodePng(baked))
        : Uint8List.fromList(img.encodeJpg(baked, quality: 92));

    return BPreparedDocument(
      bytes: out,
      mimeType: preferPng ? 'image/png' : 'image/jpeg',
      wasReoriented: true,
    );
  }
}
