import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'dart:typed_data';

import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';

/// Displays a saved or remotely fetched signature image for a request.
///
/// Adapts to its parent: when the parent provides a bounded box (e.g. the
/// sized signature slot in [BDeliveryDetailsSection]) the image fills it;
/// otherwise it falls back to a fixed 150x100. The signature is always drawn
/// with [BoxFit.contain] so it is never cropped or distorted.
class CapturedSignatureImage extends StatelessWidget {
  final String requestId;
  final String type;

  const CapturedSignatureImage(
      {super.key, required this.requestId, this.type = 'Signature'});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(BApiEnvironment.api4BaseUrl).replace(
      path: '/api4/Request/image',
      queryParameters: {'requestid': requestId, 'type': type},
    );

    final imageRequestUrl = uri.toString();

    return LayoutBuilder(builder: (context, constraints) {
      // Fill a fully bounded parent; keep the legacy intrinsic size when the
      // parent leaves either axis unbounded (e.g. inside a plain Column).
      final bool bounded =
          constraints.hasBoundedWidth && constraints.hasBoundedHeight;
      final double boxWidth = bounded ? constraints.maxWidth : 150;
      final double boxHeight = bounded ? constraints.maxHeight : 100;

      Widget framed(Widget child) => Center(
            child: Container(
              width: boxWidth,
              height: boxHeight,
              decoration: BoxDecoration(
                border: Border.all(color: BColors.grey),
              ),
              child: child,
            ),
          );

      // First try to load saved signature bytes from local DB. If found,
      // show it directly.
      return FutureBuilder<Uint8List?>(
        future: DatabaseHelper.instance.loadSavedSignatureBytes(requestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return framed(
                const Center(child: CircularProgressIndicator(strokeWidth: 2)));
          }

          final Uint8List? bytes = snapshot.data;
          if (bytes != null && bytes.isNotEmpty) {
            return framed(Image.memory(bytes, fit: BoxFit.contain));
          }

          // No local bytes: fall back to network-loaded image (cached)
          return framed(
            CachedNetworkImage(
              imageUrl: imageRequestUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.red, size: 40)),
            ),
          );
        },
      );
    });
  }
}
