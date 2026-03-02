import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';

/// Widget for reviewing and confirming captured photos
/// Shows full-screen image with confirm and retake options
  class BPhotoReviewScreen extends StatelessWidget {
  final String imagePath;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;
  final String title;

  const BPhotoReviewScreen({
    super.key,
    required this.imagePath,
    required this.onConfirm,
    required this.onRetake,
    this.title = 'Review Photo',
  });

  @override
  Widget build(BuildContext context) {
    logDebug('📸 Displaying photo review for: $imagePath');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        logDebug('🔄 User pressed back - triggering retake');
        onRetake();
      },
      child: SafeArea(
        child: Scaffold(
          appBar: BAppBar(
            leadingOnPressed: onRetake,
          ),
          body: Column(
            children: [
              /// Captured photo display - full screen
              Expanded(
                child: Center(
                  child: _buildPhotoDisplay(),
                ),
              ),

              /// Action buttons - confirm and retake
              Container(
                padding: const EdgeInsets.all(BSizes.defaultSpace),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    /// Retake button
                    ElevatedButton.icon(
                      onPressed: () {
                        logDebug('🔄 Retake button pressed');
                        onRetake();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),

                    /// Confirm button
                    ElevatedButton.icon(
                      onPressed: () {
                        logDebug('✅ Photo confirmed');
                        onConfirm();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build photo display widget with error handling
  Widget _buildPhotoDisplay() {
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        logDebug('❌ Error loading image: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );
  }
}
