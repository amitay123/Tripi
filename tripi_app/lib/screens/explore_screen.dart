import 'package:flutter/material.dart';
import '../theme/tripi_colors.dart';
import 'trips_screen.dart';
import 'explore_map_content.dart';
import 'settings/settings_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TripsScreen(),
    const Center(child: Text('Timeline Screen')),
    const ExploreContent(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark
        ? const Color(0xFF161B1F).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.96);
    final borderColor = isDark
        ? const Color(0xFF1C2227)
        : TripiColors.surfaceContainerLow;

    return Scaffold(
      backgroundColor: isDark
          ? TripiColors.darkBackground
          : TripiColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.luggage, 'TRIPS'),
              _buildNavItem(1, Icons.calendar_month_outlined, 'TIMELINE'),
              _buildNavItem(2, Icons.map_outlined, 'EXPLORE'),
              _buildNavItem(3, Icons.settings_outlined, 'SETTINGS'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    const activeColor = Color(0xFF0060AD);
    const inactiveColor = Color(0xFF9CA3AF);

    return Semantics(
      label: label,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? activeColor : inactiveColor,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
