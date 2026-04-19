import 'package:flutter/material.dart';
import '../../theme/tripi_colors.dart';
import '../../widgets/tripi_card.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SECURITY & PRIVACY', style: TextStyle(fontSize: 10, letterSpacing: 1, color: TripiColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Security', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'Authentication',
              [
                _buildSecurityAction('Change password', Icons.lock_outline),
                const SizedBox(height: 16),
                _buildToggleItem(context, 'Two-Factor Auth', 'Secure your account with SMS or App', true),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Security Alerts',
              [
                _buildAlertItem('New device login', true),
                _buildAlertItem('Suspicious activity', true),
                _buildAlertItem('Weekly security report', false),
              ],
            ),
            const SizedBox(height: 24),
            _buildActiveSessions(context),
            const SizedBox(height: 24),
            _buildRolesPermissions(context),
            const SizedBox(height: 24),
            _buildActivityLog(context),
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

  Widget _buildSecurityAction(String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }

  Widget _buildToggleItem(BuildContext context, String title, String subtitle, bool value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: TripiColors.onSurfaceVariant, fontSize: 11)),
            ],
          ),
        ),
        Switch(value: value, onChanged: (v) {}, activeColor: TripiColors.primary),
      ],
    );
  }

  Widget _buildAlertItem(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(Icons.devices, size: 20, color: TripiColors.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Icon(value ? Icons.check_circle : Icons.circle_outlined, color: value ? TripiColors.primary : TripiColors.outlineVariant),
        ],
      ),
    );
  }

  Widget _buildActiveSessions(BuildContext context) {
    return _buildSection(context, 'Active Sessions', [
      _buildSessionItem('iPhone 15 Pro', 'London, UK • Current Session', true),
      const Divider(height: 32),
      _buildSessionItem('MacBook Pro M3', 'Paris, France • Last active 2h ago', false),
    ]);
  }

  Widget _buildSessionItem(String device, String details, bool isActive) {
    return Row(
      children: [
        Icon(isActive ? Icons.smartphone : Icons.laptop, color: TripiColors.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(device, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(details, style: const TextStyle(color: TripiColors.onSurfaceVariant, fontSize: 11)),
            ],
          ),
        ),
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: TripiColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('ACTIVE NOW', style: TextStyle(color: TripiColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
          )
        else
          const Icon(Icons.logout, size: 20, color: TripiColors.onSurfaceVariant),
      ],
    );
  }

  Widget _buildRolesPermissions(BuildContext context) {
    return _buildSection(context, 'Roles & Permissions', [
      _buildRoleCard('Admin', 'Full access to all modules and billing.', 2),
      const SizedBox(height: 12),
      _buildRoleCard('Editor', 'Manage content, flights, and bookings.', 12),
      const SizedBox(height: 12),
      _buildRoleCard('Viewer', 'Read-only access to dashboard data.', 45),
    ]);
  }

  Widget _buildRoleCard(String role, String desc, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TripiColors.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: TripiColors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 12),
          Text('$count Members', style: const TextStyle(color: TripiColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildActivityLog(BuildContext context) {
    return _buildSection(context, 'Security Activity Log', [
      _buildLogItem('Successful Login - Admin Portal', 'alex.nav@travel.com', '12:45 PM'),
      _buildLogItem('2FA Settings Changed', 'sarah.editor@travel.com', '10:30 AM'),
      _buildLogItem('Failed Password Attempt', 'Unknown User', '09:15 AM', isError: true),
    ]);
  }

  Widget _buildLogItem(String action, String user, String time, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.history, color: isError ? Colors.red : TripiColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(user, style: const TextStyle(color: TripiColors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: TripiColors.onSurfaceVariant, fontSize: 10)),
        ],
      ),
    );
  }
}
