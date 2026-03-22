import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Segmented control specifically for ThemeMode selection with
/// light/dark/system options.
class ThemeModeSegmentedControl extends StatelessWidget {
  /// Creates a segmented control for selecting a [ThemeMode].
  ///
  /// The [value] must be one of `ThemeMode.system`, `ThemeMode.light`, or
  /// `ThemeMode.dark`, and indicates the currently selected mode. The
  /// [onChanged] callback is invoked with the newly selected mode.
  const ThemeModeSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// The currently selected theme mode.
  final ThemeMode value;

  /// Called when the user selects a different [ThemeMode].
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
