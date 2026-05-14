import 'package:flutter/material.dart';
import '../../models/ai_models.dart';
import '../../theme/tripi_colors.dart';

class AiPlanningOptionsSheet extends StatefulWidget {
  final int maxDays;
  final Function(int dayIndex, AiGenerationOptions options) onGenerate;

  const AiPlanningOptionsSheet({
    super.key,
    required this.onGenerate,
    this.maxDays = 1,
  });

  @override
  State<AiPlanningOptionsSheet> createState() => _AiPlanningOptionsSheetState();
}

class _AiPlanningOptionsSheetState extends State<AiPlanningOptionsSheet> {
  bool includeRestaurants = true;
  bool includeCafes = true;
  bool localGems = false;
  bool focusPopular = true;
  bool familyFriendly = false;
  bool leaveFreetime = false;
  ExplorationStyle explorationStyle = ExplorationStyle.insideCity;
  late int selectedDay;

  @override
  void initState() {
    super.initState();
    selectedDay = 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TripiColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: TripiColors.primary),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Trip Assistant',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tailor your perfect itinerary',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Day Selector ─────────────────────────────────────────────────
            if (widget.maxDays > 1) ...[
              Text(
                'SELECT DAY',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.maxDays,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final isSelected = selectedDay == day;
                    return InkWell(
                      onTap: () => setState(() => selectedDay = day),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? TripiColors.primary : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? TripiColors.primary : Colors.grey[300]!,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Day $day',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Trip Exploration Style ────────────────────────────────────────
            Text(
              'TRIP EXPLORATION STYLE',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.grey[600],
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildExplorationStyleSelector(),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey(explorationStyle),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: explorationStyle == ExplorationStyle.insideCity
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      explorationStyle == ExplorationStyle.insideCity
                          ? Icons.info_outline
                          : Icons.explore_outlined,
                      size: 15,
                      color: explorationStyle == ExplorationStyle.insideCity
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        explorationStyle == ExplorationStyle.insideCity
                            ? 'Museums, restaurants, landmarks & walkable city experiences'
                            : 'Castles, historic towns, day-trip landmarks, parks & scenic attractions outside the city',
                        style: TextStyle(
                          fontSize: 12,
                          color: explorationStyle == ExplorationStyle.insideCity
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Divider(height: 1),
            const SizedBox(height: 20),

            // ── Interests & Preferences ───────────────────────────────────────
            Text(
              'INTERESTS & PREFERENCES',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.grey[600],
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              title: 'Include Local Gems',
              subtitle: 'Places favored by locals, off the beaten path',
              value: localGems,
              onChanged: (v) => setState(() => localGems = v),
              icon: Icons.explore_outlined,
            ),
            _buildOptionTile(
              title: 'Must-See Landmarks',
              subtitle: 'Focus on top-rated, popular destinations',
              value: focusPopular,
              onChanged: (v) => setState(() => focusPopular = v),
              icon: Icons.star_outline,
            ),
            _buildOptionTile(
              title: 'Family Friendly',
              subtitle: 'Activities suitable for all ages',
              value: familyFriendly,
              onChanged: (v) => setState(() => familyFriendly = v),
              icon: Icons.family_restroom_outlined,
            ),
            const Divider(height: 32),
            Text(
              'FOOD & PACING',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.grey[600],
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildChipOption(
                    label: 'Restaurants',
                    isSelected: includeRestaurants,
                    onTap: () => setState(() => includeRestaurants = !includeRestaurants),
                    icon: Icons.restaurant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChipOption(
                    label: 'Cafes',
                    isSelected: includeCafes,
                    onTap: () => setState(() => includeCafes = !includeCafes),
                    icon: Icons.coffee,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              title: 'Leave Room for Spontaneity',
              subtitle: 'Generate a lighter schedule with more gaps',
              value: leaveFreetime,
              onChanged: (v) => setState(() => leaveFreetime = v),
              icon: Icons.hourglass_empty_rounded,
            ),
            const SizedBox(height: 32),

            // ── Generate Button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final opts = AiGenerationOptions(
                    includeRestaurants: includeRestaurants,
                    includeCafes: includeCafes,
                    localGems: localGems,
                    focusPopular: focusPopular,
                    familyFriendly: familyFriendly,
                    leaveFreetime: leaveFreetime,
                    explorationStyle: explorationStyle,
                  );
                  Navigator.pop(context);
                  widget.onGenerate(selectedDay, opts);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TripiColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome),
                    const SizedBox(width: 12),
                    Text(
                      explorationStyle == ExplorationStyle.outsideCity
                          ? 'Generate Day Trip'
                          : 'Generate Itinerary',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Exploration Style Segmented Selector ────────────────────────────────────

  Widget _buildExplorationStyleSelector() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildStyleSegment(
            label: 'Stay Inside the City',
            icon: Icons.location_city_rounded,
            style: ExplorationStyle.insideCity,
          ),
          _buildStyleSegment(
            label: 'Explore Outside',
            icon: Icons.terrain_rounded,
            style: ExplorationStyle.outsideCity,
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSegment({
    required String label,
    required IconData icon,
    required ExplorationStyle style,
  }) {
    final isSelected = explorationStyle == style;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => explorationStyle = style),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? TripiColors.primary : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? TripiColors.primary : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared Tile Builders ────────────────────────────────────────────────────

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: TripiColors.primary,
        activeTrackColor: TripiColors.primary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildChipOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? TripiColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? TripiColors.primary : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? TripiColors.primary : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? TripiColors.primary : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
