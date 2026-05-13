import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/b_proof_image.dart';

class RequestNetworkImageDialog extends StatelessWidget {
  final String requestId;
  final String apiController;
  final String type;
  final String title;

  const RequestNetworkImageDialog({
    super.key,
    required this.requestId,
    required this.apiController,
    this.type = 'Proof',
    this.title = BTexts.requestModalDeliveryShotTitle,
  });

  @override
  Widget build(BuildContext context) {
    final base = dotenv.env['API_URL'];
    if (base == null || base.isEmpty) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('API_URL not configured'),
        ),
      );
    }

    final apiBase = Uri.parse(base);
    final imageUri = apiBase.replace(
      path: '/api4/$apiController/image',
      queryParameters: {'requestid': requestId, 'type': type},
    );
    final imageUrl = imageUri.toString();

    return Dialog(
      insetPadding: const EdgeInsets.all(12.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    tooltip: BTexts.requestModalCloseButtonText,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20.0),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Error loading image'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  // rebuild to retry
                                  (context as Element).markNeedsBuild();
                                },
                                child: const Text('Retry'),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: () async {
                                  // Attempt to fetch raw bytes and show them
                                  final bytes = await BProofImage.instance
                                      .loadRequestImageBytes(
                                    requestId,
                                    apiController,
                                    fetchIfMissing: true,
                                    type: type,
                                  );
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (bytes != null) {
                                    Navigator.of(context).pop();
                                    await showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        insetPadding:
                                            const EdgeInsets.all(12.0),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                .size
                                                .width,
                                            maxHeight: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.9,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12.0,
                                                        vertical: 8.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                        title,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium),
                                                    IconButton(
                                                      tooltip: BTexts
                                                          .requestModalCloseButtonText,
                                                      icon: const Icon(
                                                          Icons.close),
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: InteractiveViewer(
                                                    panEnabled: true,
                                                    boundaryMargin:
                                                        const EdgeInsets.all(
                                                            20.0),
                                                    minScale: 0.5,
                                                    maxScale: 4.0,
                                                    child: Image.memory(bytes,
                                                        fit: BoxFit.contain),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0,
                                                        horizontal: 12.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    TextButton(
                                                      child: const Text(BTexts
                                                          .requestModalCloseButtonText),
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Use fallback'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text(BTexts.requestModalCloseButtonText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
