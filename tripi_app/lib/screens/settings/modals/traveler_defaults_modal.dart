import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

class TravelerDefaultsModal extends StatefulWidget {
  final int adults;
  final int children;
  const TravelerDefaultsModal(
      {super.key, required this.adults, required this.children});

  @override
  State<TravelerDefaultsModal> createState() => _TravelerDefaultsModalState();
}

class _TravelerDefaultsModalState extends State<TravelerDefaultsModal> {
  late int _adults;
  late int _children;

  @override
  void initState() {
    super.initState();
    _adults = widget.adults;
    _children = widget.children;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161B1F) : Colors.white;
    final onSurface = isDark ? const Color(0xFFE4E8EA) : const Color(0xFF2D3335);
    final onVariant =
        isDark ? const Color(0xFF9AABB3) : const Color(0xFF5A6062);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Traveler Defaults',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: onSurface)),
              const SizedBox(height: 4),
              Text('Auto-filled for every new trip',
                  style: GoogleFonts.inter(fontSize: 14, color: onVariant)),
              const SizedBox(height: 28),
              _Counter(
                label: 'Adults',
                subtitle: 'Age 13+',
                value: _adults,
                min: 1,
                max: 16,
                isDark: isDark,
                onSurface: onSurface,
                onVariant: onVariant,
                onChanged: (v) => setState(() => _adults = v),
              ),
              const SizedBox(height: 16),
              _Counter(
                label: 'Children',
                subtitle: 'Ages 2–12',
                value: _children,
                min: 0,
                max: 12,
                isDark: isDark,
                onSurface: onSurface,
                onVariant: onVariant,
                onChanged: (v) => setState(() => _children = v),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await context
                        .read<SettingsProvider>()
                        .updateField((s) => s.copyWith(
                              defaultAdults: _adults,
                              defaultChildren: _children,
                            ),
                            analyticsEvent: 'traveler_defaults_changed');
                    if (mounted) navigator.pop();
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final bool isDark;
  final Color onSurface;
  final Color onVariant;
  final ValueChanged<int> onChanged;

  const _Counter({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.isDark,
    required this.onSurface,
    required this.onVariant,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: onSurface)),
              Text(subtitle,
                  style:
                      GoogleFonts.inter(fontSize: 12, color: onVariant)),
            ],
          ),
        ),
        Row(
          children: [
            _CircleButton(
              icon: Icons.remove,
              enabled: value > min,
              isDark: isDark,
              onTap: () => onChanged(value - 1),
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: Text('$value',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: onSurface)),
              ),
            ),
            _CircleButton(
              icon: Icons.add,
              enabled: value < max,
              isDark: isDark,
              onTap: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? (isDark
                  ? const Color(0xFF1C2227)
                  : const Color(0xFFF1F4F5))
              : Colors.transparent,
          border: Border.all(
            color: enabled
                ? (isDark
                    ? const Color(0xFF2A3540)
                    : const Color(0xFFDDE1E3))
                : Colors.transparent,
          ),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled
                ? (isDark
                    ? const Color(0xFFE4E8EA)
                    : const Color(0xFF2D3335))
                : Colors.grey.withValues(alpha: 0.4)),
      ),
    );
  }
}
