import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mdmpi_mobile_app/base/utils/images/document_image.dart';

/// Builds a landscape JPEG carrying an EXIF orientation tag.
///
/// Orientation 6 means "rotate 90 degrees clockwise to display", which is what
/// a phone held sideways records. The stored pixels stay landscape, so an OCR
/// model reading raw pixels sees the document rotated.
Uint8List jpegWithOrientation(int orientation,
    {int width = 40, int height = 20}) {
  final im = img.Image(width: width, height: height);
  // A visible gradient so a rotation is detectable beyond just dimensions.
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      im.setPixelRgb(x, y, x * 6 % 256, y * 12 % 256, 128);
    }
  }
  im.exif.imageIfd.orientation = orientation;
  return Uint8List.fromList(img.encodeJpg(im, quality: 100));
}

void main() {
  group('BDocumentImage.extensionOf / mimeTypeFor / canReorient', () {
    test('reads the extension case-insensitively', () {
      expect(BDocumentImage.extensionOf('/tmp/slip.JPG'), 'jpg');
      expect(BDocumentImage.extensionOf('slip.jpeg'), 'jpeg');
      expect(BDocumentImage.extensionOf('noextension'), '');
      expect(BDocumentImage.extensionOf('trailingdot.'), '');
    });

    test('maps the formats the scanner accepts', () {
      expect(BDocumentImage.mimeTypeFor('a.jpg'), 'image/jpeg');
      expect(BDocumentImage.mimeTypeFor('a.jpeg'), 'image/jpeg');
      expect(BDocumentImage.mimeTypeFor('a.png'), 'image/png');
      expect(BDocumentImage.mimeTypeFor('a.pdf'), 'application/pdf');
      expect(BDocumentImage.mimeTypeFor('a.xyz'), 'application/octet-stream');
    });

    test('refuses to reorient a PDF or an unknown format', () {
      expect(BDocumentImage.canReorient('a.pdf'), isFalse);
      expect(BDocumentImage.canReorient('a.xyz'), isFalse);
      expect(BDocumentImage.canReorient('a.jpg'), isTrue);
      expect(BDocumentImage.canReorient('a.png'), isTrue);
    });
  });

  group('BDocumentImage.orientationOf', () {
    test('reads the tag from the encoded JPEG, not from decoded pixels', () {
      // This is the crux. The package's JPEG decoder applies the tag during
      // decode and clears it, so an implementation that inspected the decoded
      // image would see "upright" and never persist the rotation.
      final bytes = jpegWithOrientation(6);

      expect(BDocumentImage.orientationOf(bytes, isJpeg: true), 6);

      final decoded = img.decodeImage(bytes)!;
      expect(decoded.exif.imageIfd.hasOrientation, isFalse,
          reason: 'decoder is expected to consume the tag');
    });

    test('returns null when no tag is present', () {
      final im = img.Image(width: 8, height: 8);
      final plain = Uint8List.fromList(img.encodeJpg(im));
      expect(BDocumentImage.orientationOf(plain, isJpeg: true), anyOf(isNull, 1));
    });
  });

  group('BDocumentImage rotation', () {
    test('bakes orientation 6 so the stored pixels become portrait', () {
      final bytes = jpegWithOrientation(6, width: 40, height: 20);

      final result = BDocumentImage.bakeOrientationForTest(bytes);

      expect(result, isNotNull);
      expect(result!.wasReoriented, isTrue);
      expect(result.mimeType, 'image/jpeg');

      final out = img.decodeImage(result.bytes)!;
      expect(out.width, 20);
      expect(out.height, 40);
      expect(out.exif.imageIfd.hasOrientation, isFalse,
          reason: 'the tag must be gone so nothing rotates it twice');
    });

    test('bakes orientation 8 as well', () {
      final result =
          BDocumentImage.bakeOrientationForTest(jpegWithOrientation(8));
      expect(result, isNotNull);
      final out = img.decodeImage(result!.bytes)!;
      expect(out.width, 20);
      expect(out.height, 40);
    });

    test('does nothing when the tag says upright', () {
      final result =
          BDocumentImage.bakeOrientationForTest(jpegWithOrientation(1));
      expect(result, isNull, reason: 'no tag work means keep original bytes');
    });

    test('does nothing for bytes that are not an image', () {
      final junk = Uint8List.fromList(List<int>.generate(64, (i) => i));
      expect(BDocumentImage.bakeOrientationForTest(junk), isNull);
    });
  });

  group('BDocumentImage.prepare', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('docimg'));
    tearDown(() => tmp.deleteSync(recursive: true));

    File write(String name, Uint8List bytes) {
      final f = File('${tmp.path}${Platform.pathSeparator}$name');
      f.writeAsBytesSync(bytes);
      return f;
    }

    test('rotates a sideways photo and reports it', () async {
      final f = write('slip.jpg', jpegWithOrientation(6, width: 40, height: 20));

      final prepared = await BDocumentImage.prepare(f);

      expect(prepared.wasReoriented, isTrue);
      expect(prepared.mimeType, 'image/jpeg');
      final out = img.decodeImage(prepared.bytes)!;
      expect(out.width, 20);
      expect(out.height, 40);
    });

    test('passes an upright photo through untouched', () async {
      final original = jpegWithOrientation(1, width: 40, height: 20);
      final f = write('slip.jpg', original);

      final prepared = await BDocumentImage.prepare(f);

      expect(prepared.wasReoriented, isFalse);
      expect(prepared.bytes, original,
          reason: 'no re-encode means no quality loss');
    });

    test('passes a PDF through byte for byte', () async {
      final pdf = Uint8List.fromList('%PDF-1.4 not really a pdf'.codeUnits);
      final f = write('slip.pdf', pdf);

      final prepared = await BDocumentImage.prepare(f);

      expect(prepared.wasReoriented, isFalse);
      expect(prepared.mimeType, 'application/pdf');
      expect(prepared.bytes, pdf);
    });

    test('never fails the upload when the file is not a real image', () async {
      final junk = Uint8List.fromList(List<int>.generate(64, (i) => i));
      final f = write('slip.jpg', junk);

      final prepared = await BDocumentImage.prepare(f);

      expect(prepared.wasReoriented, isFalse);
      expect(prepared.bytes, junk);
      expect(prepared.mimeType, 'image/jpeg');
    });
  });
}
