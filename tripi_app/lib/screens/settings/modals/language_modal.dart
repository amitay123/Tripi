import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

class LanguageModal extends StatefulWidget {
  final String current;
  const LanguageModal({super.key, required this.current});

  @override
  State<LanguageModal> createState() => _LanguageModalState();
}

class _LanguageModalState extends State<LanguageModal> {
  static const _languages = [
    ('en', '🇺🇸', 'English', 'English'),
    ('he', '🇮🇱', 'עברית', 'Hebrew — Right to left'),
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
    final bgColor = isDark ? const Color(0xFF161B1F) : Colors.white;
    final onSurface =
        isDark ? const Color(0xFFE4E8EA) : const Color(0xFF2D3335);
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
              Text('Language',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: onSurface)),
              const SizedBox(height: 4),
              Text('Affects AI responses and UI labels',
                  style: GoogleFonts.inter(fontSize: 14, color: onVariant)),
              const SizedBox(height: 20),
              ..._languages.map((lang) {
                final (code, flag, name, desc) = lang;
                final isSelected = _selected == code;
                return GestureDetector(
                  onTap: () => setState(() => _selected = code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0060AD).withValues(alpha: 0.08)
                          : (isDark
                              ? const Color(0xFF1C2227)
                              : const Color(0xFFF8F9FA)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0060AD)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(flag, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFF0060AD)
                                          : onSurface)),
                              Text(desc,
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: onVariant)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              size: 20, color: Color(0xFF0060AD)),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await context
                        .read<SettingsProvider>()
                        .updateField(
                            (s) => s.copyWith(language: _selected),
                            analyticsEvent: 'language_changed',
                            analyticsParams: {'lang': _selected});
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
