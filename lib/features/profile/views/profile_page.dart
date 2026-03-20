import 'dart:convert';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;

import '../../../core/models/user.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/user_avatar_utils.dart';
import '../../../core/utils/user_display_name.dart';
import '../../../core/widgets/error_boundary.dart';
import '../../../features/auth/providers/unified_auth_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/utils/ui_utils.dart';
import '../../../shared/widgets/jyotigptapp_components.dart';
import '../../../shared/widgets/jyotigptapp_loading.dart';
import '../../../shared/widgets/themed_dialogs.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../chat/services/voice_call_notification_service.dart';
import '../providers/profile_user_settings_provider.dart';
import '../widgets/adaptive_segmented_selector.dart';
import '../widgets/profile_setting_tile.dart';

/// Profile page (You tab) showing account information and basic preferences.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useAdaptivePlatformChrome = PlatformInfo.isIOS;
    final useNativeToolbar = PlatformInfo.isIOS26OrHigher();
    final authUser = ref.watch(currentUserProvider2);
    final asyncUser = ref.watch(currentUserProvider);
    final user = asyncUser.maybeWhen(
      data: (value) => value ?? authUser,
      orElse: () => authUser,
    );
    final isAuthLoading = ref.watch(isAuthLoadingProvider2);
    final api = ref.watch(apiServiceProvider);

    final body = isAuthLoading && user == null
        ? _buildCenteredState(
            context,
            ImprovedLoadingState(
              message: AppLocalizations.of(context)!.loadingProfile,
            ),
            useAdaptivePlatformChrome: useAdaptivePlatformChrome,
          )
        : _buildProfileBody(
            context,
            ref,
            user,
            api,
            useAdaptivePlatformChrome: useAdaptivePlatformChrome,
          );

    return ErrorBoundary(
      child: _buildScaffold(
        context,
        body: body,
        useAdaptivePlatformChrome: useAdaptivePlatformChrome,
        useNativeToolbar: useNativeToolbar,
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required Widget body,
    required bool useAdaptivePlatformChrome,
    required bool useNativeToolbar,
  }) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final l10n = AppLocalizations.of(context)!;
    final theme = context.jyotigptappTheme;

    if (useAdaptivePlatformChrome) {
      return AdaptiveScaffold(
        appBar: AdaptiveAppBar(
          title: l10n.you,
          useNativeToolbar: useNativeToolbar,
        ),
        body: ColoredBox(color: theme.surfaceBackground, child: body),
      );
    }

    return Scaffold(
      backgroundColor: theme.surfaceBackground,
      extendBodyBehindAppBar: true,
      appBar: FloatingAppBar(
        leading: canPop ? const FloatingAppBarBackButton() : null,
        title: FloatingAppBarTitle(text: l10n.you),
      ),
      body: body,
    );
  }

  Widget _buildCenteredState(
    BuildContext context,
    Widget child, {
    required bool useAdaptivePlatformChrome,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = useAdaptivePlatformChrome
        ? Spacing.lg
        : (mediaQuery.padding.top + kToolbarHeight + 40);

    return SafeArea(
      top: useAdaptivePlatformChrome,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Spacing.pagePadding,
          topPadding,
          Spacing.pagePadding,
          Spacing.pagePadding + mediaQuery.padding.bottom,
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildProfileBody(
    BuildContext context,
    WidgetRef ref,
    dynamic userData,
    ApiService? api, {
    required bool useAdaptivePlatformChrome,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = useAdaptivePlatformChrome
        ? Spacing.lg
        : (mediaQuery.padding.top + kToolbarHeight + 40);

    return SafeArea(
      top: useAdaptivePlatformChrome,
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          Spacing.pagePadding,
          topPadding,
          Spacing.pagePadding,
          Spacing.pagePadding + mediaQuery.padding.bottom,
        ),
        children: [
          _buildProfileHeader(context, userData, api),
          const SizedBox(height: Spacing.xl),
          _buildProfileSection(context, ref, userData, api),
          const SizedBox(height: Spacing.xl),
          _buildPreferencesSection(context, ref),
          const SizedBox(height: Spacing.xl),
          _buildBackendSettingsSection(context, ref),
          const SizedBox(height: Spacing.xl),
          _buildAccountSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    dynamic user,
    ApiService? api,
  ) {
    final displayName = deriveUserDisplayName(user);
    final characters = displayName.characters;
    final initial =
        characters.isNotEmpty ? characters.first.toUpperCase() : 'U';
    final avatarUrl = resolveUserAvatarUrlForUser(api, user);
    final email = _extractEmail(user) ?? '';
    final theme = context.jyotigptappTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.sidebarAccent.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border: Border.all(
          color: theme.sidebarBorder.withValues(alpha: 0.6),
          width: BorderWidth.thin,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(size: 56, imageUrl: avatarUrl, fallbackText: initial),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isEmpty ? 'User' : displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.headingMedium?.copyWith(
                    color: theme.sidebarForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: Spacing.xs),
                  Row(
                    children: [
                      Icon(
                        UiUtils.platformIcon(
                          ios: CupertinoIcons.envelope,
                          android: Icons.mail_outline,
                        ),
                        size: IconSize.small,
                        color: theme.sidebarForeground.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: Spacing.xs),
                      Flexible(
                        child: Text(
                          email,
                          style: theme.bodySmall?.copyWith(
                            color: theme.sidebarForeground.withValues(
                              alpha: 0.75,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    ApiService? api,
  ) {
    final theme = context.jyotigptappTheme;
    final headingStyle = theme.headingSmall?.copyWith(
      color: theme.sidebarForeground,
    );
    final displayName = deriveUserDisplayName(user);
    final avatarUrl = resolveUserAvatarUrlForUser(api, user);
    final email = _extractEmail(user) ?? 'Signed in account';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headingStyle != null)
          Text('Profile', style: headingStyle)
        else
          const Text('Profile'),
        const SizedBox(height: Spacing.sm),
        ProfileSettingTile(
          onTap: () => _changeProfilePhoto(context, ref),
          leading: _buildIconBadge(
            context,
            UiUtils.platformIcon(
              ios: CupertinoIcons.camera,
              android: Icons.photo_camera_outlined,
            ),
            color: theme.buttonPrimary,
          ),
          title: 'Profile picture',
          subtitle: 'Choose a new photo for this device.',
          trailing: UserAvatar(
            size: 32,
            imageUrl: avatarUrl,
            fallbackText: displayName.characters.isNotEmpty
                ? displayName.characters.first.toUpperCase()
                : 'U',
          ),
          showChevron: false,
        ),
        const SizedBox(height: Spacing.md),
        ProfileSettingTile(
          onTap: () => _changeDisplayName(context, ref, user),
          leading: _buildIconBadge(
            context,
            UiUtils.platformIcon(
              ios: CupertinoIcons.person_crop_circle,
              android: Icons.badge_outlined,
            ),
            color: theme.buttonPrimary,
          ),
          title: 'Display name',
          subtitle: displayName.isEmpty ? 'Set your name' : displayName,
        ),
        const SizedBox(height: Spacing.md),
        ProfileSettingTile(
          leading: _buildIconBadge(
            context,
            UiUtils.platformIcon(
              ios: CupertinoIcons.mail,
              android: Icons.alternate_email,
            ),
            color: theme.buttonPrimary,
          ),
          title: 'Email',
          subtitle: email,
          showChevron: false,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final themeModeNotifier = ref.read(appThemeModeProvider.notifier);
    final voiceCallNotificationsEnabled = ref.watch(
      appSettingsProvider.select((s) => s.voiceCallNotificationsEnabled),
    );
    final backendSettings = ref.watch(profileUserSettingsProvider);
    final accountNotificationsEnabled = backendSettings.maybeWhen(
      data: (settings) => _readBoolSetting(settings, 'enableNotifications'),
      orElse: () => true,
    );
    final notificationsEnabled =
        voiceCallNotificationsEnabled && accountNotificationsEnabled;
    final theme = context.jyotigptappTheme;
    final headingStyle = theme.headingSmall?.copyWith(
      color: theme.sidebarForeground,
    );
    final appLocale = ref.watch(appLocaleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headingStyle != null)
          Text('App', style: headingStyle)
        else
          const Text('App'),
        const SizedBox(height: Spacing.sm),
        JyotiGPTappCard(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme',
                style: theme.bodyMedium?.copyWith(
                  color: theme.sidebarForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              ThemeModeSegmentedControl(
                value: themeMode,
                onChanged: themeModeNotifier.setTheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        ProfileSettingTile(
          onTap: () => _changeLanguage(context, ref),
          leading: _buildIconBadge(
            context,
            UiUtils.platformIcon(
              ios: CupertinoIcons.globe,
              android: Icons.language,
            ),
            color: theme.buttonPrimary,
          ),
          title: 'Language',
          subtitle: _languageLabel(context, appLocale),
        ),
        const SizedBox(height: Spacing.md),
        ProfileSettingTile(
          leading: _buildIconBadge(
            context,
            UiUtils.platformIcon(
              ios: CupertinoIcons.bell,
              android: Icons.notifications_none,
            ),
            color: theme.buttonPrimary,
          ),
          title: 'Notifications',
          subtitle:
              'Enable notifications and voice call controls for this device.',
          onTap: () => _toggleNotifications(context, ref, !notificationsEnabled),
          trailing: AdaptiveSwitch(
            value: notificationsEnabled,
            onChanged: (value) => _toggleNotifications(context, ref, value),
          ),
          showChevron: false,
        ),
      ],
    );
  }

  Widget _buildBackendSettingsSection(BuildContext context, WidgetRef ref) {
    final theme = context.jyotigptappTheme;
    final headingStyle = theme.headingSmall?.copyWith(
      color: theme.sidebarForeground,
    );
    final backendSettings = ref.watch(profileUserSettingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headingStyle != null)
          Text('Account settings', style: headingStyle)
        else
          const Text('Account settings'),
        const SizedBox(height: Spacing.sm),
        backendSettings.when(
          data: (settings) => Column(
            children: [
              _buildBackendToggleTile(
                context,
                ref,
                settings: settings,
                keyName: 'enableSounds',
                title: 'Sounds',
                subtitle: 'Play sounds for account-level interactions.',
                iosIcon: CupertinoIcons.speaker_2,
                androidIcon: Icons.volume_up_outlined,
              ),
              const SizedBox(height: Spacing.md),
              _buildBackendToggleTile(
                context,
                ref,
                settings: settings,
                keyName: 'hapticFeedback',
                title: 'Haptic feedback',
                subtitle: 'Use tactile feedback when the backend supports it.',
                iosIcon: CupertinoIcons.hand_raised,
                androidIcon: Icons.vibration_outlined,
              ),
            ],
          ),
          error: (_, __) => JyotiGPTappCard(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text(
              'Unable to load account settings right now.',
              style: theme.bodyMedium?.copyWith(
                color: theme.sidebarForeground,
              ),
            ),
          ),
          loading: () => const JyotiGPTappCard(
            padding: EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: Spacing.sm),
                Expanded(child: Text('Loading account settings...')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackendToggleTile(
    BuildContext context,
    WidgetRef ref, {
    required Map<String, dynamic> settings,
    required String keyName,
    required String title,
    required String subtitle,
    required IconData iosIcon,
    required IconData androidIcon,
  }) {
    final theme = context.jyotigptappTheme;
    final value = _readBoolSetting(settings, keyName);

    return ProfileSettingTile(
      leading: _buildIconBadge(
        context,
        UiUtils.platformIcon(ios: iosIcon, android: androidIcon),
        color: theme.buttonPrimary,
      ),
      title: title,
      subtitle: subtitle,
      onTap: () => _updateBackendSetting(
        context,
        ref,
        settings,
        keyName,
        !value,
      ),
      trailing: AdaptiveSwitch(
        value: value,
        onChanged: (next) => _updateBackendSetting(
          context,
          ref,
          settings,
          keyName,
          next,
        ),
      ),
      showChevron: false,
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    final theme = context.jyotigptappTheme;
    final headingStyle = theme.headingSmall?.copyWith(
      color: theme.sidebarForeground,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headingStyle != null)
          Text('Account', style: headingStyle)
        else
          const Text('Account'),
        const SizedBox(height: Spacing.sm),
        _buildAboutTile(context),
        const SizedBox(height: Spacing.md),
        ProfileSettingTile(
          onTap: () => _signOut(context, ref),
          leading: _buildIconBadge(
            context,
            UiUtils.platformIcon(
              ios: CupertinoIcons.square_arrow_left,
              android: Icons.logout,
            ),
            color: theme.buttonPrimary,
          ),
          title: AppLocalizations.of(context)!.signOut,
          subtitle: AppLocalizations.of(context)!.endYourSession,
          showChevron: false,
        ),
      ],
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return ProfileSettingTile(
      onTap: () => _showAboutDialog(context),
      leading: _buildIconBadge(
        context,
        UiUtils.platformIcon(
          ios: CupertinoIcons.info,
          android: Icons.info_outline,
        ),
        color: context.jyotigptappTheme.buttonPrimary,
      ),
      title: AppLocalizations.of(context)!.aboutApp,
      subtitle: AppLocalizations.of(context)!.aboutAppSubtitle,
    );
  }

  Future<void> _changeDisplayName(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) async {
    final initialValue = deriveUserDisplayName(user).trim();
    final result = await AdaptiveAlertDialog.inputShow(
      context: context,
      title: 'Change display name',
      message: 'Update the name shown in the app.',
      icon: 'person.text.rectangle',
      input: AdaptiveAlertDialogInput(
        placeholder: 'Your name',
        initialValue: initialValue,
        keyboardType: TextInputType.name,
      ),
      actions: [
        AlertAction(
          title: 'Cancel',
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: 'Save',
          style: AlertActionStyle.primary,
          onPressed: () {},
        ),
      ],
    );

    if (!context.mounted || result == null) {
      return;
    }

    final nextName = result.toString().trim();
    if (nextName.isEmpty || nextName == initialValue) {
      return;
    }

    final editableUser = _resolveEditableUser(user);
    if (editableUser == null) {
      UiUtils.showMessage(
        context,
        'Unable to update your profile right now.',
      );
      return;
    }

    final updatedUser = editableUser.copyWith(name: nextName);
    final storage = ref.read(optimizedStorageServiceProvider);
    await storage.saveLocalUser(updatedUser);
    ref.invalidate(currentUserProvider);

    if (!context.mounted) {
      return;
    }

    UiUtils.showMessage(
      context,
      'Display name updated on this device. Server profile sync is not available yet.',
    );
  }

  Future<void> _changeProfilePhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );

    if (!context.mounted || image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    final dataUrl = _imageDataUrl(bytes, image.path);
    final storage = ref.read(optimizedStorageServiceProvider);
    final asyncUser = ref.read(currentUserProvider);
    final currentUser = _resolveEditableUser(
      asyncUser.maybeWhen(
        data: (value) => value ?? ref.read(currentUserProvider2),
        orElse: () => ref.read(currentUserProvider2),
      ),
    );

    await storage.saveLocalUserAvatar(dataUrl);
    if (currentUser != null) {
      await storage.saveLocalUser(
        currentUser.copyWith(profileImage: dataUrl),
      );
    }
    ref.invalidate(currentUserProvider);

    if (!context.mounted) {
      return;
    }

    UiUtils.showMessage(
      context,
      'Profile picture updated on this device. Server profile sync is not available yet.',
    );
  }

  Future<void> _changeLanguage(BuildContext context, WidgetRef ref) async {
    final selected = await _showLanguagePicker(context, ref);
    if (!context.mounted) {
      return;
    }

    if (selected == null) {
      return;
    }

    final notifier = ref.read(appLocaleProvider.notifier);
    await notifier.setLocale(selected.locale);

    final resolvedLocale = selected.locale ?? Localizations.localeOf(context);
    try {
      await ref
          .read(profileUserSettingsProvider.notifier)
          .updateSetting('language', resolvedLocale.toLanguageTag());
    } catch (_) {
      if (context.mounted) {
        UiUtils.showMessage(
          context,
          'Language changed locally, but account sync failed.',
        );
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    UiUtils.showMessage(context, 'Language updated.');
  }

  Future<_LanguagePickerValue?> _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentLocale = ref.read(appLocaleProvider);
    final options = <_LanguagePickerValue>[
      const _LanguagePickerValue(
        label: 'System default',
        locale: null,
      ),
      for (final locale in AppLocalizations.supportedLocales)
        _LanguagePickerValue(
          locale: locale,
          label: _languageLabel(context, locale),
        ),
    ];

    if (PlatformInfo.isIOS) {
      return showCupertinoModalPopup<_LanguagePickerValue>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('App language'),
          actions: [
            for (final option in options)
              CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(option),
                isDefaultAction: option.locale == currentLocale,
                child: Text(option.label),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    }

    return showModalBottomSheet<_LanguagePickerValue>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = context.jyotigptappTheme;
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final option = options[index];
              return ListTile(
                title: Text(option.label),
                trailing: option.locale == currentLocale
                    ? Icon(
                        Icons.check,
                        color: theme.buttonPrimary,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _toggleNotifications(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    if (!enabled) {
      await settingsNotifier.setVoiceCallNotificationsEnabled(false);
      await _updateBackendSetting(
        context,
        ref,
        const <String, dynamic>{},
        'enableNotifications',
        false,
      );
      return;
    }

    await VoiceCallNotificationService().initialize();
    final granted = await VoiceCallNotificationService().requestPermissions();
    if (!context.mounted) {
      return;
    }

    if (!granted) {
      await settingsNotifier.setVoiceCallNotificationsEnabled(false);
      await _updateBackendSetting(
        context,
        ref,
        const <String, dynamic>{},
        'enableNotifications',
        false,
      );
      UiUtils.showMessage(
        context,
        'Notifications were not enabled. Check system settings if needed.',
      );
      return;
    }

    await settingsNotifier.setVoiceCallNotificationsEnabled(true);
    await _updateBackendSetting(
      context,
      ref,
      const <String, dynamic>{},
      'enableNotifications',
      true,
    );
    if (context.mounted) {
      UiUtils.showMessage(context, 'Notifications enabled.');
    }
  }

  Future<void> _updateBackendSetting(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> settings,
    String key,
    bool value,
  ) async {
    final resolvedKey = _resolveSettingKey(settings, key);

    try {
      await ref.read(profileUserSettingsProvider.notifier).updateSetting(
            resolvedKey,
            value,
          );
      if (key == 'hapticFeedback') {
        await ref.read(appSettingsProvider.notifier).setHapticFeedback(value);
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      UiUtils.showMessage(
        context,
        'Unable to update $key right now.',
      );
    }
  }

  String _resolveSettingKey(Map<String, dynamic> settings, String key) {
    for (final candidate in _settingKeyCandidates(key)) {
      if (settings.containsKey(candidate)) {
        return candidate;
      }
    }
    return key;
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      await ThemedDialogs.show(
        context,
        title: l10n.aboutJyotiGPTapp,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.versionLabel(info.version, info.buildNumber)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.closeButtonSemantic),
          ),
        ],
      );
    } catch (_) {
      if (!context.mounted) return;
      UiUtils.showMessage(
        context,
        AppLocalizations.of(context)!.unableToLoadAppInfo,
      );
    }
  }

  void _signOut(BuildContext context, WidgetRef ref) async {
    final confirm = await ThemedDialogs.confirm(
      context,
      title: AppLocalizations.of(context)!.signOut,
      message: AppLocalizations.of(context)!.endYourSession,
      confirmText: AppLocalizations.of(context)!.signOut,
      isDestructive: true,
    );

    if (confirm) {
      await ref.read(authActionsProvider).logout();
    }
  }

  Widget _buildIconBadge(
    BuildContext context,
    IconData icon, {
    required Color color,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: BorderWidth.thin,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: IconSize.medium),
    );
  }

  String? _extractEmail(dynamic source) {
    if (source is Map) {
      final value = source['email'];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      final nested = source['user'];
      if (nested is Map) {
        final nestedValue = nested['email'];
        if (nestedValue is String && nestedValue.trim().isNotEmpty) {
          return nestedValue.trim();
        }
      }
    }
    try {
      final dynamic email = source?.email;
      if (email is String && email.trim().isNotEmpty) {
        return email.trim();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  User? _resolveEditableUser(dynamic source) {
    if (source is User) {
      return source;
    }
    if (source is Map) {
      try {
        return User.fromJson(Map<String, dynamic>.from(source));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool _readBoolSetting(Map<String, dynamic> settings, String key) {
    final value = _settingKeyCandidates(key)
        .map((candidate) => settings[candidate])
        .firstWhere((candidate) => candidate != null, orElse: () => null);
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    if (value is num) {
      return value != 0;
    }
    return false;
  }

  List<String> _settingKeyCandidates(String key) {
    final snakeCase = key.replaceAllMapped(
      RegExp(r'(?<!^)([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}',
    );
    return <String>{key, snakeCase}.toList(growable: false);
  }

  String _languageLabel(BuildContext context, Locale? locale) {
    if (locale == null) {
      final systemLocale = Localizations.localeOf(context);
      return 'System default (${_languageName(systemLocale)})';
    }
    return _languageName(locale);
  }

  String _languageName(Locale locale) {
    final tag = locale.toLanguageTag();
    return switch (tag) {
      'de' => 'Deutsch',
      'en' => 'English',
      'es' => 'Español',
      'fr' => 'Français',
      'it' => 'Italiano',
      'ko' => '한국어',
      'nl' => 'Nederlands',
      'ru' => 'Русский',
      'zh' => '简体中文',
      'zh-Hant' => '繁體中文',
      _ => locale.languageCode,
    };
  }

  String _imageDataUrl(List<int> bytes, String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    final format = switch (extension) {
      '.png' => 'png',
      '.webp' => 'webp',
      '.gif' => 'gif',
      _ => 'jpeg',
    };
    return 'data:image/$format;base64,${base64Encode(bytes)}';
  }
}

class _LanguagePickerValue {
  const _LanguagePickerValue({
    required this.label,
    required this.locale,
  });

  final String label;
  final Locale? locale;
}
