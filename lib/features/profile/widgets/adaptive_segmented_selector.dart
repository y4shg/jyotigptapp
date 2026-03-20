import 'dart:io' show Platform;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/theme_extensions.dart';

/// A generic segmented selector that adapts to Cupertino on iOS/macOS
/// and Material SegmentedButton on other platforms.
class AdaptiveSegmentedSelector<T extends Object> extends StatelessWidget {
  const AdaptiveSegmentedSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<
    ({
      T value,
      String label,
      IconData cupertinoIcon,
      IconData materialIcon,
      bool enabled,
    })
  >
  options;

  @override
  Widget build(BuildContext context) {
    final isCupertino =
        Platform.isIOS || Theme.of(context).platform == TargetPlatform.macOS;

    if (isCupertino) {
      return CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        disabledChildren: {
          for (final option in options)
            if (!option.enabled) option.value,
        },
        onValueChanged: (next) {
          if (next == null) return;
          final selected = options.any(
            (option) => option.value == next && option.enabled,
          );
          if (selected) {
            onChanged(next);
          }
        },
        children: {
          for (final option in options)
            option.value: ThemeModeSegmentLabel(
              icon: option.cupertinoIcon,
              label: option.label,
            ),
        },
      );
    }

    return SegmentedButton<T>(
      selected: {value},
      showSelectedIcon: false,
      segments: [
        for (final option in options)
          ButtonSegment<T>(
            value: option.value,
            icon: Icon(option.materialIcon),
            label: Text(option.label),
            enabled: option.enabled,
          ),
      ],
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        final next = selection.first;
        final selected = options.any(
          (option) => option.value == next && option.enabled,
        );
        if (selected) {
          onChanged(next);
        }
      },
    );
  }
}

/// Segmented control specifically for ThemeMode selection with
/// light/dark/system options.
class ThemeModeSegmentedControl extends StatelessWidget {
  const ThemeModeSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  static const List<ThemeMode> _themeModes = <ThemeMode>[
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedIndex = _themeModes.indexOf(value);

    return AdaptiveSegmentedControl(
      labels: <String>[
        l10n.system,
        l10n.themeLight,
        l10n.themeDark,
      ],
      selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
      onValueChanged: (index) {
        if (index < 0 || index >= _themeModes.length) {
          return;
        }
        onChanged(_themeModes[index]);
      },
    );
  }
}

/// Label widget used inside segmented controls showing an icon and text.
class ThemeModeSegmentLabel extends StatelessWidget {
  const ThemeModeSegmentLabel({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: IconSize.small),
          const SizedBox(width: Spacing.xs),
          Text(label),
        ],
      ),
    );
  }
}
