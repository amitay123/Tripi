import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsModalShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onApply;
  final Widget child;

  const SettingsModalShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onApply,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: onSurface)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: GoogleFonts.inter(fontSize: 14, color: onVariant)),
              const SizedBox(height: 20),
              child,
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onApply,
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

class SettingsOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const SettingsOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface =
        isDark ? const Color(0xFFE4E8EA) : const Color(0xFF2D3335);
    final onVariant =
        isDark ? const Color(0xFF9AABB3) : const Color(0xFF5A6062);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0060AD).withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF1C2227) : const Color(0xFFF8F9FA)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF0060AD) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected ? const Color(0xFF0060AD) : onVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? const Color(0xFF0060AD)
                              : onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 12, color: onVariant)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: Color(0xFF0060AD)),
          ],
        ),
      ),
    );
  }
}
