import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:jyotigptapp/l10n/app_localizations.dart';

import '../../theme/color_tokens.dart';
import '../../theme/theme_extensions.dart';
import 'package:jyotigptapp/core/network/image_header_utils.dart';

typedef MarkdownLinkTapCallback = void Function(String url, String title);

class JyotiGPTappMarkdown {
  const JyotiGPTappMarkdown._();

  /// Builds a syntax-highlighted code block with a
  /// language header and copy button.
  static Widget buildCodeBlock({
    required BuildContext context,
    required String code,
    required String language,
    required JyotiGPTappThemeExtension theme,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalizedLanguage = language.trim().isEmpty
        ? 'plaintext'
        : language.trim();

    // Map common language aliases to highlight.js recognized names
    final highlightLanguage = mapLanguage(normalizedLanguage);

    // Use Atom One Dark for dark mode, GitHub for light mode
    // These colors must match the highlight themes for visual consistency
    final highlightTheme = isDark ? atomOneDarkTheme : githubTheme;
    final codeBackground = isDark
        ? const Color(0xFF282c34) // Atom One Dark
        : const Color(0xFFF6F8FA); // GitHub light

    // Derive border color from background for consistency
    final borderColor = theme.codeBorder.withValues(
      alpha: isDark ? 0.55 : 0.75,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: Spacing.xs + 2),
      decoration: BoxDecoration(
        color: codeBackground,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: borderColor, width: BorderWidth.thin),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: theme.cardShadow.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CodeBlockHeader(
            language: normalizedLanguage,
            backgroundColor: codeBackground,
            borderColor: borderColor,
            isDark: isDark,
            onCopy: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              final l10n = AppLocalizations.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n?.codeCopiedToClipboard ?? 'Code copied to clipboard.',
                  ),
                ),
              );
            },
          ),
          _CodeBlockBody(
            code: code,
            highlightLanguage: highlightLanguage,
            highlightTheme: highlightTheme,
            codeStyle: AppTypography.codeStyle.copyWith(
              fontFamily: AppTypography.monospaceFontFamily,
              fontSize: 13,
              height: 1.55,
            ),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// Maps common language names/aliases to
  /// highlight.js recognized names.
  static String mapLanguage(String language) {
    final lower = language.toLowerCase();

    // Common language aliases mapping
    const languageMap = <String, String>{
      'js': 'javascript',
      'ts': 'typescript',
      'py': 'python',
      'rb': 'ruby',
      'sh': 'bash',
      'shell': 'bash',
      'zsh': 'bash',
      'yml': 'yaml',
      'dockerfile': 'docker',
      'kt': 'kotlin',
      'cs': 'csharp',
      'c++': 'cpp',
      'objc': 'objectivec',
      'objective-c': 'objectivec',
      'txt': 'plaintext',
      'text': 'plaintext',
      'md': 'markdown',
    };

    return languageMap[lower] ?? lower;
  }

  /// Builds an image widget from a [uri].
  ///
  /// Supports `data:` URIs (base64), HTTP(S) network
  /// images, and returns an error placeholder for
  /// unsupported schemes.
  static Widget buildImage(
    BuildContext context,
    Uri uri,
    JyotiGPTappThemeExtension theme,
  ) {
    if (uri.scheme == 'data') {
      return _buildBase64Image(uri.toString(), context, theme);
    }
    if (uri.scheme.isEmpty || uri.scheme == 'http' || uri.scheme == 'https') {
      return _buildNetworkImage(uri.toString(), context, theme);
    }
    return buildImageError(context, theme);
  }

  static Widget _buildBase64Image(
    String dataUrl,
    BuildContext context,
    JyotiGPTappThemeExtension theme,
  ) {
    try {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex == -1) {
        throw FormatException(
          AppLocalizations.of(context)?.invalidDataUrl ??
              'Invalid data URL format',
        );
      }

      final base64String = dataUrl.substring(commaIndex + 1);
      final imageBytes = base64.decode(base64String);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 480),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return buildImageError(context, theme);
            },
          ),
        ),
      );
    } catch (_) {
      return buildImageError(context, theme);
    }
  }

  static Widget _buildNetworkImage(
    String url,
    BuildContext context,
    JyotiGPTappThemeExtension theme,
  ) {
    // Read auth headers from Riverpod
    final container = ProviderScope.containerOf(context, listen: false);
    final headers = buildImageHeadersFromContainer(container);

    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: headers,
      placeholder: (context, _) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.surfaceBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: theme.loadingIndicator,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => buildImageError(context, theme),
      imageBuilder: (context, imageProvider) => Container(
        margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          image: DecorationImage(image: imageProvider, fit: BoxFit.contain),
        ),
      ),
    );
  }

  /// Builds an error placeholder for broken images.
  static Widget buildImageError(
    BuildContext context,
    JyotiGPTappThemeExtension theme,
  ) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.surfaceBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: theme.cardBorder.withValues(alpha: 0.4),
          width: BorderWidth.micro,
        ),
      ),
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: theme.iconSecondary),
      ),
    );
  }

  static Widget buildMermaidBlock(BuildContext context, String code) {
    final jyotigptappTheme = context.jyotigptappTheme;
    final materialTheme = Theme.of(context);

    if (MermaidDiagram.isSupported) {
      return _buildMermaidContainer(
        context: context,
        jyotigptappTheme: jyotigptappTheme,
        materialTheme: materialTheme,
        code: code,
      );
    }

    return _buildUnsupportedMermaidContainer(
      context: context,
      jyotigptappTheme: jyotigptappTheme,
      code: code,
    );
  }

  static Widget _buildMermaidContainer({
    required BuildContext context,
    required JyotiGPTappThemeExtension jyotigptappTheme,
    required ThemeData materialTheme,
    required String code,
  }) {
    final tokens = context.colorTokens;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(
          color: jyotigptappTheme.cardBorder.withValues(alpha: 0.4),
          width: BorderWidth.micro,
        ),
      ),
      height: 360,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        child: MermaidDiagram(
          code: code,
          brightness: materialTheme.brightness,
          colorScheme: materialTheme.colorScheme,
          tokens: tokens,
        ),
      ),
    );
  }

  static Widget _buildUnsupportedMermaidContainer({
    required BuildContext context,
    required JyotiGPTappThemeExtension jyotigptappTheme,
    required String code,
  }) {
    final l10n = AppLocalizations.of(context);
    final textStyle = AppTypography.bodySmallStyle.copyWith(
      color: jyotigptappTheme.codeText.withValues(alpha: 0.7),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: jyotigptappTheme.surfaceContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(
          color: jyotigptappTheme.cardBorder.withValues(alpha: 0.4),
          width: BorderWidth.micro,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n?.mermaidPreviewUnavailable ??
                'Mermaid preview is not available on this platform.',
            style: textStyle,
          ),
          const SizedBox(height: Spacing.xs),
          SelectableText(
            code,
            maxLines: null,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
            textWidthBasis: TextWidthBasis.parent,
            style: AppTypography.codeStyle.copyWith(
              color: jyotigptappTheme.codeText,
            ),
          ),
        ],
      ),
    );
  }

  /// Checks if HTML content contains ChartJS code patterns.
  static bool containsChartJs(String html) {
    return html.contains('new Chart(') || html.contains('Chart.');
  }

  /// Converts a Color to a hex string for use in HTML/CSS.
  static String colorToHex(Color color) {
    int channel(double value) => (value * 255).round().clamp(0, 255);
    final rgba =
        (channel(color.r) << 24) |
        (channel(color.g) << 16) |
        (channel(color.b) << 8) |
        channel(color.a);
    return '#${rgba.toRadixString(16).padLeft(8, '0')}';
  }

  /// Builds a ChartJS block for rendering in a WebView.
  static Widget buildChartJsBlock(BuildContext context, String htmlContent) {
    final jyotigptappTheme = context.jyotigptappTheme;
    final materialTheme = Theme.of(context);

    if (ChartJsDiagram.isSupported) {
      return _buildChartJsContainer(
        context: context,
        jyotigptappTheme: jyotigptappTheme,
        materialTheme: materialTheme,
        htmlContent: htmlContent,
      );
    }

    return _buildUnsupportedChartJsContainer(
      context: context,
      jyotigptappTheme: jyotigptappTheme,
    );
  }

  static Widget _buildChartJsContainer({
    required BuildContext context,
    required JyotiGPTappThemeExtension jyotigptappTheme,
    required ThemeData materialTheme,
    required String htmlContent,
  }) {
    final tokens = context.colorTokens;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(
          color: jyotigptappTheme.cardBorder.withValues(alpha: 0.4),
          width: BorderWidth.micro,
        ),
      ),
      height: 320,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        child: ChartJsDiagram(
          htmlContent: htmlContent,
          brightness: materialTheme.brightness,
          colorScheme: materialTheme.colorScheme,
          tokens: tokens,
        ),
      ),
    );
  }

  static Widget _buildUnsupportedChartJsContainer({
    required BuildContext context,
    required JyotiGPTappThemeExtension jyotigptappTheme,
  }) {
    final l10n = AppLocalizations.of(context);
    final textStyle = AppTypography.bodySmallStyle.copyWith(
      color: jyotigptappTheme.codeText.withValues(alpha: 0.7),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: jyotigptappTheme.surfaceContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(
          color: jyotigptappTheme.cardBorder.withValues(alpha: 0.4),
          width: BorderWidth.micro,
        ),
      ),
      child: Text(
        l10n?.chartPreviewUnavailable ??
            'Chart preview is not available on this platform.',
        style: textStyle,
      ),
    );
  }
}

/// Collapsible code block body with syntax highlighting.
///
/// When the code exceeds [collapseThreshold] lines, only the
/// first [previewLines] are shown with a toggle to reveal the
/// rest. Short code blocks render normally.
class _CodeBlockBody extends StatefulWidget {
  const _CodeBlockBody({
    required this.code,
    required this.highlightLanguage,
    required this.highlightTheme,
    required this.codeStyle,
    required this.isDark,
  });

  final String code;
  final String highlightLanguage;
  final Map<String, TextStyle> highlightTheme;
  final TextStyle codeStyle;
  final bool isDark;

  /// Lines above this count trigger collapse behavior.
  static const collapseThreshold = 15;

  /// Number of lines visible when collapsed.
  static const previewLines = 10;

  @override
  State<_CodeBlockBody> createState() => _CodeBlockBodyState();
}

class _CodeBlockBodyState extends State<_CodeBlockBody> {
  bool _isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    final lines = widget.code.split('\n');
    final isCollapsible = lines.length > _CodeBlockBody.collapseThreshold;
    final displayCode = (isCollapsible && _isCollapsed)
        ? lines.take(_CodeBlockBody.previewLines).join('\n')
        : widget.code;
    final hiddenCount = lines.length - _CodeBlockBody.previewLines;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm + 2,
            vertical: Spacing.sm,
          ),
          child: HighlightView(
            displayCode,
            language: widget.highlightLanguage,
            theme: widget.highlightTheme,
            padding: EdgeInsets.zero,
            textStyle: widget.codeStyle,
          ),
        ),
        if (isCollapsible)
          _CollapseToggle(
            isCollapsed: _isCollapsed,
            hiddenLineCount: hiddenCount,
            isDark: widget.isDark,
            onToggle: () {
              setState(() => _isCollapsed = !_isCollapsed);
            },
          ),
      ],
    );
  }
}

/// Toggle row for expanding or collapsing a code block.
///
/// Displays a chevron icon and descriptive text such as
/// "Show N more lines" or "Show less", separated from the
/// code by a subtle top border.
class _CollapseToggle extends StatelessWidget {
  const _CollapseToggle({
    required this.isCollapsed,
    required this.hiddenLineCount,
    required this.isDark,
    required this.onToggle,
  });

  final bool isCollapsed;
  final int hiddenLineCount;
  final bool isDark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelColor = colorScheme.onSurfaceVariant;
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm + 2,
          vertical: Spacing.xs + 1,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: borderColor, width: BorderWidth.thin),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AnimationDuration.fast,
              child: Icon(
                isCollapsed
                    ? Icons.expand_more_rounded
                    : Icons.expand_less_rounded,
                key: ValueKey(isCollapsed),
                size: 16,
                color: labelColor,
              ),
            ),
            const SizedBox(width: Spacing.xs),
            AnimatedSwitcher(
              duration: AnimationDuration.fast,
              child: Text(
                isCollapsed ? 'Show $hiddenLineCount more lines' : 'Show less',
                key: ValueKey(isCollapsed),
                style: AppTypography.codeStyle.copyWith(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Code block header with language label and copy button.
class CodeBlockHeader extends StatefulWidget {
  /// Creates a code block header.
  const CodeBlockHeader({
    super.key,
    required this.language,
    required this.backgroundColor,
    required this.borderColor,
    required this.isDark,
    required this.onCopy,
  });

  final String language;
  final Color backgroundColor;
  final Color borderColor;
  final bool isDark;
  final VoidCallback onCopy;

  @override
  State<CodeBlockHeader> createState() => _CodeBlockHeaderState();
}

class _CodeBlockHeaderState extends State<CodeBlockHeader> {
  bool _isHovering = false;
  bool _isCopied = false;

  void _handleCopy() {
    widget.onCopy();
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.language.isEmpty ? 'plaintext' : widget.language;

    // Colors derived from the code block theme for consistency
    final jyotigptappTheme = context.jyotigptappTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final labelColor = colorScheme.onSurfaceVariant;

    final iconColor = _isHovering ? colorScheme.onSurface : labelColor;

    final successColor = jyotigptappTheme.success;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm + 2,
        vertical: Spacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: widget.borderColor,
            width: BorderWidth.thin,
          ),
        ),
      ),
      child: Row(
        children: [
          // Language icon
          Icon(
            _getLanguageIcon(label),
            size: 14,
            color: labelColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: Spacing.xs),
          // Language label
          Text(
            label,
            style: AppTypography.codeStyle.copyWith(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          // Copy button with hover effect
          MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onTap: _handleCopy,
              child: AnimatedContainer(
                duration: AnimationDuration.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.xs + 2,
                  vertical: Spacing.xs - 1,
                ),
                decoration: BoxDecoration(
                  color: _isHovering
                      ? widget.borderColor.withValues(alpha: 0.5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: AnimationDuration.fast,
                      child: Icon(
                        _isCopied
                            ? Icons.check_rounded
                            : Icons.content_copy_rounded,
                        key: ValueKey(_isCopied),
                        size: 14,
                        color: _isCopied ? successColor : iconColor,
                      ),
                    ),
                    if (_isHovering || _isCopied) ...[
                      const SizedBox(width: Spacing.xs),
                      AnimatedOpacity(
                        duration: AnimationDuration.fast,
                        opacity: 1.0,
                        child: Text(
                          _isCopied ? 'Copied!' : 'Copy',
                          style: AppTypography.codeStyle.copyWith(
                            color: _isCopied ? successColor : iconColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns an appropriate icon for the language.
  IconData _getLanguageIcon(String language) {
    final lower = language.toLowerCase();
    return switch (lower) {
      'dart' || 'flutter' => Icons.flutter_dash_rounded,
      'python' || 'py' => Icons.code_rounded,
      'javascript' || 'js' || 'typescript' || 'ts' => Icons.javascript_rounded,
      'html' || 'css' || 'scss' => Icons.html_rounded,
      'json' || 'yaml' || 'yml' => Icons.data_object_rounded,
      'sql' || 'mysql' || 'postgresql' => Icons.storage_rounded,
      'bash' || 'shell' || 'sh' || 'zsh' => Icons.terminal_rounded,
      'markdown' || 'md' => Icons.article_rounded,
      'swift' || 'kotlin' || 'java' => Icons.phone_iphone_rounded,
      'rust' || 'go' || 'c' || 'cpp' || 'c++' => Icons.memory_rounded,
      'docker' || 'dockerfile' => Icons.cloud_rounded,
      _ => Icons.code_rounded,
    };
  }
}

// ChartJS diagram WebView widget
class ChartJsDiagram extends StatefulWidget {
  const ChartJsDiagram({
    super.key,
    required this.htmlContent,
    required this.brightness,
    required this.colorScheme,
    required this.tokens,
  });

  final String htmlContent;
  final Brightness brightness;
  final ColorScheme colorScheme;
  final AppColorTokens tokens;

  static bool get isSupported => !kIsWeb;

  static Future<String> _loadScript() {
    return _scriptFuture ??= rootBundle.loadString('assets/chartjs.min.js');
  }

  static Future<String>? _scriptFuture;

  @override
  State<ChartJsDiagram> createState() => _ChartJsDiagramState();
}

class _ChartJsDiagramState extends State<ChartJsDiagram> {
  WebViewController? _controller;
  String? _script;
  final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      };

  @override
  void initState() {
    super.initState();
    if (!ChartJsDiagram.isSupported) {
      return;
    }
    ChartJsDiagram._loadScript().then((value) {
      if (!mounted) {
        return;
      }
      _script = value;
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent);
      _loadHtml();
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(ChartJsDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null || _script == null) {
      return;
    }
    final contentChanged = oldWidget.htmlContent != widget.htmlContent;
    final themeChanged =
        oldWidget.brightness != widget.brightness ||
        oldWidget.colorScheme != widget.colorScheme ||
        oldWidget.tokens != widget.tokens;
    if (contentChanged || themeChanged) {
      _loadHtml();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox.expand(
      child: WebViewWidget(
        controller: _controller!,
        gestureRecognizers: _gestureRecognizers,
      ),
    );
  }

  void _loadHtml() {
    if (_controller == null || _script == null) {
      return;
    }
    _controller!.loadHtmlString(_buildHtml(widget.htmlContent, _script!));
  }

  String _buildHtml(String htmlContent, String script) {
    final isDark = widget.brightness == Brightness.dark;
    final background = JyotiGPTappMarkdown.colorToHex(
      isDark ? widget.tokens.codeBackground : widget.colorScheme.surface,
    );
    final textColor = JyotiGPTappMarkdown.colorToHex(widget.tokens.codeText);
    final gridColor = JyotiGPTappMarkdown.colorToHex(
      widget.colorScheme.outlineVariant.withValues(alpha: 0.45),
    );

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }
  html, body {
    width: 100%;
    height: 100%;
    background-color: $background;
    color: $textColor;
    overflow: hidden;
  }
  #chart-container {
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 8px;
  }
  canvas {
    max-width: 100%;
    max-height: 100%;
  }
</style>
</head>
<body>
<div id="chart-container">
  <canvas id="chart-canvas"></canvas>
</div>
<script>$script</script>
<script>
(function() {
  Chart.defaults.color = '$textColor';
  Chart.defaults.borderColor = '$gridColor';
  Chart.defaults.backgroundColor = '$background';

  try {
    const htmlContent = ${jsonEncode(htmlContent).replaceAll('</', r'<\/')};

    // Extract inline script blocks (skip external src= scripts).
    // Uses matchAll to collect all inline <script> bodies.
    const inlineScriptRe = /<script(?![^>]*\\bsrc\\b)[^>]*>([\\s\\S]*?)<\\/script>/gi;
    const userScript = [...htmlContent.matchAll(inlineScriptRe)]
      .map(m => m[1].trim())
      .filter(s => s.length > 0)
      .join('\\n');

    if (userScript) {
      // Redirect canvas getElementById calls to our chart-canvas so the
      // LLM script works even though its canvas element doesn't exist here.
      const _origGet = document.getElementById.bind(document);
      document.getElementById = function(id) {
        return _origGet(id) || _origGet('chart-canvas');
      };
      try {
        eval(userScript); // ignore: eval
      } finally {
        document.getElementById = _origGet;
      }
    }
  } catch (e) {
    console.error('Error creating chart:', e);
    document.getElementById('chart-container').innerHTML =
      '<p style="color: red; padding: 16px;">Error rendering chart: ' + e.message + '</p>';
  }
})();
</script>
</body>
</html>
''';
  }
}

// Mermaid diagram WebView widget
class MermaidDiagram extends StatefulWidget {
  const MermaidDiagram({
    super.key,
    required this.code,
    required this.brightness,
    required this.colorScheme,
    required this.tokens,
  });

  final String code;
  final Brightness brightness;
  final ColorScheme colorScheme;
  final AppColorTokens tokens;

  static bool get isSupported => !kIsWeb;

  static Future<String> _loadScript() {
    return _scriptFuture ??= rootBundle.loadString('assets/mermaid.min.js');
  }

  static Future<String>? _scriptFuture;

  @override
  State<MermaidDiagram> createState() => _MermaidDiagramState();
}

class _MermaidDiagramState extends State<MermaidDiagram> {
  WebViewController? _controller;
  String? _script;
  final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      };

  @override
  void initState() {
    super.initState();
    if (!MermaidDiagram.isSupported) {
      return;
    }
    MermaidDiagram._loadScript().then((value) {
      if (!mounted) {
        return;
      }
      _script = value;
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent);
      _loadHtml();
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(MermaidDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null || _script == null) {
      return;
    }
    final codeChanged = oldWidget.code != widget.code;
    final themeChanged =
        oldWidget.brightness != widget.brightness ||
        oldWidget.colorScheme != widget.colorScheme ||
        oldWidget.tokens != widget.tokens;
    if (codeChanged || themeChanged) {
      _loadHtml();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox.expand(
      child: WebViewWidget(
        controller: _controller!,
        gestureRecognizers: _gestureRecognizers,
      ),
    );
  }

  void _loadHtml() {
    if (_controller == null || _script == null) {
      return;
    }
    _controller!.loadHtmlString(
      _buildHtml(_sanitizeMermaidCode(widget.code), _script!),
    );
  }

  String _sanitizeMermaidCode(String source) {
    final lines = source.split('\n');
    final normalized = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed == 'end' || trimmed.startsWith('end %%')) {
        normalized.add(line);
        continue;
      }

      var updated = line;
      updated = updated.replaceFirstMapped(
        RegExp(r'^(\s*classDef\s+)end(\b)'),
        (match) => '${match[1]}endNode${match[2]}',
      );
      updated = updated.replaceFirstMapped(
        RegExp(r'^(\s*class\s+[^;\n]+\s+)end(\s*;?\s*)$'),
        (match) => '${match[1]}endNode${match[2]}',
      );

      normalized.add(updated);
    }

    return normalized.join('\n');
  }

  String _buildHtml(String code, String script) {
    final theme = widget.brightness == Brightness.dark ? 'dark' : 'default';
    final primary = JyotiGPTappMarkdown.colorToHex(widget.tokens.brandTone60);
    final secondary = JyotiGPTappMarkdown.colorToHex(widget.tokens.accentTeal60);
    final background = JyotiGPTappMarkdown.colorToHex(widget.tokens.codeBackground);
    final onBackground = JyotiGPTappMarkdown.colorToHex(widget.tokens.codeText);

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<style>
  body {
    margin: 0;
    background-color: transparent;
  }
  #container {
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: transparent;
  }
</style>
</head>
<body>
<div id="container">
  <div class="mermaid" id="mermaid-diagram"></div>
</div>
<script>$script</script>
<script>
  mermaid.initialize({
    startOnLoad: false,
    theme: '$theme',
    themeVariables: {
      primaryColor: '$primary',
      primaryTextColor: '$onBackground',
      primaryBorderColor: '$secondary',
      background: '$background'
    },
  });

  var diagramCode = ${jsonEncode(code)};

  async function renderValidated(id, source) {
    var parseResult = await mermaid.parse(source, { suppressErrors: false });
    if (!parseResult) {
      throw new Error('Mermaid parse failed');
    }
    var rendered = await mermaid.render(id, source);
    if (
      rendered &&
      rendered.svg &&
      rendered.svg.indexOf('Syntax error in text') !== -1
    ) {
      throw new Error('Mermaid render produced syntax error svg');
    }
    return rendered;
  }

  renderValidated('mermaid-svg', diagramCode).then(function(result) {
    document.getElementById('mermaid-diagram').innerHTML = result.svg;
  }).catch(function(err) {
    var message = err.message || String(err);
    document.getElementById('mermaid-diagram').innerHTML =
      '<pre style="color:red;padding:16px;">' + message + '</pre>';
  });
</script>
</body>
</html>
''';
  }
}
