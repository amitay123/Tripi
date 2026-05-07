import 'package:flutter/material.dart';
import '../../models/ai_models.dart';
import '../../theme/tripi_colors.dart';

class AiPlanningOptionsSheet extends StatefulWidget {
  final Function(AiGenerationOptions) onGenerate;

  const AiPlanningOptionsSheet({super.key, required this.onGenerate});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TripiColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome, color: TripiColors.primary),
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
          const SizedBox(height: 32),
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
                );
                widget.onGenerate(opts);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TripiColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome),
                  SizedBox(width: 12),
                  Text(
                    'Generate Itinerary',
                    style: TextStyle(
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
    );
  }

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
        activeColor: TripiColors.primary,
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
          color: isSelected ? TripiColors.primary.withOpacity(0.1) : Colors.white,
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
