import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/storage_providers.dart';

const String _preOnboardingKey = 'pre_onboarding_complete_v1';
const String _postOnboardingKey = 'post_onboarding_complete_v1';

/// Whether the pre-sign-in onboarding has been completed.
final preOnboardingCompleteProvider = AsyncNotifierProvider<
  PreOnboardingCompleteNotifier,
  bool
>(PreOnboardingCompleteNotifier.new);

class PreOnboardingCompleteNotifier extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_preOnboardingKey) ?? false;
  }

  Future<void> setComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preOnboardingKey, true);
    state = const AsyncData(true);
  }
}

/// Whether the post-sign-in onboarding has been completed.
final postOnboardingCompleteProvider = AsyncNotifierProvider<
  PostOnboardingCompleteNotifier,
  bool
>(PostOnboardingCompleteNotifier.new);

class PostOnboardingCompleteNotifier extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() async {
    final storage = ref.read(secureStorageProvider);
    final value = await storage.read(key: _postOnboardingKey);
    return value == 'true';
  }

  Future<void> setComplete() async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: _postOnboardingKey, value: 'true');
    state = const AsyncData(true);
  }
}

