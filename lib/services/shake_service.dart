import 'package:shake/shake.dart';
import 'package:flutter/services.dart';
import 'package:sukh_app/main.dart';
import 'package:sukh_app/widgets/help_modal.dart';

// Platform channel for direct vibration
const MethodChannel _vibrationChannel = MethodChannel('com.sukh_app/vibration');

class ShakeService {
  static ShakeDetector? _shakeDetector;
  static bool _isInitialized = false;
  static bool _isModalShowing = false;
  static DateTime? _lastModalShownTime;

  /// Initialize shake detection
  static void initialize() {
    // Stop existing detector if any
    if (_shakeDetector != null) {
      try {
        _shakeDetector?.stopListening();
      } catch (e) {
        // Silent fail
      }
      _shakeDetector = null;
      _isInitialized = false;
    }

    // Skip if already initialized (unless we just stopped it)
    if (_isInitialized) {
      return;
    }

    try {
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: (ShakeEvent event) {
          // Always trigger vibration first (even if modal is blocked)
          _triggerVibration();

          // Prevent multiple modals from stacking
          if (_isModalShowing) {
            return;
          }

          // Cooldown period - prevent opening modal too frequently (2 seconds)
          final now = DateTime.now();
          if (_lastModalShownTime != null) {
            final timeSinceLastModal = now.difference(_lastModalShownTime!);
            if (timeSinceLastModal.inSeconds < 2) {
              return;
            }
          }

          // Show modal
          _showHelpModal();
        },
        minimumShakeCount: 1,
        shakeSlopTimeMS: 500,
        shakeCountResetTime: 3000,
        shakeThresholdGravity: 1.2,
      );

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  /// Trigger vibration feedback when shake is detected
  static void _triggerVibration() {
    _triggerVibrationAsync();
  }

  /// Async vibration using platform channel for actual device vibration
  static void _triggerVibrationAsync() async {
    try {
      // Use platform channel for direct Android vibration (actual motor vibration)
      // Single gentle vibration: [0ms delay, 200ms vibrate]
      final pattern = <int>[
        0,
        200,
      ]; // [delay, vibrate] - single gentle vibration
      await _vibrationChannel.invokeMethod('vibrate', {
        'pattern': pattern.map((e) => e.toInt()).toList(),
        'repeat': -1, // Don't repeat
      });
    } catch (e) {
      // Fallback to HapticFeedback if platform channel fails
      _triggerHapticFeedback();
    }
  }

  /// Fallback haptic feedback (if platform channel fails)
  static void _triggerHapticFeedback() {
    try {
      // Single gentle haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {}
  }

  /// Show help modal when shake is detected
  static void _showHelpModal() {
    // Prevent showing if already showing
    if (_isModalShowing) {
      return;
    }

    final context = navigatorKey.currentContext;
    if (context != null) {
      _isModalShowing = true;
      _lastModalShownTime = DateTime.now();
      showHelpModal(context).then((_) {
        // Reset flag when modal is closed
        _isModalShowing = false;
      });
    } else {
      // Try again after a short delay if context is not ready
      Future.delayed(const Duration(milliseconds: 500), () {
        final retryContext = navigatorKey.currentContext;
        if (retryContext != null && !_isModalShowing) {
          _isModalShowing = true;
          _lastModalShownTime = DateTime.now();
          showHelpModal(retryContext).then((_) {
            _isModalShowing = false;
          });
        }
      });
    }
  }

  /// Stop shake detection
  static void stop() {
    _shakeDetector?.stopListening();
    _isInitialized = false;
  }

  /// Dispose shake detector
  static void dispose() {
    try {
      _shakeDetector?.stopListening();
    } catch (e) {
      // Silent fail
    }
    _shakeDetector = null;
    _isInitialized = false;
    _isModalShowing = false;
    _lastModalShownTime = null;
  }

  /// Manually trigger help modal (for testing)
  static void showHelpManually() {
    _triggerVibration();
    _showHelpModal();
  }

  /// Test vibration only (for debugging)
  static void testVibration() {
    _triggerVibration();
  }
}
