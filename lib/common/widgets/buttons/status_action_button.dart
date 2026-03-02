import 'package:flutter/material.dart';

/// Reusable status-driven action button for logistics modals.
///
/// Maps request statuses to appropriate CTA labels using a provided
/// mapping function. Handles visibility and empty states automatically.
class StatusActionButton extends StatelessWidget {
  /// Current status of the request/item.
  final String? status;

  /// Callback when button is pressed.
  final VoidCallback onPressed;

  /// Whether the button should be visible.
  final bool isVisible;

  /// Function that maps a status to the button text.
  /// Return empty string to hide the button for a specific status.
  final String Function(String? status) statusToTextMapper;

  const StatusActionButton({
    super.key,
    required this.status,
    required this.onPressed,
    required this.isVisible,
    required this.statusToTextMapper,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final label = statusToTextMapper(status);
    if (label.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

