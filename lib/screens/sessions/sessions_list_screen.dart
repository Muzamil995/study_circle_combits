import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_circle/models/study_session_model.dart';
import 'package:study_circle/models/study_group_model.dart';
import 'package:study_circle/models/rsvp_model.dart';
import 'package:study_circle/providers/auth_provider.dart' as app_auth;
import 'package:study_circle/services/firestore_service.dart';
import 'package:study_circle/screens/sessions/create_session_screen.dart';
import 'package:study_circle/theme/app_colors.dart';
import 'package:intl/intl.dart';

class SessionsListScreen extends StatefulWidget {
  final StudyGroupModel group;

  const SessionsListScreen({super.key, required this.group});

  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();
    final currentUser = authProvider.userModel;
    final isGroupMember =
        currentUser != null && widget.group.memberIds.contains(currentUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Study Sessions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildGroupInfo(),
          Expanded(
            child: StreamBuilder<List<StudySessionModel>>(
              stream: _firestoreService.getGroupSessions(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(
                    'Error loading sessions: ${snapshot.error}',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data ?? [];

                if (sessions.isEmpty) {
                  return _buildEmptyState();
                }

                final now = DateTime.now();
                final upcomingSessions = sessions
                    .where((s) => s.dateTime.isAfter(now))
                    .toList();
                final pastSessions = sessions
                    .where((s) => s.dateTime.isBefore(now))
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (upcomingSessions.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Upcoming Sessions',
                        upcomingSessions.length,
                      ),
                      const SizedBox(height: 12),
                      ...upcomingSessions.map(
                        (session) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SessionCard(
                            session: session,
                            group: widget.group,
                            currentUserId: currentUser?.uid,
                          ),
                        ),
                      ),
                    ],
                    if (pastSessions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSectionHeader('Past Sessions', pastSessions.length),
                      const SizedBox(height: 12),
                      ...pastSessions.map(
                        (session) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SessionCard(
                            session: session,
                            group: widget.group,
                            currentUserId: currentUser?.uid,
                            isPast: true,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isGroupMember
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCreateSession(),
              backgroundColor: AppColors.primary,
              elevation: 6,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Session',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildGroupInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primaryLight.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.group, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: isDark ? Colors.white : AppColors.gray800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.group.courseCode,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            title.contains('Upcoming') ? Icons.event : Icons.history,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.gray800,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              'No Sessions Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gray700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule your first study session to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.gray600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gray700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.gray600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCreateSession() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSessionScreen(group: widget.group),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _SessionCard extends StatelessWidget {
  final StudySessionModel session;
  final StudyGroupModel group;
  final String? currentUserId;
  final bool isPast;

  const _SessionCard({
    required this.session,
    required this.group,
    this.currentUserId,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final userRsvpStatus = currentUserId != null
        ? session.getUserRsvpStatus(currentUserId!)
        : null;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPast 
              ? AppColors.gray300 
              : AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isPast
                ? [
                    AppColors.gray100.withValues(alpha: 0.5),
                    AppColors.gray50.withValues(alpha: 0.3),
                  ]
                : [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.primaryLight.withValues(alpha: 0.02),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isPast
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/session-details',
              arguments: {'session': session, 'group': group},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPast
                              ? [AppColors.gray400, AppColors.gray500]
                              : [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isPast ? AppColors.gray400 : AppColors.primary)
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPast ? Icons.history : Icons.event_note,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: isPast
                                  ? AppColors.gray600
                                  : (isDark ? Colors.white : AppColors.gray800),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPast
                                    ? [
                                        AppColors.gray400.withValues(alpha: 0.3),
                                        AppColors.gray500.withValues(alpha: 0.2),
                                      ]
                                    : [AppColors.primary, AppColors.primaryLight],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              session.topic,
                              style: TextStyle(
                                fontSize: 13,
                                color: isPast ? AppColors.gray600 : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (userRsvpStatus != null) _buildRsvpBadge(userRsvpStatus),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gray300.withValues(alpha: 0.3),
                        AppColors.gray400.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.calendar_today,
                  dateFormat.format(session.dateTime),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  '${timeFormat.format(session.dateTime)} • ${session.durationMinutes} min',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, session.location),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gray300.withValues(alpha: 0.3),
                        AppColors.gray400.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRsvpSummary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRsvpBadge(RsvpStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case RsvpStatus.attending:
        color = AppColors.success;
        label = 'Attending';
        icon = Icons.check_circle;
        break;
      case RsvpStatus.maybe:
        color = AppColors.warning;
        label = 'Maybe';
        icon = Icons.help;
        break;
      case RsvpStatus.notAttending:
        color = AppColors.error;
        label = 'Not Attending';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isPast ? AppColors.gray500 : AppColors.gray700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRsvpSummary() {
    return Row(
      children: [
        _buildRsvpCount(
          Icons.check_circle,
          session.attendingCount,
          AppColors.success,
        ),
        const SizedBox(width: 12),
        _buildRsvpCount(Icons.help, session.maybeCount, AppColors.warning),
        const SizedBox(width: 12),
        _buildRsvpCount(
          Icons.cancel,
          session.notAttendingCount,
          AppColors.error,
        ),
      ],
    );
  }

  Widget _buildRsvpCount(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
