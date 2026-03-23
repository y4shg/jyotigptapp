import 'package:jyotigptapp/shared/utils/platform_io.dart' show Platform;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/color_tokens.dart';
import '../theme/theme_extensions.dart';
import '../theme/tweakcn_themes.dart';

/// Centralized service for consistent brand identity throughout the app
class BrandService {
  BrandService._();

  /// The primary brand mark shown throughout the app.
  static const String brandMarkSvgAssetPath = 'assets/icons/icon.svg';

  /// The full-color launcher icon used for onboarding and first sign-in.
  static const String launcherIconPngAssetPath = 'assets/icons/icon.png';

  /// Alternative icons for different contexts.
  static IconData get connectivityIcon =>
      Platform.isIOS ? CupertinoIcons.wifi : Icons.wifi;
  static IconData get networkIcon =>
      Platform.isIOS ? CupertinoIcons.globe : Icons.public;

  /// Brand colors - these should be accessed through context.jyotigptappTheme in UI components
  static Color primaryBrandColor({
    BuildContext? context,
    Brightness? brightness,
  }) {
    final palette = _resolvePalette(context);
    final resolvedBrightness = brightness ?? _resolveBrightness(context);
    return palette.variantFor(resolvedBrightness).primary;
  }

  static Color secondaryBrandColor({
    BuildContext? context,
    Brightness? brightness,
  }) {
    final palette = _resolvePalette(context);
    final resolvedBrightness = brightness ?? _resolveBrightness(context);
    return palette.variantFor(resolvedBrightness).secondary;
  }

  static Color accentBrandColor({
    BuildContext? context,
    Brightness? brightness,
  }) {
    final palette = _resolvePalette(context);
    final resolvedBrightness = brightness ?? _resolveBrightness(context);
    return palette.variantFor(resolvedBrightness).accent;
  }

  /// Creates a branded icon with consistent styling
  static Widget createBrandIcon({
    double size = 24,
    Color? color,
    IconData? icon,
    bool useGradient = false,
    bool addShadow = false,
    BuildContext? context,
    String? semanticsLabel,
  }) {
    final resolvedColor = color ?? primaryBrandColor(context: context);

    Widget iconWidget;
    if (icon == null) {
      iconWidget = _buildBrandSvg(
        size: size,
        color: useGradient ? null : resolvedColor,
        semanticsLabel: semanticsLabel,
      );
      if (useGradient) {
        iconWidget = ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              primaryBrandColor(context: context),
              secondaryBrandColor(context: context),
            ],
          ).createShader(bounds),
          child: _buildBrandSvg(
            size: size,
            color: null,
            semanticsLabel: semanticsLabel,
          ),
        );
      }
    } else {
      iconWidget = Icon(
        icon,
        size: size,
        color: useGradient ? null : resolvedColor,
      );

      if (useGradient) {
        iconWidget = ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              primaryBrandColor(context: context),
              secondaryBrandColor(context: context),
            ],
          ).createShader(bounds),
          child: Icon(icon, size: size),
        );
      }
    }

    if (addShadow) {
      iconWidget = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: primaryBrandColor(context: context).withValues(alpha: 0.3),
              blurRadius: size * 0.3,
              offset: Offset(0, size * 0.1),
            ),
          ],
        ),
        child: iconWidget,
      );
    }

    return iconWidget;
  }

  /// Creates a branded avatar with the brand mark.
  static Widget createBrandAvatar({
    double size = 40,
    Color? backgroundColor,
    Color? iconColor,
    bool useGradient = true,
    String? fallbackText,
    BuildContext? context,
  }) {
    final bgColor = backgroundColor ?? primaryBrandColor(context: context);
    final tokens = _resolveTokens(context);
    final iColor =
        iconColor ??
        (context?.jyotigptappTheme.textInverse ?? tokens.neutralTone00);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: useGradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryBrandColor(context: context),
                  secondaryBrandColor(context: context),
                ],
              )
            : null,
        color: useGradient ? null : bgColor,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: primaryBrandColor(context: context).withValues(alpha: 0.3),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: fallbackText != null && fallbackText.isNotEmpty
          ? Center(
              child: Text(
                fallbackText.toUpperCase(),
                style: TextStyle(
                  color: iColor,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : createBrandIcon(
              size: size * 0.5,
              color: iColor,
              context: context,
              semanticsLabel: brandName,
            ),
    );
  }

  /// Creates a branded loading indicator
  static Widget createBrandLoadingIndicator({
    double size = 24,
    double strokeWidth = 2,
    Color? color,
    BuildContext? context,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? primaryBrandColor(context: context),
        ),
      ),
    );
  }

  /// Creates a branded empty state icon
  static Widget createBrandEmptyStateIcon({
    double size = 80,
    Color? color,
    bool showBackground = true,
    BuildContext? context,
  }) {
    final tokens = _resolveTokens(context);
    final iconColor =
        color ?? (context?.jyotigptappTheme.iconSecondary ?? tokens.neutralTone80);

    if (!showBackground) {
      return createBrandIcon(
        size: size,
        color: iconColor,
        context: context,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context?.jyotigptappTheme.surfaceBackground ?? tokens.neutralTone10,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: context?.jyotigptappTheme.dividerColor ?? tokens.neutralTone40,
          width: 2,
        ),
      ),
      child: createBrandIcon(
        size: size * 0.5,
        color: iconColor,
        context: context,
      ),
    );
  }

  /// Creates a branded button with the brand mark (by default).
  static Widget createBrandButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    bool isSecondary = false,
    BuildContext? context,
  }) {
    final theme = context?.jyotigptappTheme;
    final tokens = _resolveTokens(context);
    return SizedBox(
      width: width,
      height: 48,
      child: AdaptiveButton.child(
        onPressed: isLoading ? null : onPressed,
        color: isSecondary
            ? (theme?.buttonSecondary ?? tokens.neutralTone20)
            : (theme?.buttonPrimary ?? primaryBrandColor(context: context)),
        style: AdaptiveButtonStyle.filled,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? createBrandLoadingIndicator(
                    size: IconSize.sm,
                    context: context,
                  )
                : createBrandIcon(
                    size: IconSize.md,
                    icon: icon,
                    color: theme?.textInverse ?? tokens.neutralTone00,
                    context: context,
                  ),
            const SizedBox(width: Spacing.sm),
            Text(text),
          ],
        ),
      ),
    );
  }

  /// Brand-specific semantic labels for accessibility
  static String get brandName => 'JyotiGPTapp';
  static String get brandDescription => 'Your AI Conversation Hub';
  static String get connectionLabel => 'Connection';
  static String get networkLabel => 'Network';

  /// Creates the full-color launcher icon (PNG).
  ///
  /// Use this for onboarding and first sign-in screens, where the full icon
  /// (not the SVG brand mark) should be displayed.
  static Widget createLauncherIcon({
    double size = 56,
    bool addShadow = false,
    String? semanticsLabel,
  }) {
    Widget iconWidget = Image.asset(
      launcherIconPngAssetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticsLabel ?? brandName,
    );

    if (addShadow) {
      iconWidget = DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: size * 0.22,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: iconWidget,
      );
    }

    return iconWidget;
  }

  /// Creates branded AppBar with consistent styling
  static PreferredSizeWidget createBrandAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
    double elevation = 0,
    BuildContext? context,
  }) {
    return AppBar(
      title: Text(
        title,
        style: context != null
            ? context.jyotigptappTheme.headingSmall?.copyWith(
                color: context.jyotigptappTheme.textPrimary,
                fontWeight: FontWeight.w600,
              )
            : TextStyle(
                fontSize: AppTypography.headlineSmall,
                fontWeight: FontWeight.w600,
              ),
      ),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: context?.jyotigptappTheme.surfaceBackground,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      leading: leading,
      actions: actions,
    );
  }

  /// Creates a branded splash screen logo
  static Widget createSplashLogo({
    double size = 140,
    bool animate = true,
    BuildContext? context,
  }) {
    final theme = context?.jyotigptappTheme;
    final tokens = _resolveTokens(context);
    final baseColor =
        theme?.buttonPrimary ??
        primaryBrandColor(context: context, brightness: Brightness.dark);
    final accentColor =
        theme?.buttonPrimary.withValues(alpha: 0.8) ??
        secondaryBrandColor(context: context, brightness: Brightness.dark);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, accentColor],
        ),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: context != null
            ? JyotiGPTappShadows.glow(context)
            : JyotiGPTappShadows.glowWithTokens(tokens),
      ),
      child: createBrandIcon(
        size: size * 0.5,
        color: theme?.textInverse ?? tokens.neutralTone00,
        context: context,
        semanticsLabel: brandName,
      ),
    );
  }

  static TweakcnThemeDefinition _resolvePalette(BuildContext? context) {
    return TweakcnThemes.jyotigptapp;
  }

  static Brightness _resolveBrightness(BuildContext? context) {
    return context != null ? Theme.of(context).brightness : Brightness.light;
  }

  static AppColorTokens _resolveTokens(BuildContext? context) {
    final palette = _resolvePalette(context);
    final brightness = _resolveBrightness(context);
    return brightness == Brightness.dark
        ? AppColorTokens.dark(theme: palette)
        : AppColorTokens.light(theme: palette);
  }

  static Widget _buildBrandSvg({
    required double size,
    required Color? color,
    required String? semanticsLabel,
  }) {
    return SvgPicture.asset(
      brandMarkSvgAssetPath,
      width: size,
      height: size,
      semanticsLabel: semanticsLabel ?? brandName,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
