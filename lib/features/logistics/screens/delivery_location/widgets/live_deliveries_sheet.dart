import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/common/widgets/layouts/draggable_bottom_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/rider_location_model.dart';

/// Bottom sheet for the live map: the list of couriers currently on the road,
/// or — once a car is tapped — one selected-delivery card with explicit
/// **Call** and **Center** actions.
///
/// Replaces the edge-swipe `Drawer` (no button ever opened it) and the native
/// Google info window (one truncated line, and its only action — tap to call —
/// was invisible). The collapsed handle shows the count, so an empty map says
/// "waiting" instead of just being a map.
///
/// Pure widget: data and callbacks in, no `Get.find` inside, so it is testable
/// without the map or the socket.
class LiveDeliveriesSheet extends StatelessWidget {
  const LiveDeliveriesSheet({
    super.key,
    required this.deliveries,
    required this.colorFor,
    required this.selectedRequestId,
    required this.onSelect,
    required this.onClearSelection,
    required this.onCall,
    required this.onCenter,
    this.initialChildSize = collapsedSize,
  });

  /// Height fraction that shows the handle plus the one-line summary.
  static const double collapsedSize = 0.11;

  final List<RiderLocationModel> deliveries;
  final Color Function(String requestId) colorFor;
  final String? selectedRequestId;
  final ValueChanged<String> onSelect;
  final VoidCallback onClearSelection;
  final ValueChanged<RiderLocationModel> onCall;
  final ValueChanged<String> onCenter;
  final double initialChildSize;

  @override
  Widget build(BuildContext context) {
    return BDraggableBottomSheet(
      initialChildSize: initialChildSize,
      minChildSize: collapsedSize,
      maxChildSize: 0.6,
      horizontalPadding: BSizes.md,
      body: LiveDeliveriesBody(
        deliveries: deliveries,
        colorFor: colorFor,
        selectedRequestId: selectedRequestId,
        onSelect: onSelect,
        onClearSelection: onClearSelection,
        onCall: onCall,
        onCenter: onCenter,
      ),
    );
  }
}

/// The sheet's content: summary line, then either the list or the selected card.
class LiveDeliveriesBody extends StatelessWidget {
  const LiveDeliveriesBody({
    super.key,
    required this.deliveries,
    required this.colorFor,
    required this.selectedRequestId,
    required this.onSelect,
    required this.onClearSelection,
    required this.onCall,
    required this.onCenter,
  });

  final List<RiderLocationModel> deliveries;
  final Color Function(String requestId) colorFor;
  final String? selectedRequestId;
  final ValueChanged<String> onSelect;
  final VoidCallback onClearSelection;
  final ValueChanged<RiderLocationModel> onCall;
  final ValueChanged<String> onCenter;

  static String summaryFor(int count) {
    if (count == 0) return 'Waiting for dispatched deliveries';
    return count == 1 ? '1 live delivery' : '$count live deliveries';
  }

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    RiderLocationModel? selected;
    for (final d in deliveries) {
      if (d.requestId == selectedRequestId) {
        selected = d;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary — the collapsed sheet shows exactly this line.
        Padding(
          padding: const EdgeInsets.only(bottom: BSizes.sm),
          child: Row(
            children: [
              Icon(Iconsax.truck_fast,
                  size: BSizes.iconSm, color: textColor.withValues(alpha: 0.6)),
              const SizedBox(width: BSizes.sm),
              Expanded(
                child: Text(
                  summaryFor(deliveries.length),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
        // The card slides in over the list (200 ms ease-out) and out faster
        // (140 ms). Selecting a car happens many times a day, so the marker
        // itself does not animate — only the panel that replaces the list.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          reverseDuration: const Duration(milliseconds: 140),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, if (current != null) current],
          ),
          child: selected != null
              ? _card(selected)
              : Column(
                  key: const ValueKey('list'),
                  children: [
                    if (deliveries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: BSizes.md),
                        child: Text(
                          'Live couriers appear here as soon as they press Dispatch.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textColor.withValues(alpha: 0.6)),
                        ),
                      ),
                    for (final d in deliveries)
                      _DeliveryRow(
                        delivery: d,
                        color: colorFor(d.requestId),
                        textColor: textColor,
                        onTap: () => onSelect(d.requestId),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

extension on LiveDeliveriesBody {
  Widget _card(RiderLocationModel selected) => SelectedDeliveryCard(
        key: ValueKey('card_${selected.requestId}'),
        delivery: selected,
        color: colorFor(selected.requestId),
        onClose: onClearSelection,
        onCall: () => onCall(selected),
        onCenter: () => onCenter(selected.requestId),
      );
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({
    required this.delivery,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final RiderLocationModel delivery;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The dot matches the car colour on the map.
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: BSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.client.isEmpty ? 'Dispatch' : delivery.client,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall?.copyWith(color: textColor),
                  ),
                  Text(
                    delivery.requestId,
                    style: theme.labelSmall
                        ?.copyWith(color: textColor.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: BSizes.xs),
                  Text(
                    deliveryMetaLine(delivery),
                    style: theme.bodySmall?.copyWith(color: textColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BSizes.sm),
            Icon(Iconsax.arrow_right_3,
                size: BSizes.iconSm, color: textColor.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

/// One card for the tapped car: who, which request, how far, and the two
/// things a dispatcher actually does from here.
class SelectedDeliveryCard extends StatelessWidget {
  const SelectedDeliveryCard({
    super.key,
    required this.delivery,
    required this.color,
    required this.onClose,
    required this.onCall,
    required this.onCenter,
  });

  final RiderLocationModel delivery;
  final Color color;
  final VoidCallback onClose;
  final VoidCallback onCall;
  final VoidCallback onCenter;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: BSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.client.isEmpty ? 'Dispatch' : delivery.client,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleMedium?.copyWith(color: textColor),
                  ),
                  Text(
                    delivery.requestId,
                    style: theme.labelSmall
                        ?.copyWith(color: textColor.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('live_delivery_close'),
              tooltip: 'Back to list',
              visualDensity: VisualDensity.compact,
              icon: Icon(Iconsax.close_circle, color: textColor),
              onPressed: onClose,
            ),
          ],
        ),
        const SizedBox(height: BSizes.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                deliveryMetaLine(delivery),
                style: theme.bodyMedium?.copyWith(color: textColor),
              ),
            ),
            if (delivery.status.trim().isNotEmpty)
              StatusChip(status: displayStatus(delivery.status), compact: true),
          ],
        ),
        const SizedBox(height: BSizes.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('live_delivery_call'),
                onPressed: onCall,
                icon: const Icon(Iconsax.call, size: BSizes.iconSm),
                label: const Text('Call'),
              ),
            ),
            const SizedBox(width: BSizes.sm),
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('live_delivery_center'),
                onPressed: onCenter,
                icon: const Icon(Iconsax.gps, size: BSizes.iconSm),
                label: const Text('Center'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `RDR · 1 min · 0.2 km` — no `Label:` prefixes; the values explain themselves.
String deliveryMetaLine(RiderLocationModel d) {
  final parts = <String>[
    if (d.riderInitial.trim().isNotEmpty) d.riderInitial.trim(),
    if (d.eta.trim().isNotEmpty) d.eta.trim(),
    if (d.distance.trim().isNotEmpty) d.distance.trim(),
  ];
  return parts.isEmpty ? 'Waiting for the first position…' : parts.join(' · ');
}

/// The socket sends `en_route`; show it the way the rest of the app does.
String displayStatus(String status) {
  final raw = status.trim();
  if (raw.toLowerCase() == 'en_route') return 'En Route';
  return raw.replaceAll('_', ' ');
}
