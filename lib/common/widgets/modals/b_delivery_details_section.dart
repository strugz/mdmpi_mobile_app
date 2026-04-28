import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/request_image_dialog.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/signature/captured_signature_image.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/b_map_location_link.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_view_delivered_item_button.dart';

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
    this.completedAtFormatter,
    this.location = '',
    this.locationLabel = 'Delivered Location',
    this.signatureBelowReceivedBy = false,
    // Signature sizing options (new): if null, default behavior preserved
    this.signatureWidth,
    this.signatureHeight,
    this.signatureWidthFactor = 0.35,
    this.signatureMinWidth = 80.0,
    this.signatureMaxWidth = 130.0,
    // Default to left so Received By appears on the left by default
    this.signatureLeft = false,
    // If null, the receivedBy placement follows signatureLeft; otherwise explicit
    this.receivedByLeft,
    this.imageProofType = 'Proof',
    this.signatureType = 'Signature',
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

  /// Optional custom formatter for completedAt (returns formatted string)
  final String Function(String)? completedAtFormatter;

  /// Optional location coordinates/text to show as a map link row.
  final String location;

  /// Label for the optional location row.
  final String locationLabel;

  /// If true, display signature below the Received By value instead of a watermark
  final bool signatureBelowReceivedBy;

  /// If true, render watermark or below-received signature on the left side instead of right
  final bool signatureLeft;

  /// Optional explicit signature width (overrides computed factor)
  final double? signatureWidth;

  /// Optional explicit signature height (if not provided, height = width * 0.5 clamped)
  final double? signatureHeight;

  /// Signature width as factor of available width (default 0.35)
  final double signatureWidthFactor;

  /// Signature minimum width when computing from factor
  final double signatureMinWidth;

  /// Signature maximum width when computing from factor
  final double signatureMaxWidth;

  /// If non-null, explicitly place the Received By block on the left when true,
  /// or on the right when false. When null, it follows [signatureLeft].
  final bool? receivedByLeft;

  final String imageProofType;

  final String signatureType;

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
    final hasLocation = location.trim().isNotEmpty;

    // Decide which side shows the Received By block. If receivedByLeft is null,
    // follow signatureLeft; otherwise use the explicit value. Also ensure there
    // is a receivedBy to show.
    final bool placeReceivedLeft =
        (receivedByLeft ?? signatureLeft) && hasReceivedBy;

    // Hide entire section if no data
    if (!hasDriver &&
        !hasHelper &&
        !hasReceivedBy &&
        !hasDeparted &&
        !hasCompleted &&
        !hasLocation) {
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
            // Calculate signature size based on available width or explicit props
            final screenWidth = constraints.maxWidth;

            double computedSignatureWidth;
            if (signatureWidth != null) {
              computedSignatureWidth = signatureWidth!.clamp(0.0, screenWidth);
            } else {
              // If only receivedBy is present (no driver/helper), allocate more width
              final bool soloReceiver =
                  !hasDriver && !hasHelper && hasReceivedBy;
              final double effectiveFactor =
                  soloReceiver ? 0.75 : signatureWidthFactor;
              // Allow expansion up to 95% of container when solo receiver
              final double maxAllowed =
                  soloReceiver ? (screenWidth * 0.95) : signatureMaxWidth;
              computedSignatureWidth = (screenWidth * effectiveFactor)
                  .clamp(signatureMinWidth, maxAllowed);
            }

            double computedSignatureHeight;
            if (signatureHeight != null) {
              computedSignatureHeight =
                  signatureHeight!.clamp(0.0, screenWidth);
            } else {
              computedSignatureHeight =
                  (computedSignatureWidth * 0.5).clamp(40.0, 130.0);
            }
            return Stack(
              children: [
                // Signature watermark - right aligned and faded (only when not using below-received placement)
                if (hasReceivedBy &&
                    showSignatureWatermark &&
                    !signatureBelowReceivedBy)
                  Positioned(
                    top: 20,
                    // position left or right based on signatureLeft flag
                    left: signatureLeft ? 30 : null,
                    right: signatureLeft ? null : 30,
                    child: Container(
                      color: Colors.white,
                      child: SizedBox(
                        width: computedSignatureWidth,
                        height: computedSignatureHeight,
                        child: CapturedSignatureImage(
                          requestId: requestId,
                          type: signatureType,
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
                        // Left column: Driver/Helper and optionally Received By (if placed left)
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
                              if (placeReceivedLeft) ...[
                                const SizedBox(height: BSizes.xs),
                                BLabelValueText(
                                  label: receivedByLabel,
                                  value: receivedBy,
                                  showLabel: true,
                                  maxLines: 3,
                                  smallSize: true,
                                  textColor: textColor,
                                  padding: EdgeInsets.zero,
                                ),
                                if (signatureBelowReceivedBy) ...[
                                  const SizedBox(height: BSizes.sm),
                                  FractionallySizedBox(
                                    widthFactor: 0.9,
                                    child: SizedBox(
                                      height: computedSignatureHeight,
                                      child: CapturedSignatureImage(
                                        requestId: requestId,
                                        type: signatureType,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: BSizes.sm),
                        // Right column: show Received By if it's not placed on the left
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!placeReceivedLeft && hasReceivedBy) ...[
                                BLabelValueText(
                                  label: receivedByLabel,
                                  value: receivedBy,
                                  showLabel: true,
                                  maxLines: 3,
                                  smallSize: true,
                                  textColor: textColor,
                                  padding: EdgeInsets.zero,
                                ),
                                if (signatureBelowReceivedBy) ...[
                                  const SizedBox(height: BSizes.sm),
                                  FractionallySizedBox(
                                    widthFactor: 0.9,
                                    child: SizedBox(
                                      height: computedSignatureHeight,
                                      child: CapturedSignatureImage(
                                        requestId: requestId,
                                        type: signatureType,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Timestamps
                    if (hasDeparted) ...[
                      const SizedBox(height: BSizes.sm),
                      BLabelValueText(
                        label: departedAtLabel,
                        value: BFormatter.formatDateWithAmPm(departedAt!),
                        showLabel: false,
                        icon: Iconsax.calendar,
                        maxLines: 2,
                        smallSize: true,
                        textColor: textColor,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                    if (hasCompleted) ...[
                      const SizedBox(height: BSizes.sm),
                      BLabelValueText(
                        label: completedAtLabel,
                        value: completedAtFormatter != null
                            ? completedAtFormatter!(completedAt!)
                            : BFormatter.formatDateWithAmPm(completedAt!),
                        showLabel: false,
                        icon: Iconsax.calendar_1,
                        maxLines: 2,
                        smallSize: true,
                        textColor: textColor,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                    if (hasLocation) ...[
                      const SizedBox(height: BSizes.sm),
                      BMapLocationLink(
                        label: locationLabel,
                        location: location,
                        showLabel: true,
                        icon: Iconsax.location,
                        padding: EdgeInsets.zero,
                        mainAlignment: MainAxisAlignment.start,
                        iconOnly: true,
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
                    semanticsLabel:
                        'Delivered item image for request $requestId',
                    apiController: apiController,
                    title: dialogTitle,
                    type: imageProofType
                  );
                },
          ),
        ],
      ],
    );
  }
}
