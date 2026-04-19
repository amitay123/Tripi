import 'package:flutter/material.dart';
import '../../theme/tripi_colors.dart';
import '../../widgets/tripi_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WORKSPACE CONFIGURATION', style: TextStyle(fontSize: 10, letterSpacing: 1, color: TripiColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Settings', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'Trip Settings',
              [
                _buildSettingItem(
                  context,
                  'Distance Units',
                  'Prefer kilometers or miles for itinerary legs',
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: TripiColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUnitTab('km', true),
                        _buildUnitTab('miles', false),
                      ],
                    ),
                  ),
                ),
                _buildDropdownItem(context, Icons.grid_view_rounded, 'Default trip view', 'Timeline Grid'),
                _buildDropdownItem(context, Icons.map_outlined, 'Map type', 'Standard (Vector)'),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'Notifications',
              [
                _buildToggleItem(context, 'New trip creation', 'Notify when a travel agent starts a new draft.', true),
                _buildToggleItem(context, 'System Updates', 'Stay informed about new app features and maintenance.', false),
                const SizedBox(height: 16),
                const Text('PREFERRED CHANNELS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TripiColors.onSurfaceVariant)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildCheckbox('Email', true),
                    const SizedBox(width: 24),
                    _buildCheckbox('Push Notifications', true),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'UI Preferences',
              [
                _buildToggleItem(context, 'Dark Mode', 'Easier on the eyes in low light.', false),
                _buildToggleItem(context, 'Compact Layout', 'Maximize information density.', true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TripiCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(BuildContext context, String title, String subtitle, {required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: TripiColors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildUnitTab(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? TripiColors.primary : TripiColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDropdownItem(BuildContext context, IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: TripiColors.primary),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TripiColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 13)),
                const Icon(Icons.keyboard_arrow_down, color: TripiColors.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(BuildContext context, String title, String subtitle, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: TripiColors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {},
            activeColor: TripiColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: value ? TripiColors.primary : Colors.transparent,
            border: Border.all(color: value ? TripiColors.primary : TripiColors.outlineVariant),
            borderRadius: BorderRadius.circular(6),
          ),
          child: value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
