import 'package:flutter/material.dart';

/// Standard primary submit button with integrated small loading indicator.
class BSubmitButton extends StatelessWidget {
  const BSubmitButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    this.label = 'Submit',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

