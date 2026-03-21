import 'dart:convert';
import 'dart:typed_data';

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
import '../../../core/utils/debug_logger.dart';
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

  double _topContentPadding(
    MediaQueryData mediaQuery, {
    required bool useAdaptivePlatformChrome,
  }) {
    if (useAdaptivePlatformChrome) {
      return Spacing.xl;
    }

    return mediaQuery.padding.top + kToolbarHeight + Spacing.xxl;
  }

  Widget _buildCenteredState(
    BuildContext context,
    Widget child, {
    required bool useAdaptivePlatformChrome,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = _topContentPadding(
      mediaQuery,
      useAdaptivePlatformChrome: useAdaptivePlatformChrome,
    );

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
    final topPadding = _topContentPadding(
      mediaQuery,
      useAdaptivePlatformChrome: useAdaptivePlatformChrome,
    );

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
    final l10n = AppLocalizations.of(context)!;
    final theme = context.jyotigptappTheme;
    final headingStyle = theme.headingSmall?.copyWith(
      color: theme.sidebarForeground,
    );
    final displayName = deriveUserDisplayName(user);
    final avatarUrl = resolveUserAvatarUrlForUser(api, user);
    final email = _extractEmail(user) ?? l10n.profileSignedInAccount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headingStyle != null)
          Text(l10n.profileSectionTitle, style: headingStyle)
        else
          Text(l10n.profileSectionTitle),
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
          title: l10n.profilePictureTitle,
          subtitle: l10n.profilePictureSubtitle,
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
          title: l10n.displayNameTitle,
          subtitle: displayName.isEmpty ? l10n.displayNameUnset : displayName,
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
          title: l10n.emailTitle,
          subtitle: email,
          showChevron: false,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(appThemeModeProvider);
    final themeModeNotifier = ref.read(appThemeModeProvider.notifier);
    final voiceCallNotificationsEnabled = ref.watch(
      appSettingsProvider.select((s) => s.voiceCallNotificationsEnabled),
    );
    final backendSettings = ref.watch(profileUserSettingsProvider);
    final settingsMap = backendSettings.maybeWhen(
      data: (settings) => settings,
      orElse: () => const <String, dynamic>{},
    );
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
          Text(l10n.appSectionTitle, style: headingStyle)
        else
          Text(l10n.appSectionTitle),
        const SizedBox(height: Spacing.sm),
        JyotiGPTappCard(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.themeTitle,
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
          title: l10n.languageTitle,
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
          title: l10n.notificationsTitle,
          subtitle: l10n.notificationsSubtitle,
          onTap: backendSettings.maybeWhen(
            data: (_) => () => _toggleNotifications(
                  context,
                  ref,
                  settingsMap,
                  !notificationsEnabled,
                ),
            orElse: () => null,
          ),
          trailing: AdaptiveSwitch(
            value: notificationsEnabled,
            onChanged: backendSettings.maybeWhen(
              data: (_) => (value) => _toggleNotifications(
                    context,
                    ref,
                    settingsMap,
                    value,
                  ),
              orElse: () => null,
            ),
          ),
          showChevron: false,
        ),
      ],
    );
  }

  Widget _buildBackendSettingsSection(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = context.jyotigptappTheme;
    final headingStyle = theme.headingSmall?.copyWith(
      color: theme.sidebarForeground,
    );
    final backendSettings = ref.watch(profileUserSettingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headingStyle != null)
          Text(l10n.accountSettingsTitle, style: headingStyle)
        else
          Text(l10n.accountSettingsTitle),
        const SizedBox(height: Spacing.sm),
        backendSettings.when(
          data: (settings) => Column(
            children: [
              _buildBackendToggleTile(
                context,
                ref,
                settings: settings,
                keyName: 'enableSounds',
                title: l10n.accountSoundsTitle,
                subtitle: l10n.accountSoundsSubtitle,
                iosIcon: CupertinoIcons.speaker_2,
                androidIcon: Icons.volume_up_outlined,
              ),
              const SizedBox(height: Spacing.md),
              _buildBackendToggleTile(
                context,
                ref,
                settings: settings,
                keyName: 'hapticFeedback',
                title: _hapticsToggleTitle(context, settings),
                subtitle: _hapticsToggleSubtitle(context, settings),
                iosIcon: CupertinoIcons.hand_raised,
                androidIcon: Icons.vibration_outlined,
              ),
            ],
          ),
          error: (_, __) => JyotiGPTappCard(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text(
              l10n.accountSettingsLoadError,
              style: theme.bodyMedium?.copyWith(
                color: theme.sidebarForeground,
              ),
            ),
          ),
          loading: () => JyotiGPTappCard(
            padding: EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: Spacing.sm),
                Expanded(child: Text(l10n.accountSettingsLoading)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _hapticsToggleTitle(
    BuildContext context,
    Map<String, dynamic> settings,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = _readBoolSetting(
      settings,
      'hapticFeedback',
      defaultValue: true,
    );
    return enabled ? l10n.hapticsOffTitle : l10n.hapticsOnTitle;
  }

  String _hapticsToggleSubtitle(
    BuildContext context,
    Map<String, dynamic> settings,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = _readBoolSetting(
      settings,
      'hapticFeedback',
      defaultValue: true,
    );
    return enabled
        ? l10n.hapticsOffSubtitle
        : l10n.hapticsOnSubtitle;
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
    final value = _readBoolSetting(
      settings,
      keyName,
      defaultValue: keyName == 'hapticFeedback',
    );

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
          Text(AppLocalizations.of(context)!.account, style: headingStyle)
        else
          Text(AppLocalizations.of(context)!.account),
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
      title: AppLocalizations.of(context)!.changeDisplayNameTitle,
      message: AppLocalizations.of(context)!.changeDisplayNameMessage,
      icon: 'person.text.rectangle',
      input: AdaptiveAlertDialogInput(
        placeholder: AppLocalizations.of(context)!.displayNamePlaceholder,
        initialValue: initialValue,
        keyboardType: TextInputType.name,
      ),
      actions: [
        AlertAction(
          title: AppLocalizations.of(context)!.cancel,
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: AppLocalizations.of(context)!.save,
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
        AppLocalizations.of(context)!.profileUpdateFailed,
      );
      return;
    }

    final updatedUser = editableUser.copyWith(name: nextName);
    final storage = ref.read(optimizedStorageServiceProvider);
    try {
      await storage.saveLocalUser(updatedUser);
      ref.read(currentUserProvider.notifier).setLocalUser(updatedUser);
    } catch (error, stackTrace) {
      DebugLogger.error(
        'profile-display-name-save-failed',
        scope: 'profile/local',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        UiUtils.showMessage(
          context,
          AppLocalizations.of(context)!.profileUpdateFailed,
        );
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    UiUtils.showMessage(
      context,
      AppLocalizations.of(context)!.displayNameUpdatedLocalOnly,
    );
  }

  Future<void> _changeProfilePhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    XFile? image;
    try {
      image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
    } catch (error, stackTrace) {
      DebugLogger.error(
        'profile-avatar-picker-failed',
        scope: 'profile/local',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        UiUtils.showMessage(
          context,
          AppLocalizations.of(context)!.profileUpdateFailed,
        );
      }
      return;
    }

    if (!context.mounted || image == null) {
      return;
    }

    final storage = ref.read(optimizedStorageServiceProvider);
    Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
    } catch (error, stackTrace) {
      DebugLogger.error(
        'profile-avatar-read-failed',
        scope: 'profile/local',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        UiUtils.showMessage(
          context,
          AppLocalizations.of(context)!.profileUpdateFailed,
        );
      }
      return;
    }

    final dataUrl = _imageDataUrl(bytes, image.path);
    final asyncUser = ref.read(currentUserProvider);
    final currentUser = _resolveEditableUser(
      asyncUser.maybeWhen(
        data: (value) => value ?? ref.read(currentUserProvider2),
        orElse: () => ref.read(currentUserProvider2),
      ),
    );
    final previousAvatar = await storage.getLocalUserAvatar();

    try {
      await storage.saveLocalUserAvatar(dataUrl);
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(profileImage: dataUrl);
        await storage.saveLocalUser(updatedUser);
        ref.read(currentUserProvider.notifier).setLocalUser(updatedUser);
      } else {
        ref.read(currentUserProvider.notifier).clearLocalUser();
      }
    } catch (error, stackTrace) {
      DebugLogger.error(
        'profile-avatar-save-failed',
        scope: 'profile/local',
        error: error,
        stackTrace: stackTrace,
      );
      try {
        await storage.saveLocalUserAvatar(previousAvatar);
        await storage.saveLocalUser(currentUser);
      } catch (rollbackError, rollbackStack) {
        DebugLogger.error(
          'profile-avatar-rollback-failed',
          scope: 'profile/local',
          error: rollbackError,
          stackTrace: rollbackStack,
        );
      }
      if (context.mounted) {
        UiUtils.showMessage(
          context,
          AppLocalizations.of(context)!.profileUpdateFailed,
        );
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    UiUtils.showMessage(
      context,
      AppLocalizations.of(context)!.profilePictureUpdatedLocalOnly,
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
      final persistedValue = selected.locale == null
          ? null
          : resolvedLocale.toLanguageTag();
      await ref
          .read(profileUserSettingsProvider.notifier)
          .updateSetting('language', persistedValue);
    } catch (_) {
      if (context.mounted) {
        UiUtils.showMessage(
          context,
          AppLocalizations.of(context)!.languageChangedLocalOnly,
        );
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    UiUtils.showMessage(context, AppLocalizations.of(context)!.languageUpdated);
  }

  Future<_LanguagePickerValue?> _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentLocale = ref.read(appLocaleProvider);
    final options = <_LanguagePickerValue>[
      _LanguagePickerValue(
        label: AppLocalizations.of(context)!.systemDefaultLanguageOption,
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
          title: Text(AppLocalizations.of(context)!.appLanguageTitle),
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
            child: Text(AppLocalizations.of(context)!.cancel),
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
    Map<String, dynamic> settings,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    if (!enabled) {
      final previous =
          ref.read(appSettingsProvider).voiceCallNotificationsEnabled;
      try {
        await _updateBackendSetting(
          context,
          ref,
          settings,
          'enableNotifications',
          false,
          rethrowOnError: true,
        );
        await settingsNotifier.setVoiceCallNotificationsEnabled(false);
      } catch (_) {
        await settingsNotifier.setVoiceCallNotificationsEnabled(previous);
      }
      return;
    }

    final previous =
        ref.read(appSettingsProvider).voiceCallNotificationsEnabled;
    try {
      final svc = VoiceCallNotificationService();
      await svc.initialize();
      final granted = await svc.requestPermissions();
      if (!context.mounted) {
        return;
      }

      if (!granted) {
        await settingsNotifier.setVoiceCallNotificationsEnabled(false);
        UiUtils.showMessage(
          context,
          l10n.notificationsNotEnabledMessage,
        );
        return;
      }

      await _updateBackendSetting(
        context,
        ref,
        settings,
        'enableNotifications',
        true,
        rethrowOnError: true,
      );
      await settingsNotifier.setVoiceCallNotificationsEnabled(true);
      if (context.mounted) {
        UiUtils.showMessage(context, l10n.notificationsEnabledMessage);
      }
    } catch (error, stackTrace) {
      DebugLogger.error(
        'notifications-toggle-failed',
        scope: 'profile',
        error: error,
        stackTrace: stackTrace,
      );
      await settingsNotifier.setVoiceCallNotificationsEnabled(previous);
      if (context.mounted) {
        UiUtils.showMessage(
          context,
          l10n.errorMessage,
        );
      }
    }
  }

  Future<void> _updateBackendSetting(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> settings,
    String key,
    bool value, {
    bool rethrowOnError = false,
  }) async {
    final canonicalKey = switch (key) {
      'enableNotifications' => 'enable_notifications',
      'enableSounds' => 'enable_sounds',
      'hapticFeedback' => 'haptic_feedback',
      _ => key,
    };

    try {
      await ref.read(profileUserSettingsProvider.notifier).updateSetting(
            canonicalKey,
            value,
          );
      if (key == 'hapticFeedback') {
        await ref.read(appSettingsProvider.notifier).setHapticFeedback(value);
      }
    } catch (_) {
      if (context.mounted) {
        final label = _settingLabel(context, settings, key);
        UiUtils.showMessage(
          context,
          AppLocalizations.of(context)!.settingUpdateFailed(label),
        );
      }
      if (rethrowOnError) {
        rethrow;
      }
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

  String _settingLabel(
    BuildContext context,
    Map<String, dynamic> settings,
    String key,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return switch (key) {
      'enableNotifications' => l10n.notificationsTitle,
      'enableSounds' => l10n.accountSoundsTitle,
      'hapticFeedback' => _hapticsToggleTitle(context, settings),
      _ => key,
    };
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

  bool _readBoolSetting(
    Map<String, dynamic> settings,
    String key, {
    bool defaultValue = false,
  }) {
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
    return defaultValue;
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
      return AppLocalizations.of(
        context,
      )!.systemDefaultLanguageLabel(_languageName(systemLocale));
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
