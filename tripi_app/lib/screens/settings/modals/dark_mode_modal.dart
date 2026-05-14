import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import 'settings_widgets.dart';

class DarkModeModal extends StatefulWidget {
  final String current;
  const DarkModeModal({super.key, required this.current});

  @override
  State<DarkModeModal> createState() => _DarkModeModalState();
}

class _DarkModeModalState extends State<DarkModeModal> {
  static const options = [
    ('system', Icons.phone_android_outlined, 'System Default',
        'Follows your device appearance setting.'),
    ('light', Icons.wb_sunny_outlined, 'Light Mode',
        'Always use light theme.'),
    ('dark', Icons.dark_mode_outlined, 'Dark Mode',
        'Always use dark theme.'),
  ];

  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SettingsModalShell(
      title: 'Appearance',
      subtitle: 'Choose your preferred theme',
      isDark: isDark,
      onApply: () async {
        final navigator = Navigator.of(context);
        await context
            .read<SettingsProvider>()
            .updateField((s) => s.copyWith(darkMode: _selected),
                analyticsEvent: 'theme_changed',
                analyticsParams: {'mode': _selected});
        if (mounted) navigator.pop();
      },
      child: Column(
        children: options.map((opt) {
          final (value, icon, label, desc) = opt;
          return SettingsOptionTile(
            icon: icon,
            label: label,
            subtitle: desc,
            selected: _selected == value,
            isDark: isDark,
            onTap: () => setState(() => _selected = value),
          );
        }).toList(),
      ),
    );
  }
}
