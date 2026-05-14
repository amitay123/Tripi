import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import 'settings_widgets.dart';

class IntensityModal extends StatefulWidget {
  final String current;
  const IntensityModal({super.key, required this.current});

  @override
  State<IntensityModal> createState() => _IntensityModalState();
}

class _IntensityModalState extends State<IntensityModal> {
  static const _options = [
    ('relaxed', Icons.spa_outlined, 'Relaxed',
        '1–2 attractions/day. Slow pace, long breaks.'),
    ('balanced', Icons.balance_outlined, 'Balanced',
        '3–4 attractions/day. Mix of rest and activity.'),
    ('intensive', Icons.rocket_launch_outlined, 'Intensive',
        '5–7 attractions/day. Full days, minimal downtime.'),
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
      title: 'Intensity Level',
      subtitle: 'How packed do you want your days?',
      isDark: isDark,
      onApply: () async {
        final navigator = Navigator.of(context);
        await context
            .read<SettingsProvider>()
            .updateField((s) => s.copyWith(intensityLevel: _selected),
                analyticsEvent: 'intensity_changed',
                analyticsParams: {'level': _selected});
        if (mounted) navigator.pop();
      },
      child: Column(
        children: _options.map((opt) {
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
