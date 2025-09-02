
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../../../base/utils/constants/colors.dart';

class CapturedSignatureImage extends StatelessWidget {
  final String requestId;

  const CapturedSignatureImage({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final String imageRequestUrl =
        '${dotenv.env['API_URL']!}/api3/request/signature/$requestId';
    try {
      return Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: BColors.grey),
          ),
          child: Image.network(
            imageRequestUrl,
            height: 100,
            width: 150,
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) {
              // Log the error for debugging if needed
              return const Icon(Icons.error, color: Colors.red, size: 50);
            },
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) {
                return child; // Image is fully loaded
              }
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      // Catch potential FormatException from base64Decode
      return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 50));
    }
  }
}
