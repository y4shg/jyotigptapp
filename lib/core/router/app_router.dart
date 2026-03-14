import 'dart:async';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_state_manager.dart';
import '../providers/app_providers.dart';
import '../services/connectivity_service.dart';
import '../services/navigation_service.dart';
import '../utils/debug_logger.dart';
import '../../features/auth/providers/unified_auth_providers.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/auth/views/connection_issue_page.dart';
import '../../features/auth/views/sign_in_page.dart';
import '../../features/chat/views/chat_page.dart';
import '../../features/navigation/views/splash_launcher_page.dart';
import '../../features/onboarding/providers/onboarding_providers.dart';
import '../../features/onboarding/views/post_onboarding_page.dart';
import '../../features/onboarding/views/pre_onboarding_page.dart';
import '../../features/notes/views/notes_list_page.dart';
import '../../features/notes/views/note_editor_page.dart';
import '../../features/profile/views/profile_page.dart';
import '../../l10n/app_localizations.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    _subscriptions = [
      ref.listen<bool>(reviewerModeProvider, _onStateChanged),
      ref.listen<AsyncValue<bool>>(preOnboardingCompleteProvider, _onStateChanged),
      ref.listen<AsyncValue<bool>>(
        postOnboardingCompleteProvider,
        _onStateChanged,
      ),
      ref.listen<AuthNavigationState>(
        authNavigationStateProvider,
        _onStateChanged,
      ),
      ref.listen<ConnectivityStatus>(
        connectivityStatusProvider,
        _onStateChanged,
      ),
      ref.listen<bool>(isChatStreamingProvider, _onStateChanged),
    ];
  }

  final Ref ref;
  late final List<ProviderSubscription<dynamic>> _subscriptions;

  void _onStateChanged(dynamic previous, dynamic next) {
    // Debounce router refreshes to avoid thrashing on rapid state changes
    _scheduleRefresh();
  }

  Timer? _refreshDebounce;
  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 50), () {
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final location = state.uri.path.isEmpty ? Routes.splash : state.uri.path;
    final reviewerMode = ref.read(reviewerModeProvider);

    if (reviewerMode) {
      // Stay on whatever route if already in chat; otherwise go to chat
      if (location == Routes.chat) return null;
      return Routes.chat;
    }

    final preOnboarding = ref.read(preOnboardingCompleteProvider);
    if (preOnboarding.isLoading) {
      return location == Routes.splash ? null : Routes.splash;
    }
    final preComplete = preOnboarding.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );
    if (!preComplete) {
      return location == Routes.preOnboarding ? null : Routes.preOnboarding;
    }

    final authState = ref.read(authNavigationStateProvider);
    final connectivityService = ref.read(connectivityServiceProvider);

    // Check connectivity status to determine if we should show connection issue
    final connectivity = ref.read(connectivityStatusProvider);

    // Only show connection issue page if:
    // 1. Not in reviewer mode
    // 2. Connectivity is explicitly offline
    // 3. Auth is authenticated (don't interrupt auth flow)
    // 4. App is in foreground and offline warning isn't suppressed
    // 5. No active streaming is in progress (avoid interrupting chat streams)
    final hasActiveStreams = ref.read(isChatStreamingProvider);
    switch (authState) {
      case AuthNavigationState.loading:
        // Keep splash during session establishment.
        if (_isAuthLocation(location)) return null;
        return location == Routes.splash ? null : Routes.splash;
      case AuthNavigationState.needsLogin:
        if (location == Routes.connectionIssue) return null;
        // Redirect to sign-in page if not already on an auth route.
        if (_isAuthLocation(location)) return null;
        return Routes.signIn;
      case AuthNavigationState.error:
        final authSnapshot = ref
            .read(authStateManagerProvider)
            .maybeWhen(data: (state) => state, orElse: () => null);
        final hasValidToken = authSnapshot?.hasValidToken ?? false;
        final isAuthFormRoute = location == Routes.signIn;
        if (!hasValidToken && isAuthFormRoute) {
          // Keep user on the login/authentication flow to show inline errors
          return null;
        }
        // Otherwise show connection issue page for recoverable auth errors
        return location == Routes.connectionIssue
            ? null
            : Routes.connectionIssue;
      case AuthNavigationState.authenticated:
        final postOnboarding = ref.read(postOnboardingCompleteProvider);
        if (postOnboarding.isLoading) {
          return location == Routes.splash ? null : Routes.splash;
        }
        final postComplete = postOnboarding.maybeWhen(
          data: (value) => value,
          orElse: () => false,
        );
        if (!postComplete) {
          return location == Routes.postOnboarding
              ? null
              : Routes.postOnboarding;
        }

        final shouldShowConnectionIssue =
            connectivity == ConnectivityStatus.offline &&
            connectivityService.isAppForeground &&
            !connectivityService.isOfflineSuppressed &&
            !hasActiveStreams;
        if (shouldShowConnectionIssue) {
          return location == Routes.connectionIssue
              ? null
              : Routes.connectionIssue;
        }

        // Avoid unnecessary redirects if already on a non-auth route
        if (_isAuthLocation(location) ||
            location == Routes.preOnboarding ||
            location == Routes.postOnboarding ||
            location == Routes.splash ||
            location == Routes.connectionIssue) {
          return Routes.chat;
        }
        return null;
    }
  }

  bool _isAuthLocation(String location) {
    return location == Routes.signIn || location == Routes.connectionIssue;
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    for (final sub in _subscriptions) {
      sub.close();
    }
    super.dispose();
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  final routes = <RouteBase>[
    GoRoute(
      path: Routes.splash,
      name: RouteNames.splash,
      builder: (context, state) => const SplashLauncherPage(),
    ),
    GoRoute(
      path: Routes.preOnboarding,
      name: RouteNames.preOnboarding,
      builder: (context, state) => const PreOnboardingPage(),
    ),
    GoRoute(
      path: Routes.postOnboarding,
      name: RouteNames.postOnboarding,
      builder: (context, state) => const PostOnboardingPage(),
    ),
    GoRoute(
      path: Routes.signIn,
      name: RouteNames.signIn,
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: Routes.chat,
      name: RouteNames.chat,
      builder: (context, state) => const ChatPage(),
    ),
    GoRoute(
      path: Routes.connectionIssue,
      name: RouteNames.connectionIssue,
      builder: (context, state) => const ConnectionIssuePage(),
    ),
    GoRoute(
      path: Routes.profile,
      name: RouteNames.profile,
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: Routes.notes,
      name: RouteNames.notes,
      builder: (context, state) => const NotesListPage(),
    ),
    GoRoute(
      path: Routes.noteEditor,
      name: RouteNames.noteEditor,
      builder: (context, state) {
        final noteId = state.pathParameters['id'];
        if (noteId == null || noteId.isEmpty) {
          return const NotesListPage();
        }
        return NoteEditorPage(noteId: noteId);
      },
    ),

    // -----------------------------------------------------------------------
    // Legacy route compatibility (deep links / old navigation state)
    // -----------------------------------------------------------------------
    GoRoute(
      path: '/login',
      redirect: (_, __) => Routes.signIn,
    ),
    GoRoute(
      path: '/authentication',
      redirect: (_, __) => Routes.signIn,
    ),
    GoRoute(
      path: '/server-connection',
      redirect: (_, __) => Routes.signIn,
    ),
    GoRoute(
      path: '/sso-auth',
      redirect: (_, __) => Routes.signIn,
    ),
    GoRoute(
      path: '/proxy-auth',
      redirect: (_, __) => Routes.signIn,
    ),
    GoRoute(
      path: '/profile/customization',
      redirect: (_, __) => Routes.profile,
    ),
  ];

  final router = GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: routes,
    observers: [NavigationLoggingObserver()],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      final message =
          l10n?.routeNotFound(state.uri.path) ??
          'Route not found: ${state.uri.path}';
      return AdaptiveScaffold(
        body: Center(child: Text(message, textAlign: TextAlign.center)),
      );
    },
  );

  NavigationService.attachRouter(router);
  return router;
});

class NavigationLoggingObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final previous = previousRoute?.settings.name ?? previousRoute?.settings;
    DebugLogger.navigation(
      'Pushed: ${route.settings.name ?? route.settings} (from ${previous ?? 'root'})',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    DebugLogger.navigation('Popped: ${route.settings.name ?? route.settings}');
  }
}
