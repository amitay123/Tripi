import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

class TripStyleModal extends StatefulWidget {
  final List<String> selected;
  const TripStyleModal({super.key, required this.selected});

  @override
  State<TripStyleModal> createState() => _TripStyleModalState();
}

class _TripStyleModalState extends State<TripStyleModal> {
  static const _styles = [
    ('Adventure', Icons.terrain_rounded, 'Off-beaten paths, nature, adrenaline'),
    ('Cultural', Icons.museum_outlined, 'History, art, architecture, local life'),
    ('Relaxation', Icons.self_improvement_outlined, 'Spas, beaches, slow travel'),
    ('Foodie', Icons.restaurant_outlined, 'Street food, fine dining, markets'),
    ('Shopping', Icons.shopping_bag_outlined, 'Markets, boutiques, souvenirs'),
    ('Nightlife', Icons.nightlife_outlined, 'Bars, clubs, live music'),
    ('Family', Icons.family_restroom_rounded, 'Kid-friendly, parks, activities'),
    ('Romantic', Icons.favorite_border_rounded, 'Intimate spots, sunsets, fine dining'),
    ('Budget', Icons.savings_outlined, 'Free attractions, hostels, local transit'),
  ];

  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161B1F) : Colors.white;
    final onSurface = isDark ? const Color(0xFFE4E8EA) : const Color(0xFF2D3335);
    final onVariant = isDark ? const Color(0xFF9AABB3) : const Color(0xFF5A6062);

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
              Text('Trip Style',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: onSurface)),
              const SizedBox(height: 4),
              Text('Affects AI recommendation scoring globally.',
                  style: GoogleFonts.inter(fontSize: 14, color: onVariant)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _styles.map((style) {
                  final (name, icon, _) = style;
                  final isSelected = _selected.contains(name);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) {
                        _selected.remove(name);
                      } else {
                        _selected.add(name);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0060AD)
                            : (isDark
                                ? const Color(0xFF1C2227)
                                : const Color(0xFFF1F4F5)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0060AD)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : onVariant),
                          const SizedBox(width: 6),
                          Text(name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : onSurface,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
                        .updateField(
                            (s) => s.copyWith(tripStyles: _selected.toList()),
                            analyticsEvent: 'trip_style_changed');
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
