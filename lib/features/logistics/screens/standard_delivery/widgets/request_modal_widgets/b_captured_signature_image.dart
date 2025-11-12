import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'dart:typed_data';

import '../../../../../../base/utils/constants/colors.dart';

class CapturedSignatureImage extends StatelessWidget {
  final String requestId;

  const CapturedSignatureImage({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final base = dotenv.env['API_URL'];
    if (base == null || base.isEmpty) {
      return const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
      );
    }
    final uri = Uri.parse(base).replace(
      path: '/api4/Request/image',
      queryParameters: {'requestid': requestId, 'type': 'Signature'},
    );
    final imageRequestUrl = uri.toString();

    // First try to load saved signature bytes from local DB. If found, show it directly.
    return FutureBuilder<Uint8List?>(
      future: DatabaseHelper.instance.loadSavedSignatureBytes(requestId),
      builder: (context, snapshot) {
        // While waiting, show the same placeholder as CachedNetworkImage would
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: BColors.grey),
              ),
              child: const SizedBox(
                height: 100,
                width: 150,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          // On DB error, fall back to network image
          // (we intentionally do not surface DB errors here)
        }

        final Uint8List? bytes = snapshot.data;
        if (bytes != null && bytes.isNotEmpty) {
          return Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: BColors.grey),
              ),
              child: Image.memory(
                bytes,
                height: 100,
                width: 150,
                fit: BoxFit.fill,
              ),
            ),
          );
        }

        // No local bytes: fall back to network-loaded image (cached)
        return Center(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: BColors.grey),
            ),
            child: CachedNetworkImage(
              imageUrl: imageRequestUrl,
              height: 100,
              width: 150,
              fit: BoxFit.fill,
              placeholder: (context, url) => const SizedBox(
                height: 100,
                width: 150,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const SizedBox(
                height: 100,
                width: 150,
                child: Center(
                    child: Icon(Icons.error, color: Colors.red, size: 40)),
              ),
            ),
          ),
        );
      },
    );
  }
}
