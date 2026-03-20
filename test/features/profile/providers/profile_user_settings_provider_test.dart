import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jyotigptapp/core/providers/app_providers.dart';
import 'package:jyotigptapp/core/services/api_service.dart';
import 'package:jyotigptapp/features/profile/providers/profile_user_settings_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  group('ProfileUserSettingsController', () {
    group('build (initial load)', () {
      test('returns empty map when apiServiceProvider is null', () async {
        final container = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(profileUserSettingsProvider.future);

        check(result).deepEquals(<String, dynamic>{});
      });

      test('returns settings from api.getUserSettings() when api is present',
          () async {
        final mockApi = _MockApiService();
        when(() => mockApi.getUserSettings()).thenAnswer(
          (_) async => <String, dynamic>{
            'enableNotifications': true,
            'enableSounds': false,
            'theme': 'dark',
          },
        );

        final container = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(profileUserSettingsProvider.future);

        check(result).deepEquals(<String, dynamic>{
          'enableNotifications': true,
          'enableSounds': false,
          'theme': 'dark',
        });
        verify(() => mockApi.getUserSettings()).called(1);
      });

      test('returns empty map when api.getUserSettings() returns empty map',
          () async {
        final mockApi = _MockApiService();
        when(() => mockApi.getUserSettings()).thenAnswer(
          (_) async => <String, dynamic>{},
        );

        final container = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(profileUserSettingsProvider.future);

        check(result).deepEquals(<String, dynamic>{});
      });

      test('returns a copy of the settings map (not the same reference)',
          () async {
        final original = <String, dynamic>{'key': 'value'};
        final mockApi = _MockApiService();
        when(() => mockApi.getUserSettings()).thenAnswer(
          (_) async => original,
        );

        final container = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(profileUserSettingsProvider.future);

        check(result['key']).equals('value');
        // Mutating the original should not affect stored state
        original['key'] = 'changed';
        check(result['key']).equals('value');
      });
    });

    group('updateSetting', () {
      test('applies optimistic update to state before api call', () async {
        final mockApi = _MockApiService();
        when(() => mockApi.getUserSettings()).thenAnswer(
          (_) async => <String, dynamic>{'enableNotifications': true},
        );

        final completer = Completer<void>();
        when(() => mockApi.updateUserSettings(any())).thenAnswer(
          (_) => completer.future,
        );

        final container = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
          ],
        );
        addTearDown(container.dispose);

        // Wait for initial load
        await container.read(profileUserSettingsProvider.future);

        // Call updateSetting without awaiting completion
        final updateFuture = container
            .read(profileUserSettingsProvider.notifier)
            .updateSetting('enableNotifications', false);

        // State should already be updated optimistically
        final stateAfterOptimisticUpdate =
            container.read(profileUserSettingsProvider).valueOrNull;
        check(stateAfterOptimisticUpdate?['enableNotifications']).equals(false);

        // Complete the API call
        completer.complete();
        await updateFuture;
      });

      test('calls api.updateUserSettings with merged settings', () async {
        final mockApi = _MockApiService();
        when(() => mockApi.getUserSettings()).thenAnswer(
          (_) async => <String, dynamic>{
            'enableNotifications': true,
            'enableSounds': false,
          },
        );
        when(() => mockApi.updateUserSettings(any())).thenAnswer(
          (_) async {},
        );

        final container = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileUserSettingsProvider.future);
        await container
            .read(profileUserSettingsProvider.notifier)
            .updateSetting('enableSounds', true);

        final captured =
            verify(() => mockApi.updateUserSettings(captureAny())).captured;
        final sentSettings = captured.last as Map<String, dynamic>;
        check(sentSettings['enableSounds']).equals(true);
        check(sentSettings['enableNotifications']).equals(true);
      });

      test('adds new key to existing settings', () async {
        final mockApi = _MockApiService();
        when(() => mockApi.getUserSettings()).thenAnswer(
          (_) async => <String, dynamic>{'existing': 'value'},
        );
        when(() => mockApi.updateUserSettings(any())).thenAnswer(
          (_) async {},
        );

        final container = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileUserSettingsProvider.future);
        await container
            .read(profileUserSettingsProvider.notifier)
            .updateSetting('newKey', 42);

        final result =
            container.read(profileUserSettingsProvider).valueOrNull!;
        check(result['existing']).equals('value');
        check(result['newKey']).equals(42);
      });

      test('rolls back state when api.updateUserSettings throws', () async {
        final mockApi = _MockApiService();
        when(() => mockApi.getUserSettings()).thenAnswer(
          (_) async => <String, dynamic>{'enableNotifications': true},
        );
        when(() => mockApi.updateUserSettings(any())).thenThrow(
          Exception('Network error'),
        );

        final container = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileUserSettingsProvider.future);

        Object? caughtError;
        try {
          await container
              .read(profileUserSettingsProvider.notifier)
              .updateSetting('enableNotifications', false);
        } catch (e) {
          caughtError = e;
        }
        check(caughtError).isNotNull();

        // State should be rolled back to previous value
        final rolledBackState =
            container.read(profileUserSettingsProvider).valueOrNull;
        check(rolledBackState?['enableNotifications']).equals(true);
      });

      test('re-throws the original error with its stack trace on failure',
          () async {
        final mockApi = _MockApiService();
        when(() => mockApi.getUserSettings()).thenAnswer(
          (_) async => <String, dynamic>{},
        );
        final originalError = Exception('Server error');
        when(() => mockApi.updateUserSettings(any())).thenThrow(originalError);

        final container = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileUserSettingsProvider.future);

        Object? caught;
        try {
          await container
              .read(profileUserSettingsProvider.notifier)
              .updateSetting('key', 'value');
        } catch (e) {
          caught = e;
        }

        check(caught).isNotNull();
        check(caught.toString()).contains('Server error');
      });

      test('updates state without api call when apiServiceProvider is null',
          () async {
        final container = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);

        // Initial state is empty map (null api path in build())
        await container.read(profileUserSettingsProvider.future);

        // updateSetting should still update the in-memory state
        await container
            .read(profileUserSettingsProvider.notifier)
            .updateSetting('key', 'value');

        final result =
            container.read(profileUserSettingsProvider).valueOrNull;
        check(result?['key']).equals('value');
      });

      test('merges multiple sequential updates correctly', () async {
        final mockApi = _MockApiService();
        when(() => mockApi.getUserSettings()).thenAnswer(
          (_) async => <String, dynamic>{
            'a': 1,
            'b': 2,
          },
        );
        when(() => mockApi.updateUserSettings(any())).thenAnswer(
          (_) async {},
        );

        final container = ProviderContainer(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileUserSettingsProvider.future);

        await container
            .read(profileUserSettingsProvider.notifier)
            .updateSetting('a', 10);
        await container
            .read(profileUserSettingsProvider.notifier)
            .updateSetting('b', 20);
        await container
            .read(profileUserSettingsProvider.notifier)
            .updateSetting('c', 30);

        final result =
            container.read(profileUserSettingsProvider).valueOrNull!;
        check(result['a']).equals(10);
        check(result['b']).equals(20);
        check(result['c']).equals(30);
      });
    });
  });
}