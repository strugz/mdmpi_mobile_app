import 'package:flutter/material.dart';

/// Action button for Pull-Out modal.
///
/// Maps Pull-Out statuses to appropriate CTA labels. Keep UI logic here
/// so modals/controllers remain clean.
class BPullOutActionButton extends StatelessWidget {
  final String? status;
  final VoidCallback onPressed;
  final bool isVisible;

  const BPullOutActionButton({
    super.key,
    required this.status,
    required this.onPressed,
    required this.isVisible,
  });

  String _getButtonText() {
    if (status == null) return 'Proceed';
    switch (status) {
      case 'New Request':
        return 'Set In Transit';
      case 'In Transit':
        return 'Mark Taken Out';
      case 'Taken Out':
        return '';
      default:
        return 'Proceed';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final label = _getButtonText();
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
