import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

    try {
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
              child: Center(child: Icon(Icons.error, color: Colors.red, size: 40)),
            ),
          ),
        ),
      );
    } catch (e) {
      // In case something unexpected happens, show a fallback icon.
      return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 50));
    }
  }
}
