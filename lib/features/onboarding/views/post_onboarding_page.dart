import 'dart:io' show Platform;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:jyotigptapp/core/services/navigation_service.dart';
import 'package:jyotigptapp/core/utils/user_display_name.dart';
import 'package:jyotigptapp/core/widgets/error_boundary.dart';
import 'package:jyotigptapp/features/auth/providers/unified_auth_providers.dart';
import 'package:jyotigptapp/features/onboarding/providers/onboarding_providers.dart';
import 'package:jyotigptapp/shared/services/brand_service.dart';
import 'package:jyotigptapp/shared/theme/theme_extensions.dart';
import 'package:jyotigptapp/shared/widgets/jyotigptapp_components.dart';

class PostOnboardingPage extends ConsumerStatefulWidget {
  const PostOnboardingPage({super.key});

  @override
  ConsumerState<PostOnboardingPage> createState() => _PostOnboardingPageState();
}

class _PostOnboardingPageState extends ConsumerState<PostOnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == 2;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeAndGoToChat() async {
    await ref.read(postOnboardingCompleteProvider.notifier).setComplete();
    if (!mounted) return;
    context.go(Routes.chat);
  }

  Future<void> _next() async {
    if (_isLast) {
      await _completeAndGoToChat();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.jyotigptappTheme;
    final user = ref.watch(currentUserProvider2);
    final name = (user == null) ? 'there' : deriveUserDisplayName(user);

    final pages = <_OnboardingPageModel>[
      _OnboardingPageModel(
        title: "You're all set, $name!",
        body: 'Welcome to JyotiGPT.',
        icon: Icons.check_circle_outline,
      ),
      const _OnboardingPageModel(
        title: 'Start a chat',
        body: 'Tap “New chat” or pick a conversation to continue.',
        icon: Icons.add_comment_outlined,
      ),
      const _OnboardingPageModel(
        title: 'Try voice or switch models',
        body: 'Use the mic to speak, or switch models in the chat header.',
        icon: Icons.tune,
      ),
    ];

    return ErrorBoundary(
      child: AdaptiveScaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.pagePadding,
                  vertical: Spacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_isLast)
                      TextButton(
                        onPressed: _completeAndGoToChat,
                        child: const Text('Skip'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) => _OnboardingPage(
                    model: pages[index],
                    isActive: index == _index,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.pagePadding,
                  Spacing.sm,
                  Spacing.pagePadding,
                  Spacing.lg,
                ),
                child: Column(
                  children: [
                    _Dots(count: pages.length, index: _index),
                    const SizedBox(height: Spacing.md),
                    JyotiGPTappButton(
                      text: _isLast ? 'Go to chats' : 'Next',
                      onPressed: _next,
                      isFullWidth: true,
                      icon: _isLast
                          ? (Platform.isIOS
                                ? CupertinoIcons.chat_bubble_2
                                : Icons.chat_bubble_outline)
                          : (Platform.isIOS
                                ? CupertinoIcons.chevron_right
                                : Icons.chevron_right_rounded),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'Powered by JyotiGPT',
                      style: theme.bodySmall?.copyWith(
                        color: theme.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageModel {
  const _OnboardingPageModel({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.model, required this.isActive});

  final _OnboardingPageModel model;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = context.jyotigptappTheme;

    final icon = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: theme.sidebarAccent.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(
          color: theme.sidebarBorder.withValues(alpha: 0.6),
          width: BorderWidth.thin,
        ),
      ),
      child: Center(
        child: BrandService.createBrandIcon(
          size: 44,
          icon: model.icon,
          useGradient: true,
          addShadow: true,
          context: context,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 320.ms)
              .slideY(begin: 0.08, end: 0, duration: 320.ms),
          const SizedBox(height: Spacing.lg),
          Text(
            model.title,
            textAlign: TextAlign.center,
            style: theme.headingLarge?.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 320.ms)
              .slideY(begin: 0.06, end: 0, duration: 320.ms),
          const SizedBox(height: Spacing.sm),
          Text(
            model.body,
            textAlign: TextAlign.center,
            style: theme.bodyMedium?.copyWith(
              color: theme.textSecondary,
              height: 1.4,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 320.ms)
              .slideY(begin: 0.06, end: 0, duration: 320.ms),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = context.jyotigptappTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? theme.buttonPrimary : theme.dividerColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

