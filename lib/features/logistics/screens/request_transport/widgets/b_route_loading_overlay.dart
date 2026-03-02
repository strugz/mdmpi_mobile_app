import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/logger.dart';
import '../../../controllers/request_transport_controller.dart';

/// Widget for displaying route loading overlay with auto-retry functionality
class RouteLoadingOverlay extends StatefulWidget {
  const RouteLoadingOverlay({super.key});

  @override
  State<RouteLoadingOverlay> createState() => _RouteLoadingOverlayState();
}

class _RouteLoadingOverlayState extends State<RouteLoadingOverlay> {
  late Timer _retryTimer;
  late Timer _countdownTimer;
  int _retryCount = 0;
  int _remainingSeconds = 15;
  static const int _timeoutSeconds = 15;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _startRetryTimer();
  }

  /// Start the retry timer that triggers if route doesn't load within timeout
  void _startRetryTimer() {
    _remainingSeconds = _timeoutSeconds;

    // Start countdown timer that updates every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
      }

      // When countdown reaches 0, trigger retry
      if (_remainingSeconds <= 0) {
        timer.cancel();
        logDebug('⏱️ Route loading timeout - retry attempt ${_retryCount + 1}/$_maxRetries');

        if (_retryCount < _maxRetries) {
          _retryCount++;
          if (mounted) {
            setState(() {}); // Trigger rebuild to update retry count
          }

          try {
            final controller = Get.find<RequestTransportController>();
            logDebug('🔄 Retrying route initialization...');
            controller.initializeRoute();
            // Start another timer for the next retry
            _startRetryTimer();
          } catch (e) {
            logDebug('❌ Error during retry: $e');
          }
        } else {
          _showMaxRetriesReached();
        }
      }
    });
  }

  /// Show message when max retries reached
  void _showMaxRetriesReached() {
    logDebug('❌ Max retries reached ($_maxRetries attempts)');

    Get.snackbar(
      'Route Loading Failed',
      'Unable to load route after $_maxRetries attempts. Please check your internet connection and try again.',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Card(
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(BColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading Route...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we calculate\nthe route to your destination',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Attempt ${_retryCount + 1}/$_maxRetries',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Retrying in $_remainingSeconds seconds...',
                  style: TextStyle(
                    fontSize: 12,
                    color: BColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
