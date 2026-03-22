import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Platform-specific utilities for enhanced user experience.
///
/// Provides convenience methods for triggering haptic feedback
/// on supported platforms (iOS and Android).
class PlatformUtils {
  PlatformUtils._();

  /// Whether the current device supports haptic feedback.
  static bool get supportsHaptics => Platform.isIOS || Platform.isAndroid;

  static bool _isHapticsEnabled(bool enabled) =>
      supportsHaptics && enabled;

  /// Trigger light haptic feedback.
  static void lightHaptic({required bool enabled}) {
    if (_isHapticsEnabled(enabled)) {
      HapticFeedback.lightImpact();
    }
  }

  /// Trigger medium haptic feedback.
  ///
  /// Uses medium impact on iOS; falls back to light impact on
  /// Android where medium is not always distinguishable.
  static void mediumHaptic({required bool enabled}) {
    if (_isHapticsEnabled(enabled) && Platform.isIOS) {
      HapticFeedback.mediumImpact();
    } else if (_isHapticsEnabled(enabled) && Platform.isAndroid) {
      HapticFeedback.lightImpact();
    }
  }

  /// Trigger heavy haptic feedback.
  ///
  /// Uses heavy impact on iOS; falls back to a vibration on
  /// Android.
  static void heavyHaptic({required bool enabled}) {
    if (_isHapticsEnabled(enabled) && Platform.isIOS) {
      HapticFeedback.heavyImpact();
    } else if (_isHapticsEnabled(enabled) && Platform.isAndroid) {
      HapticFeedback.vibrate();
    }
  }

  /// Trigger selection haptic feedback.
  static void selectionHaptic({required bool enabled}) {
    if (_isHapticsEnabled(enabled)) {
      HapticFeedback.selectionClick();
    }
  }
}
