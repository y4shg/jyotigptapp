import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/app_providers.dart';

part 'profile_user_settings_provider.g.dart';

@Riverpod(keepAlive: true)
class ProfileUserSettings extends _$ProfileUserSettings {
  Future<void> _pendingWrite = Future<void>.value();

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
    final api = ref.read(apiServiceProvider);
    if (api == null) {
      throw StateError('No API client available for user settings.');
    }

    final current = Map<String, dynamic>.from(
      state.maybeWhen(data: (value) => value, orElse: () => null) ??
          await future,
    );
    final previous = Map<String, dynamic>.from(current);
    final next = <String, dynamic>{...current, key: value};

    state = AsyncData(next);

    final write = _pendingWrite.then((_) async {
      try {
        await api.updateUserSettings(next);
      } catch (error, stackTrace) {
        final currentState = state.asData?.value;
        if (currentState != null && _mapsEqual(currentState, next)) {
          state = AsyncData(previous);
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
    });

    _pendingWrite = write.catchError((_) {});
    await write;
  }

  bool _mapsEqual(Map<String, dynamic> left, Map<String, dynamic> right) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
