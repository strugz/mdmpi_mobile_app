import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/request_image_dialog.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_captured_signature_image.dart';

/// Displays delivery details section with driver, helper, receiver info,
/// timestamps, signature watermark, and view item button.
///
/// Reusable across Pull Out, Standard Delivery, Pick Up, and other modules.
/// Automatically hides the entire section if no data is provided.
class BDeliveryDetailsSection extends StatelessWidget {
  const BDeliveryDetailsSection({
    super.key,
    this.sectionTitle = 'Delivery Details',
    this.driver = '',
    this.helper = '',
    this.receivedBy = '',
    this.receivedByLabel = 'Released By',
    this.departedAt,
    this.departedAtLabel = 'Departed At',
    this.completedAt,
    this.completedAtLabel = 'Completed At',
    required this.requestId,
    this.showSignatureWatermark = true,
    this.onViewItemPressed,
    this.viewItemButtonLabel = 'View Proof',
    this.dialogTitle,
    this.apiController = 'Request',
    this.showViewItemButton = true,
  });

  /// Section header text displayed at the top
  final String sectionTitle;

  /// Driver name to display
  final String driver;

  /// Helper name to display
  final String helper;

  /// Person who received/released the delivery
  final String receivedBy;

  /// Label for the receivedBy field (e.g., 'Released By', 'Received By')
  final String receivedByLabel;

  /// Departure timestamp in ISO format
  final String? departedAt;

  /// Label for departure timestamp
  final String departedAtLabel;

  /// Completion timestamp in ISO format
  final String? completedAt;

  /// Label for completion timestamp (e.g., 'Pull Out At', 'Delivered At')
  final String completedAtLabel;

  /// Request ID for signature image loading
  final String requestId;

  /// Whether to show signature watermark behind receivedBy section
  final bool showSignatureWatermark;

  /// Callback when view item button is pressed. If null, uses default dialog.
  final VoidCallback? onViewItemPressed;

  /// Text label for the view item button
  final String viewItemButtonLabel;

  /// Title for the image dialog (e.g., 'Delivered Item', 'Pick Up Item')
  final String? dialogTitle;

  /// API controller name for image dialog
  final String apiController;

  /// Whether to show the view item button
  final bool showViewItemButton;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;

    // Check if any data exists to display
    final hasDriver = driver.isNotEmpty;
    final hasHelper = helper.isNotEmpty;
    final hasReceivedBy = receivedBy.isNotEmpty;
    final hasDeparted = departedAt != null && departedAt!.isNotEmpty;
    final hasCompleted = completedAt != null && completedAt!.isNotEmpty;

    // Hide entire section if no data
    if (!hasDriver &&
        !hasHelper &&
        !hasReceivedBy &&
        !hasDeparted &&
        !hasCompleted) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BSizes.md),
        BTextDivider(text: sectionTitle),
        const SizedBox(height: BSizes.sm),

        // Signature as watermark behind entire section - responsive
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate signature size based on available width
            final screenWidth = constraints.maxWidth;
            final signatureWidth = (screenWidth * 0.35).clamp(80.0, 130.0);
            final signatureHeight = (signatureWidth * 0.5).clamp(40.0, 65.0);

            return Stack(
              children: [
                // Signature watermark - right aligned and faded
                if (hasReceivedBy && showSignatureWatermark)
                  Positioned(
                    top: 20,
                    right: 30,
                    child: Container(
                      color: Colors.white,
                      child: SizedBox(
                        width: signatureWidth,
                        height: signatureHeight,
                        child: CapturedSignatureImage(
                          requestId: requestId,
                        ),
                      ),
                    ),
                  ),
                // Main content on top
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver/Helper and Receiver row - always horizontal
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column: Driver and Helper
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasDriver)
                                BProductTitleText(
                                  title: 'Driver: $driver',
                                  maxLines: 3,
                                  smallSize: true,
                                  fontColor: textColor,
                                ),
                              if (hasDriver && hasHelper)
                                const SizedBox(height: BSizes.xs),
                              if (hasHelper)
                                BProductTitleText(
                                  title: 'Helper: $helper',
                                  maxLines: 3,
                                  smallSize: true,
                                  fontColor: textColor,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: BSizes.sm),
                        // Right column: Receiver (signature overlays here)
                        if (hasReceivedBy)
                          Expanded(
                            child: BProductTitleText(
                              title: '$receivedByLabel: $receivedBy',
                              maxLines: 3,
                              smallSize: true,
                              fontColor: textColor,
                            ),
                          ),
                      ],
                    ),
                    // Timestamps
                    if (hasDeparted) ...[
                      const SizedBox(height: BSizes.sm),
                      BProductTitleText(
                        title:
                            '$departedAtLabel: ${BFormatter.formatDateTimeCustomizable(
                          departedAt!,
                          "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                          "yyyy-MM-dd HH:mm",
                        )}',
                        maxLines: 2,
                        smallSize: true,
                        fontColor: textColor,
                      ),
                    ],
                    if (hasCompleted) ...[
                      const SizedBox(height: BSizes.sm),
                      BProductTitleText(
                        title:
                            '$completedAtLabel: ${BFormatter.formatDateTimeCustomizable(
                          completedAt!,
                          "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                          "yyyy-MM-dd HH:mm",
                        )}',
                        maxLines: 2,
                        smallSize: true,
                        fontColor: textColor,
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),

        // View Delivered Item Button
        if (showViewItemButton) ...[
          const SizedBox(height: BSizes.sm),
          ViewDeliveredItemButton(
            textColor: textColor,
            labelTitle: viewItemButtonLabel,
            onPressed: onViewItemPressed ??
                () {
                  showRequestImageDialog(
                    context,
                    requestId: requestId,
                    fetchIfMissing: true,
                    semanticsLabel:
                        'Delivered item image for request $requestId',
                    apiController: apiController,
                    title: dialogTitle,
                  );
                },
          ),
        ],
      ],
    );
  }
}
