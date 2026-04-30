import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/signature_outbox_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/widgets/signature_outbox.dart';

/// Full page wrapper for the developer-facing Signature Outbox widget.
class SignatureOutboxPage extends StatelessWidget {
  const SignatureOutboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SignatureOutboxController>()
        ? Get.find<SignatureOutboxController>()
        : Get.put(SignatureOutboxController());

    return Scaffold(
      appBar: BAppBar(
        title: Text(
          'Signature Outbox',
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
      body: const SignatureOutbox(),
    );
  }
}

