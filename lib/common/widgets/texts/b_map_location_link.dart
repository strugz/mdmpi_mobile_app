import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';

/// A label-value location row that opens Google Maps when given valid coordinates.
class BMapLocationLink extends StatelessWidget {
  const BMapLocationLink({
    super.key,
    required this.label,
    required this.location,
    this.icon = Iconsax.location,
    this.showLabel = true,
    this.padding,
    this.mainAlignment = MainAxisAlignment.start,
    this.maxLines = 2,
    this.iconOnly = false,
  });

  final String label;
  final String location;
  final IconData icon;
  final bool showLabel;
  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment mainAlignment;
  final int maxLines;
  final bool iconOnly;

  static _Coordinates? _parseCoordinates(String rawValue) {
    final normalized = rawValue.trim();
    if (normalized.isEmpty) return null;

    final parts = normalized.split(',');
    if (parts.length != 2) return null;

    final latitude = double.tryParse(parts[0].trim());
    final longitude = double.tryParse(parts[1].trim());
    if (latitude == null || longitude == null) return null;
    if (latitude < -90 || latitude > 90) return null;
    if (longitude < -180 || longitude > 180) return null;

    return _Coordinates(latitude: latitude, longitude: longitude);
  }

  static String _buildGoogleMapsUrl(_Coordinates coordinates) {
    final query = Uri.encodeComponent(
      '${coordinates.latitude},${coordinates.longitude}',
    );
    return 'https://www.google.com/maps/search/?api=1&query=$query';
  }

  Future<void> _openMap(_Coordinates coordinates) async {
    try {
      await BDevicesUtils.launchUrl(_buildGoogleMapsUrl(coordinates));
    } catch (_) {
      BLoaders.errorSnackBar(
        title: 'Map unavailable',
        message: 'Unable to open Google Maps for this location.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = _parseCoordinates(location);
    final canOpenMap = coordinates != null;
    final linkColor = canOpenMap ? Theme.of(context).colorScheme.primary : null;
    final resolvedPadding =
        padding ?? const EdgeInsets.symmetric(vertical: BSizes.xxs);
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: linkColor,
          fontWeight: FontWeight.w600,
        );

    final labelValueText = BLabelValueText(
      label: label,
      value: location,
      icon: icon,
      showLabel: showLabel,
      padding: padding ?? EdgeInsets.zero,
      mainAlignment: mainAlignment,
      maxLines: maxLines,
      textColor: linkColor,
    );

    if (!canOpenMap) {
      return labelValueText;
    }

    if (iconOnly) {
      return Padding(
        padding: resolvedPadding,
        child: Row(
          mainAxisAlignment: mainAlignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLabel && label.isNotEmpty) ...[
              Flexible(
                child: Text(
                  label,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
              const SizedBox(width: BSizes.xs),
            ],
            Tooltip(
              message: label.isNotEmpty
                  ? 'Open $label in Google Maps'
                  : 'Open in Google Maps',
              child: InkWell(
                onTap: () => _openMap(coordinates),
                borderRadius: BorderRadius.circular(BSizes.sm),
                child: Container(
                  padding: const EdgeInsets.all(BSizes.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(BSizes.sm),
                  ),
                  child: Icon(
                    Icons.map_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _openMap(coordinates),
      borderRadius: BorderRadius.circular(BSizes.sm),
      child: Padding(
        padding: resolvedPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: BLabelValueText(
                label: label,
                value: location,
                icon: icon,
                showLabel: showLabel,
                padding: EdgeInsets.zero,
                mainAlignment: mainAlignment,
                maxLines: maxLines,
                textColor: linkColor,
              ),
            ),
            const SizedBox(width: BSizes.xs),
            Icon(
              Icons.map_outlined,
              size: 18,
              color: linkColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _Coordinates {
  const _Coordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
