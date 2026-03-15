import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

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
    final topPadding =
        useAdaptivePlatformChrome
            ? 24.0
            : (MediaQuery.of(context).padding.top + kToolbarHeight + 24);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.pagePadding,
        topPadding,
        Spacing.pagePadding,
        Spacing.pagePadding + MediaQuery.of(context).padding.bottom,
      ),
      child: Center(child: child),
    );
  }

  Widget _buildProfileBody(
    BuildContext context,
    WidgetRef ref,
    dynamic userData,
    ApiService? api,
    {required bool useAdaptivePlatformChrome}
  ) {
    final topPadding =
        useAdaptivePlatformChrome
            ? 24.0
            : (MediaQuery.of(context).padding.top + kToolbarHeight + 24);
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        Spacing.pagePadding,
        topPadding,
        Spacing.pagePadding,
        Spacing.pagePadding + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _buildProfileHeader(context, userData, api),
        const SizedBox(height: Spacing.xl),
        _buildPreferencesSection(context, ref),
        const SizedBox(height: Spacing.xl),
        _buildAccountSection(context, ref),
      ],
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

    String? extractEmail(dynamic source) {
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
        // best-effort
      }
      return null;
    }

    final email = extractEmail(user) ?? '';
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatar(size: 56, imageUrl: avatarUrl, fallbackText: initial),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isEmpty ? 'User' : displayName,
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

  Widget _buildPreferencesSection(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final themeModeNotifier = ref.read(appThemeModeProvider.notifier);

    final voiceCallNotificationsEnabled = ref.watch(
      appSettingsProvider.select((s) => s.voiceCallNotificationsEnabled),
    );
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    final theme = context.jyotigptappTheme;
    final headingStyle = theme.headingSmall?.copyWith(
      color: theme.sidebarForeground,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headingStyle != null)
          Text('Preferences', style: headingStyle)
        else
          const Text('Preferences'),
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
          leading: _buildIconBadge(
            context,
            UiUtils.platformIcon(
              ios: CupertinoIcons.bell,
              android: Icons.notifications_none,
            ),
            color: theme.buttonPrimary,
          ),
          title: 'Voice call controls notification',
          subtitle:
              'Show an ongoing notification during voice calls '
              'for quick mute/end controls.',
          onTap: () => settingsNotifier.setVoiceCallNotificationsEnabled(
            !voiceCallNotificationsEnabled,
          ),
          trailing: Switch.adaptive(
            value: voiceCallNotificationsEnabled,
            onChanged: settingsNotifier.setVoiceCallNotificationsEnabled,
          ),
          showChevron: false,
        ),
        const SizedBox(height: Spacing.md),
        ProfileSettingTile(
          leading: _buildIconBadge(
            context,
            UiUtils.platformIcon(
              ios: CupertinoIcons.lock_shield,
              android: Icons.security_outlined,
            ),
            color: theme.buttonPrimary,
          ),
          title: 'Request notification permission',
          subtitle: 'Enable notifications in system settings if prompted.',
          onTap: () => _requestNotificationPermission(context),
        ),
      ],
    );
  }

  Future<void> _requestNotificationPermission(BuildContext context) async {
    final granted = await VoiceCallNotificationService().requestPermissions();
    if (!context.mounted) return;
    UiUtils.showMessage(
      context,
      granted ? 'Notifications enabled.' : 'Notifications not enabled.',
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
}
