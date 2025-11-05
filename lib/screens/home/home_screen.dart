import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_circle/models/user_model.dart';
import 'package:study_circle/models/study_session_model.dart';
import 'package:study_circle/models/study_group_model.dart';
import 'package:study_circle/providers/auth_provider.dart' as app_auth;
import 'package:study_circle/providers/theme_provider.dart';
import 'package:study_circle/services/firestore_service.dart';
import 'package:study_circle/theme/app_colors.dart';
import 'package:study_circle/screens/groups/groups_list_screen.dart';
import 'package:study_circle/screens/sessions/my_sessions_screen.dart';
import 'package:study_circle/screens/profile/profile_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: _buildAppBar(context, user),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardTab(user: user, onChangeTab: _changeTab),
          GroupsListScreen(),
          MySessionsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navigate to create group screen
                Navigator.pushNamed(context, '/create-group');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Group'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, UserModel user) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'StudyCircle',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            'Hello, ${user.name.split(' ').first}!',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.emoji_events),
          tooltip: 'Achievements',
          onPressed: () {
            Navigator.pushNamed(context, '/achievements');
          },
        ),
        IconButton(
          icon: const Icon(Icons.calendar_month),
          tooltip: 'Calendar',
          onPressed: () {
            Navigator.pushNamed(context, '/calendar');
          },
        ),
        IconButton(
          icon: Icon(
            context.watch<ThemeProvider>().isDarkMode
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: () {
            context.read<ThemeProvider>().toggleTheme();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: 'Groups',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event),
          label: 'Sessions',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

// Dashboard Tab
class _DashboardTab extends StatelessWidget {
  final UserModel user;
  final Function(int) onChangeTab;

  const _DashboardTab({required this.user, required this.onChangeTab});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh user data
        await context.read<app_auth.AuthProvider>().reloadUserData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCards(),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildUpcomingSessions(),
            const SizedBox(height: 24),
            _buildRecentGroups(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final firestoreService = FirestoreService();

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.groups,
            title: 'Groups Joined',
            value: user.joinedGroupIds.length.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<List<StudySessionModel>>(
            stream: firestoreService.getUpcomingSessions(user.joinedGroupIds),
            builder: (context, snapshot) {
              final sessionCount = snapshot.data?.length ?? 0;
              return _StatCard(
                icon: Icons.event_available,
                title: 'Upcoming Sessions',
                value: sessionCount.toString(),
                color: AppColors.success,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_circle,
                label: 'Create Group',
                onTap: () => Navigator.pushNamed(context, '/create-group'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.search,
                label: 'Find Groups',
                onTap: () {
                  // Switch to groups tab
                  onChangeTab(1);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingSessions() {
    final firestoreService = FirestoreService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Sessions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            TextButton(
              onPressed: () {
                onChangeTab(2); // Navigate to sessions tab
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<StudySessionModel>>(
          stream: firestoreService.getUpcomingSessions(user.joinedGroupIds),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildEmptyState(
                icon: Icons.error_outline,
                message: 'Error loading sessions',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final sessions = snapshot.data ?? [];

            if (sessions.isEmpty) {
              return _buildEmptyState(
                icon: Icons.event_busy,
                message: 'No upcoming sessions',
              );
            }

            // Show first 3 sessions
            final displaySessions = sessions.take(3).toList();

            return Column(
              children: displaySessions.map((session) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SessionPreviewCard(session: session),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Groups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            TextButton(
              onPressed: () {
                onChangeTab(1); // Navigate to groups tab
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        user.joinedGroupIds.isEmpty
            ? _buildEmptyState(
                icon: Icons.group_off,
                message: 'Join your first study group!',
              )
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.groups, color: AppColors.primary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You are in ${user.joinedGroupIds.length} group${user.joinedGroupIds.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.gray400),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: AppColors.gray600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: AppColors.gray600)),
        ],
      ),
    );
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// Session Preview Card Widget
class _SessionPreviewCard extends StatelessWidget {
  final StudySessionModel session;

  const _SessionPreviewCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd');
    final timeFormat = DateFormat('h:mm a');
    final firestoreService = FirestoreService();

    return StreamBuilder<StudyGroupModel?>(
      stream: firestoreService.getStudyGroupStream(session.groupId),
      builder: (context, groupSnapshot) {
        final group = groupSnapshot.data;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
          ),
          child: InkWell(
            onTap: group != null
                ? () {
                    // Navigate to session details
                    Navigator.pushNamed(
                      context,
                      '/session-details',
                      arguments: {'session': session, 'group': group},
                    );
                  }
                : null,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.event, color: AppColors.info, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dateFormat.format(session.dateTime)} at ${timeFormat.format(session.dateTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray600,
                        ),
                      ),
                      if (group != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          group.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.gray400, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
