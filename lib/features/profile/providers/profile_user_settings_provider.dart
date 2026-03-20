import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final profileUserSettingsProvider = AsyncNotifierProvider<
    ProfileUserSettingsController, Map<String, dynamic>>(
  ProfileUserSettingsController.new,
);

class ProfileUserSettingsController
    extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final api = ref.watch(apiServiceProvider);
    if (api == null) {
      return <String, dynamic>{};
    }

    final settings = await api.getUserSettings();
    return Map<String, dynamic>.from(settings);
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final current = Map<String, dynamic>.from(
      state.maybeWhen(data: (value) => value, orElse: () => null) ??
          await future,
    );
    final previous = Map<String, dynamic>.from(current);
    final next = <String, dynamic>{...current, key: value};

    state = AsyncData(next);

    final api = ref.read(apiServiceProvider);
    if (api == null) {
      return;
    }

    try {
      await api.updateUserSettings(next);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
