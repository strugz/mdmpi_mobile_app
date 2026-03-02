import 'package:flutter/material.dart';

import '../../../../models/standard_delivery_model.dart';

/// Footer widget for request modals.
///
/// Note: Driver/Helper information has been moved to [BDeliveryDetailsSection]
/// for better presentation with timestamps and signature watermark.
/// This widget is kept for future footer content or can be removed if not needed.
class RequestModalFooter extends StatelessWidget {
  const RequestModalFooter({super.key, required this.requestModel});

  final StandardDeliveryModel requestModel;

  @override
  Widget build(BuildContext context) {
    // Driver/Helper info is now displayed in BDeliveryDetailsSection
    // Return empty widget - footer can be extended for other metadata if needed
    return const SizedBox.shrink();
  }
}
