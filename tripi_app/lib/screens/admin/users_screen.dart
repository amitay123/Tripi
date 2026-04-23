import 'package:flutter/material.dart';
import '../../theme/tripi_colors.dart';
import '../../widgets/tripi_card.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeamOverview(context),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add New Account'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSearchBar(context),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildFilterButton(Icons.tune, 'Filter')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFilterButton(Icons.sort, 'Sort')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildUserItem(context, 'Alex Johnson', 'alex@example.com',
                      'ADMINISTRATOR', true),
                  _buildUserItem(context, 'Marcus Chen', 'marcus.c@example.com',
                      'TRAVELER', false),
                  _buildUserItem(context, 'Sarah Miller', 'sarah.m@example.com',
                      'PLANNER', true),
                  _buildUserItem(context, 'David Wright',
                      'd.wright@example.com', 'TRAVELER', true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F2F5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.menu, color: TripiColors.primary),
          Text(
            'Account Manager',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: TripiColors.primary,
                ),
          ),
          const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=admin'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamOverview(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TripiColors.primary, TripiColors.primary.withBlue(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Overview',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You have 24 active team members this month with a 98% security compliance rate.',
            style:
                TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleStat('24', 'TOTAL USERS'),
              _buildSimpleStat('03', 'PENDING'),
              _buildSimpleStat('12', 'ONLINE NOW'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 9,
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by name, email or role...',
        prefixIcon:
            const Icon(Icons.search, color: TripiColors.onSurfaceVariant),
        filled: true,
        fillColor: TripiColors.surfaceContainerHigh.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: TripiColors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildUserItem(BuildContext context, String name, String email,
      String role, bool isOnline) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TripiCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          NetworkImage('https://i.pravatar.cc/150?u=$name'),
                    ),
                    if (isOnline)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(email,
                          style: const TextStyle(
                              color: TripiColors.onSurfaceVariant,
                              fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert,
                    color: TripiColors.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: TripiColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                        color: TripiColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Text('Profile',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  label: const Icon(Icons.arrow_forward, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
