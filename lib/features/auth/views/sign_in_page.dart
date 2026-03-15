import 'dart:io' show Platform;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jyotigptapp/core/widgets/error_boundary.dart';
import 'package:jyotigptapp/core/auth/auth_state_manager.dart';
import 'package:jyotigptapp/features/auth/providers/unified_auth_providers.dart';
import 'package:jyotigptapp/l10n/app_localizations.dart';
import 'package:jyotigptapp/shared/services/brand_service.dart';
import 'package:jyotigptapp/shared/theme/theme_extensions.dart';
import 'package:jyotigptapp/shared/widgets/jyotigptapp_components.dart';

/// Consumer-friendly sign-in page (username/email + password only).
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSigningIn = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSigningIn = true;
      _error = null;
    });

    try {
      final actions = ref.read(authActionsProvider);
      final success = await actions.login(
        _usernameController.text.trim(),
        _passwordController.text,
        rememberCredentials: true,
      );

      if (!success) {
        final authState = ref.read(authStateManagerProvider);
        final message = authState.maybeWhen(
          data: (state) => state.error,
          orElse: () => null,
        );
        throw Exception(message ?? l10n.genericSignInFailed);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _formatError(e.toString(), l10n);
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
      });
    }
  }

  String _formatError(String raw, AppLocalizations l10n) {
    if (raw.contains('401') || raw.contains('Unauthorized')) {
      return l10n.invalidCredentials;
    }
    if (raw.contains('SocketException') || raw.contains('Connection')) {
      return l10n.unableToConnectServer;
    }
    if (raw.contains('timeout')) {
      return l10n.requestTimedOut;
    }
    return l10n.genericSignInFailed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.jyotigptappTheme;
    final l10n = AppLocalizations.of(context)!;

    final topPadding = MediaQuery.of(context).padding.top + 24;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24;

    return ErrorBoundary(
      child: AdaptiveScaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  Spacing.pagePadding,
                  topPadding,
                  Spacing.pagePadding,
                  bottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      title: l10n.appTitle,
                      subtitle: l10n.enterCredentials,
                    ),
                    const SizedBox(height: Spacing.xl),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AccessibleFormField(
                            label: l10n.usernameOrEmail,
                            controller: _usernameController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username],
                            prefixIcon: Icon(
                              Platform.isIOS
                                  ? CupertinoIcons.person
                                  : Icons.person_outline,
                              color: theme.iconSecondary,
                              size: IconSize.small,
                            ),
                            validator: (value) {
                              final text = (value ?? '').trim();
                              return text.isEmpty ? l10n.requiredField : null;
                            },
                            onSubmitted: (_) => _signIn(),
                          ),
                          const SizedBox(height: Spacing.md),
                          AccessibleFormField(
                            label: l10n.password,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            prefixIcon: Icon(
                              Platform.isIOS
                                  ? CupertinoIcons.lock
                                  : Icons.lock_outline,
                              color: theme.iconSecondary,
                              size: IconSize.small,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              tooltip: _obscurePassword
                                  ? l10n.showPassword
                                  : l10n.hidePassword,
                              icon: Icon(
                                _obscurePassword
                                    ? (Platform.isIOS
                                          ? CupertinoIcons.eye
                                          : Icons.visibility_outlined)
                                    : (Platform.isIOS
                                          ? CupertinoIcons.eye_slash
                                          : Icons.visibility_off_outlined),
                                color: theme.iconSecondary,
                                size: IconSize.small,
                              ),
                            ),
                            validator: (value) {
                              final text = (value ?? '').trim();
                              return text.isEmpty ? l10n.requiredField : null;
                            },
                            onSubmitted: (_) => _signIn(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: Spacing.md),
                            _InlineError(message: _error!),
                          ],
                          const SizedBox(height: Spacing.lg),
                          JyotiGPTappButton(
                            text: l10n.signIn,
                            onPressed: _isSigningIn ? null : _signIn,
                            isLoading: _isSigningIn,
                            isFullWidth: true,
                            icon: Platform.isIOS
                                ? CupertinoIcons.arrow_right_circle
                                : Icons.arrow_forward_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),
                    Text(
                      'Powered by JyotiGPT',
                      textAlign: TextAlign.center,
                      style: theme.bodySmall?.copyWith(
                        color: theme.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.jyotigptappTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BrandService.createLauncherIcon(size: 56, addShadow: true),
        const SizedBox(height: Spacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.headingLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.bodyMedium?.copyWith(
            color: theme.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.jyotigptappTheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: theme.error.withValues(alpha: 0.18),
          width: BorderWidth.thin,
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.bodySmall?.copyWith(color: theme.error, height: 1.35),
      ),
    );
  }
}
