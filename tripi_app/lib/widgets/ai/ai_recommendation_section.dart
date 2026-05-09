import 'package:flutter/material.dart';
import '../../models/ai_models.dart';
import '../../theme/tripi_colors.dart';
import 'ai_horizontal_card.dart';

/// A labeled horizontal-scroll section containing [AiHorizontalCard] items.
///
/// Shows a section header with icon, title, and count badge, then a
/// horizontally-scrollable row of cards.
///
/// If [items] is empty and [showWhenEmpty] is true, renders a styled
/// "disabled" placeholder instead.
class AiRecommendationSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<AiSuggestion> items;
  final void Function(AiSuggestion) onAdd;

  /// If true and items is empty, shows a disabled/inactive placeholder.
  final bool showWhenEmpty;

  /// Optional short string shown in the placeholder when disabled.
  final String? disabledHint;

  const AiRecommendationSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.items,
    required this.onAdd,
    this.showWhenEmpty = false,
    this.disabledHint,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !showWhenEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 14),
        items.isEmpty ? _buildDisabledPlaceholder() : _buildScrollRow(),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          // Count badge
          if (items.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScrollRow() {
    return SizedBox(
      height: 348, // card image 130 + padding + content
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 6),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final suggestion = items[index];
          return AiHorizontalCard(
            suggestion: suggestion,
            onAdd: () => onAdd(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildDisabledPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.grey[400], size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title disabled',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (disabledHint != null)
                    Text(
                      disabledHint!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active-toggle chip row ────────────────────────────────────────────────────

/// A horizontally-scrollable row of chips summarising which toggles are active.
class AiOptionsChipRow extends StatelessWidget {
  final AiGenerationOptions options;

  const AiOptionsChipRow({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    final chips = _buildChips();
    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  List<Widget> _buildChips() {
    final chips = <Widget>[];

    // Exploration style
    chips.add(_chip(
      label: options.explorationStyle == ExplorationStyle.insideCity
          ? 'Inside City'
          : 'Explore Outside',
      icon: options.explorationStyle == ExplorationStyle.insideCity
          ? Icons.location_city_rounded
          : Icons.terrain_rounded,
      color: TripiColors.primary,
    ));

    if (options.focusPopular) {
      chips.add(_chip(
          label: 'Must-See Landmarks',
          icon: Icons.star_rounded,
          color: const Color(0xFFF59E0B)));
    }
    if (options.localGems) {
      chips.add(_chip(
          label: 'Local Gems',
          icon: Icons.explore_rounded,
          color: const Color(0xFF10B981)));
    }
    if (options.familyFriendly) {
      chips.add(_chip(
          label: 'Family Friendly',
          icon: Icons.family_restroom_rounded,
          color: const Color(0xFF6366F1)));
    }
    if (options.includeRestaurants) {
      chips.add(_chip(
          label: 'Restaurants',
          icon: Icons.restaurant_rounded,
          color: const Color(0xFFEF4444)));
    }
    if (options.includeCafes) {
      chips.add(_chip(
          label: 'Cafes',
          icon: Icons.coffee_rounded,
          color: const Color(0xFF8B5CF6)));
    }
    if (options.leaveFreetime) {
      chips.add(_chip(
          label: 'Spontaneity',
          icon: Icons.hourglass_empty_rounded,
          color: Colors.teal));
    }

    return chips;
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
