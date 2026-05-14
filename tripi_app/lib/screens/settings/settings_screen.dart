import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/settings_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/ai_provider.dart';
import '../../services/analytics_service.dart';
import '../../theme/tripi_colors.dart';
import 'edit_profile_screen.dart';
import 'personal_details_screen.dart';
import 'modals/intensity_modal.dart';
import 'modals/traveler_defaults_modal.dart';
import 'modals/trip_style_modal.dart';
import 'modals/dark_mode_modal.dart';
import 'modals/language_modal.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsView();
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message, style: GoogleFonts.inter(fontSize: 14)),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
          'You will be signed out of your account on this device.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay Signed In'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final aiProvider = Provider.of<AiProvider>(context, listen: false);

    await settingsProvider.logout();
    bookingProvider.logout();
    aiProvider.reset();

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? TripiColors.darkBackground
        : TripiColors.surfaceContainerLow;
    final cardColor = isDark
        ? TripiColors.darkSurfaceContainerLowest
        : TripiColors.surfaceContainerLowest;
    final onSurface =
        isDark ? TripiColors.darkOnSurface : TripiColors.onSurface;
    final onVariant =
        isDark ? TripiColors.darkOnSurfaceVariant : TripiColors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Header(
                isDark: isDark,
                onSurface: onSurface,
                user: user,
                cardColor: cardColor,
                onVariant: onVariant,
              ),
            ),

            // ── Profile Card ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _ProfileCard(
                  user: user,
                  cardColor: cardColor,
                  onSurface: onSurface,
                  onVariant: onVariant,
                  settings: settings,
                ),
              ),
            ),

            // ── Account & Profile ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Section(
                title: 'ACCOUNT & PROFILE',
                cardColor: cardColor,
                onVariant: onVariant,
                children: [
                  _SettingsRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen())),
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                  _SettingsRow(
                    icon: Icons.badge_outlined,
                    label: 'Personal Details',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const PersonalDetailsScreen())),
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                ],
              ),
            ),

            // ── Trip Preferences ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Section(
                title: 'TRIP PREFERENCES',
                cardColor: cardColor,
                onVariant: onVariant,
                children: [
                  _SettingsRow(
                    icon: Icons.speed_rounded,
                    label: 'Intensity Level',
                    trailing: _ValueBadge(
                        _capitalize(settings.settings.intensityLevel),
                        onVariant),
                    onTap: () async {
                      await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => IntensityModal(
                              current: settings.settings.intensityLevel));
                      if (mounted) _showSuccess('Intensity updated');
                    },
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                  _SettingsRow(
                    icon: Icons.people_outline_rounded,
                    label: 'Traveler Defaults',
                    trailing: _ValueBadge(
                        '${settings.settings.defaultAdults} Adults, ${settings.settings.defaultChildren} Kids',
                        onVariant),
                    onTap: () async {
                      await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => TravelerDefaultsModal(
                              adults: settings.settings.defaultAdults,
                              children:
                                  settings.settings.defaultChildren));
                      if (mounted) _showSuccess('Travelers updated');
                    },
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                  _SettingsRow(
                    icon: Icons.style_outlined,
                    label: 'Trip Style',
                    trailing: _ValueBadge(
                        settings.settings.tripStyles.isEmpty
                            ? 'Not set'
                            : settings.settings.tripStyles.length == 1
                                ? settings.settings.tripStyles.first
                                : '${settings.settings.tripStyles.length} styles',
                        onVariant),
                    onTap: () async {
                      await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => TripStyleModal(
                              selected: settings.settings.tripStyles));
                      if (mounted) _showSuccess('Trip style updated');
                    },
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                ],
              ),
            ),

            // ── Security & Privacy ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Section(
                title: 'SECURITY & PRIVACY',
                cardColor: cardColor,
                onVariant: onVariant,
                children: [
                  _SettingsRow(
                    icon: Icons.lock_reset_rounded,
                    label: 'Reset Password',
                    onTap: () {
                      // Navigate to existing reset password screen
                      Navigator.pushNamed(context, '/set-new-password');
                    },
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                  _SettingsToggleRow(
                    icon: Icons.security_rounded,
                    label: 'Security Alerts',
                    value: settings.settings.securityAlerts,
                    onChanged: (v) async {
                      await settings.updateField(
                          (s) => s.copyWith(securityAlerts: v),
                          analyticsEvent: SettingsAnalyticsEvents.pushToggled,
                          analyticsParams: {'type': 'security_alerts', 'enabled': v});
                      if (mounted) _showSuccess('Security alerts ${v ? 'enabled' : 'disabled'}');
                    },
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                  _SettingsRow(
                    icon: Icons.devices_rounded,
                    label: 'Active Sessions',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0060AD).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Current',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0060AD))),
                    ),
                    onTap: () {
                      // Future: show session list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Session management coming soon')),
                      );
                    },
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                ],
              ),
            ),

            // ── Notifications ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Section(
                title: 'NOTIFICATIONS',
                cardColor: cardColor,
                onVariant: onVariant,
                children: [
                  _SettingsToggleRow(
                    icon: Icons.notifications_outlined,
                    label: 'Push Notifications',
                    subtitle: 'Itinerary reminders & AI suggestions',
                    value: settings.settings.pushItineraryReminders &&
                        settings.settings.pushAiSuggestions,
                    onChanged: (v) async {
                      await settings.updateField(
                          (s) => s.copyWith(
                              pushItineraryReminders: v,
                              pushAiSuggestions: v,
                              pushTravelAlerts: v),
                          analyticsEvent: SettingsAnalyticsEvents.pushToggled,
                          analyticsParams: {'enabled': v});
                      if (mounted) _showSuccess('Push notifications ${v ? 'enabled' : 'disabled'}');
                    },
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                  _SettingsToggleRow(
                    icon: Icons.email_outlined,
                    label: 'Email Updates',
                    subtitle: 'Recommendations & product updates',
                    value: settings.settings.emailRecommendations ||
                        settings.settings.emailProductUpdates,
                    onChanged: (v) async {
                      await settings.updateField(
                          (s) => s.copyWith(
                              emailRecommendations: v,
                              emailProductUpdates: v),
                          analyticsEvent: SettingsAnalyticsEvents.emailToggled,
                          analyticsParams: {'enabled': v});
                      if (mounted) _showSuccess('Email updates ${v ? 'enabled' : 'disabled'}');
                    },
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                ],
              ),
            ),

            // ── App Settings ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Section(
                title: 'APP SETTINGS',
                cardColor: cardColor,
                onVariant: onVariant,
                children: [
                  _SettingsRow(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    trailing: _ValueBadge(
                        _capitalize(settings.settings.darkMode), onVariant),
                    onTap: () async {
                      await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => DarkModeModal(
                              current: settings.settings.darkMode));
                      if (mounted) _showSuccess('Appearance updated');
                    },
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                  _SettingsRow(
                    icon: Icons.language_rounded,
                    label: 'Language',
                    trailing: _ValueBadge(
                        settings.settings.language == 'he'
                            ? 'עברית'
                            : 'English',
                        onVariant),
                    onTap: () async {
                      await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => LanguageModal(
                              current: settings.settings.language));
                      if (mounted) _showSuccess('Language updated');
                    },
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                ],
              ),
            ),

            // ── Support & About ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Section(
                title: 'SUPPORT & ABOUT',
                cardColor: cardColor,
                onVariant: onVariant,
                children: [
                  _SettingsRow(
                    icon: Icons.help_outline_rounded,
                    label: 'Help Center',
                    onTap: () {},
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                  _SettingsRow(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () {},
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                  _SettingsRow(
                    icon: Icons.shield_outlined,
                    label: 'Privacy Policy',
                    onTap: () {},
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Version',
                    trailing: Text('2.4.0 (349)',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: onVariant)),
                    showChevron: false,
                    onTap: null,
                    onSurface: onSurface,
                    onVariant: onVariant,
                  ),
                ],
              ),
            ),

            // ── Logout Button ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text('Log Out',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                      side: const BorderSide(
                          color: Color(0xFFD32F2F), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    onPressed: _handleLogout,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ══════════════════════════════════════════════════════════════════════════════
// Header
// ══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final bool isDark;
  final Color onSurface;
  final User? user;
  final Color cardColor;
  final Color onVariant;

  const _Header({
    required this.isDark,
    required this.onSurface,
    required this.user,
    required this.cardColor,
    required this.onVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? TripiColors.darkSurfaceContainerLowest
                  : TripiColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F2D3335),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.settings_outlined,
                size: 18, color: onVariant),
          ),
          const SizedBox(width: 12),
          Text('Settings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: onSurface,
                letterSpacing: -0.5,
              )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Profile Card
// ══════════════════════════════════════════════════════════════════════════════

class _ProfileCard extends StatelessWidget {
  final User? user;
  final Color cardColor;
  final Color onSurface;
  final Color onVariant;
  final SettingsProvider settings;

  const _ProfileCard({
    required this.user,
    required this.cardColor,
    required this.onSurface,
    required this.onVariant,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final name = user?.userMetadata?['full_name']?.toString() ??
        user?.userMetadata?['name']?.toString() ??
        'Traveler';
    final email = user?.email ?? '';
    final avatarUrl = user?.userMetadata?['avatar_url']?.toString();

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const EditProfileScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F2D3335),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF0060AD).withValues(alpha: 0.1),
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'T',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0060AD),
                          ),
                        )
                      : null,
                ),
                if (settings.isLoadingAvatar)
                  const Positioned.fill(
                    child: CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: onSurface)),
                  const SizedBox(height: 2),
                  Text(email,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: onVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: onVariant),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Section wrapper
// ══════════════════════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color cardColor;
  final Color onVariant;

  const _Section({
    required this.title,
    required this.children,
    required this.cardColor,
    required this.onVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: onVariant,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A2D3335),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                          height: 1,
                          color: onVariant.withValues(alpha: 0.08)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Row types
// ══════════════════════════════════════════════════════════════════════════════

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color onSurface;
  final Color onVariant;
  final bool showChevron;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onSurface,
    required this.onVariant,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 20, color: onVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: onSurface)),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 6),
              ],
              if (showChevron && onTap != null)
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: onVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color onSurface;
  final Color onVariant;

  const _SettingsToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onSurface,
    required this.onVariant,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: onVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: onSurface)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: onVariant)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ValueBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _ValueBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(fontSize: 13, color: color));
  }
}
