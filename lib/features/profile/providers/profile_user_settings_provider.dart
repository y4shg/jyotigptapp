import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/app_providers.dart';

part 'profile_user_settings_provider.g.dart';

@Riverpod(keepAlive: true)
class ProfileUserSettings extends _$ProfileUserSettings {
  Future<void> _pendingWrite = Future<void>.value();
  Map<String, dynamic>? _lastConfirmedSettings;
  int _clientGeneration = 0;

  @override
  Future<Map<String, dynamic>> build() async {
    final api = ref.watch(apiServiceProvider);
    if (api == null) {
      throw StateError('No API client available for user settings.');
    }

    _clientGeneration++;
    final settings = await api.getUserSettings();
    _lastConfirmedSettings = Map<String, dynamic>.from(settings);
    return _lastConfirmedSettings!;
  }

  Future<void> updateSetting(String key, Object? value) async {
    final api = ref.read(apiServiceProvider);
    if (api == null) {
      throw StateError('No API client available for user settings.');
    }

    final generation = _clientGeneration;

    final current = Map<String, dynamic>.from(
      state.maybeWhen(data: (value) => value, orElse: () => null) ??
          await future,
    );
    final next = Map<String, dynamic>.from(current);
    if (value == null) {
      next.remove(key);
    } else {
      next[key] = value;
    }

    state = AsyncData(next);

    final write = _pendingWrite.then((_) async {
      try {
        await api.updateUserSettings(next);
        if (ref.mounted && generation == _clientGeneration) {
          _lastConfirmedSettings = next;
        }
      } catch (error, stackTrace) {
        final currentState = state.asData?.value;
        if (ref.mounted &&
            generation == _clientGeneration &&
            currentState != null &&
            _mapsEqual(currentState, next)) {
          if (_lastConfirmedSettings != null) {
            state = AsyncData(_lastConfirmedSettings!);
          } else {
            ref.invalidateSelf();
          }
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
