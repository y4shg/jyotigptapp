import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../../core/services/settings_service.dart';

/// Platform-specific utilities for enhanced user experience.
///
/// Provides convenience methods for triggering haptic feedback
/// on supported platforms (iOS and Android).
class PlatformUtils {
  PlatformUtils._();

  /// Whether the current device supports haptic feedback.
  static bool get supportsHaptics => Platform.isIOS || Platform.isAndroid;

  static bool get _hapticsEnabled =>
      supportsHaptics && SettingsService.isHapticFeedbackEnabled;

  /// Trigger light haptic feedback.
  static void lightHaptic() {
    if (_hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Trigger medium haptic feedback.
  ///
  /// Uses medium impact on iOS; falls back to light impact on
  /// Android where medium is not always distinguishable.
  static void mediumHaptic() {
    if (_hapticsEnabled && Platform.isIOS) {
      HapticFeedback.mediumImpact();
    } else if (_hapticsEnabled && Platform.isAndroid) {
      HapticFeedback.lightImpact();
    }
  }

  /// Trigger heavy haptic feedback.
  ///
  /// Uses heavy impact on iOS; falls back to a vibration on
  /// Android.
  static void heavyHaptic() {
    if (_hapticsEnabled && Platform.isIOS) {
      HapticFeedback.heavyImpact();
    } else if (_hapticsEnabled && Platform.isAndroid) {
      HapticFeedback.vibrate();
    }
  }

  /// Trigger selection haptic feedback.
  static void selectionHaptic() {
    if (_hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }
}
