// Merged dialog widget and helper: ImageBytesDialog + showRequestImageDialog
// This file replaces the previous `image_bytes_dialog.dart` as the single source
// for showing request-related image dialogs.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:mdmpi_mobile_app/features/logistics/helpers/b_proof_image.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/request_network_image_dialog.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';

class ImageBytesDialog extends StatelessWidget {
  final Uint8List bytes;
  final String title;
  final String closeButtonText;
  final String semanticsLabel;

  const ImageBytesDialog({
    super.key,
    required this.bytes,
    this.title = 'Image',
    this.closeButtonText = 'Close',
    this.semanticsLabel = 'Image',
  });

  @override
  Widget build(BuildContext context) {
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
                    tooltip: closeButtonText,
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
                  child: Semantics(
                    label: semanticsLabel,
                    child: Image.memory(bytes, fit: BoxFit.contain),
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
                    child: Text(closeButtonText),
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

class ImageLocalPathDialog extends StatelessWidget {
  final String localPath;
  final String title;
  final String closeButtonText;
  final String semanticsLabel;

  const ImageLocalPathDialog({
    super.key,
    required this.localPath,
    this.title = 'Image',
    this.closeButtonText = 'Close',
    this.semanticsLabel = 'Image',
  });

  @override
  Widget build(BuildContext context) {
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
                    tooltip: closeButtonText,
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
                  child: Semantics(
                    label: semanticsLabel,
                    child: Image.file(
                      File(localPath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Center(
                          child: Text('Failed to load local image'),
                        );
                      },
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
                    child: Text(closeButtonText),
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

/// Multi-photo variant of [showRequestImageDialog]: resolves one local file
/// per image [types] entry (local first, then API) and shows the ones found
/// in a swipeable page view. Falls back to the single-image dialog behavior
/// when only the first type resolves.
Future<void> showRequestImagesDialog(BuildContext context,
    {required String requestId,
    required List<String> types,
    String? title,
    String? closeButtonText,
    String? semanticsLabel,
    String? apiController}) async {
  if (apiController == null || apiController.isEmpty || types.isEmpty) {
    return;
  }

  final localPaths = <String>[];
  for (final type in types) {
    final path = await BProofImage.instance.fetchAndSaveImageToLocalFile(
      requestId,
      apiController,
      type: type,
    );
    if (path != null && path.isNotEmpty) {
      localPaths.add(path);
    }
  }

  if (!context.mounted) return;

  if (localPaths.isEmpty) {
    // Nothing resolved locally: fall back to the network dialog for the
    // primary type so the user still gets the legacy behavior.
    await showRequestImageDialog(
      context,
      requestId: requestId,
      title: title,
      closeButtonText: closeButtonText,
      semanticsLabel: semanticsLabel,
      apiController: apiController,
      type: types.first,
    );
    return;
  }

  if (localPaths.length == 1) {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ImageLocalPathDialog(
        localPath: localPaths.first,
        title: title ?? BTexts.requestModalDeliveryShotTitle,
        closeButtonText: closeButtonText ?? BTexts.requestModalCloseButtonText,
        semanticsLabel:
            semanticsLabel ?? 'Delivered item image for request $requestId',
      ),
    );
    return;
  }

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ImagePagerDialog(
      localPaths: localPaths,
      title: title ?? BTexts.requestModalDeliveryShotTitle,
      closeButtonText: closeButtonText ?? BTexts.requestModalCloseButtonText,
      semanticsLabel:
          semanticsLabel ?? 'Delivered item image for request $requestId',
    ),
  );
}

class _ImagePagerDialog extends StatefulWidget {
  const _ImagePagerDialog({
    required this.localPaths,
    required this.title,
    required this.closeButtonText,
    required this.semanticsLabel,
  });

  final List<String> localPaths;
  final String title;
  final String closeButtonText;
  final String semanticsLabel;

  @override
  State<_ImagePagerDialog> createState() => _ImagePagerDialogState();
}

class _ImagePagerDialogState extends State<_ImagePagerDialog> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    '${widget.title} (${_page + 1}/${widget.localPaths.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    tooltip: widget.closeButtonText,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                itemCount: widget.localPaths.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20.0),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Semantics(
                      label: '${widget.semanticsLabel} (${index + 1})',
                      child: Image.file(
                        File(widget.localPaths[index]),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('Failed to load local image'),
                        ),
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
                    child: Text(widget.closeButtonText),
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

Future<void> showRequestImageDialog(BuildContext context,
    {required String requestId,
    String? title,
    String? closeButtonText,
    String? semanticsLabel,
    String? apiController,
    String type = 'Proof'}) async {
  if (apiController == null || apiController.isEmpty) {
    return;
  }


  final String? localPath =
      await BProofImage.instance.fetchAndSaveImageToLocalFile(
    requestId,
    apiController,
    type: type,
  );

  if (!context.mounted) return;

  if (localPath != null && localPath.isNotEmpty) {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return ImageLocalPathDialog(
          localPath: localPath,
          title: title ?? BTexts.requestModalDeliveryShotTitle,
          closeButtonText:
              closeButtonText ?? BTexts.requestModalCloseButtonText,
          semanticsLabel:
              semanticsLabel ?? 'Delivered item image for request $requestId',
        );
      },
    );
    return;
  }

  // Fallback: show network dialog that knows how to load by requestId.
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return RequestNetworkImageDialog(
        requestId: requestId,
        apiController: apiController,
        type: type,
        title: title ?? BTexts.requestModalDeliveryShotTitle,
      );
    },
  );
}
