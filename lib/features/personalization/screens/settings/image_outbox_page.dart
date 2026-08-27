import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/image_outbox_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/widgets/image_outbox.dart';

/// Full page wrapper for the developer-facing Image Outbox widget.
class ImageOutboxPage extends StatelessWidget {
  const ImageOutboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ImageOutboxController>()
        ? Get.find<ImageOutboxController>()
        : Get.put(ImageOutboxController());

    return Scaffold(
      appBar: BAppBar(
        title: Text(
          'Image Outbox',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        showBackArrow: true,
        actions: [
          IconButton(
            onPressed: controller.loadItems,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: const ImageOutbox(),
    );
  }
}
