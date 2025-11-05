import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_circle/models/study_group_model.dart';
import 'package:study_circle/models/study_session_model.dart';
import 'package:study_circle/models/join_request_model.dart';
import 'package:study_circle/models/resource_model.dart';
import 'package:study_circle/providers/auth_provider.dart' as app_auth;
import 'package:study_circle/services/firestore_service.dart';
import 'package:study_circle/screens/groups/join_requests_screen.dart';
import 'package:study_circle/screens/qna/qna_list_screen.dart';
import 'package:study_circle/theme/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:study_circle/config/cloudinary_config.dart';
import 'package:study_circle/utils/logger.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  bool _isLoading = false;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();
    final currentUser = authProvider.userModel;

    return StreamBuilder<StudyGroupModel?>(
      stream: _firestoreService.getStudyGroupStream(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: _buildErrorState('Error loading group: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final group = snapshot.data;

        if (group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: _buildErrorState('Group not found'),
          );
        }

        final isMember = currentUser != null && group.isMember(currentUser.uid);
        final isCreator =
            currentUser != null && group.isCreator(currentUser.uid);

        return Scaffold(
          appBar: _buildAppBar(group, isCreator),
          body: Column(
            children: [
              _buildHeader(group, currentUser?.uid),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAboutTab(group),
                    _buildMembersTab(group),
                    _buildSessionsTab(group),
                    _buildResourcesTab(group),
                    _buildQnaTab(group),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton:
              isMember &&
                  (_tabController.index == 2 || _tabController.index == 3 || _tabController.index == 4)
              ? FloatingActionButton.extended(
                  onPressed: () {
                    if (_tabController.index == 2) {
                      Navigator.pushNamed(
                        context,
                        '/create-session',
                        arguments: {'group': group, 'session': null},
                      );
                    } else if (_tabController.index == 3) {
                      _showUploadResourceDialog(group, currentUser);
                    } else if (_tabController.index == 4) {
                      Navigator.pushNamed(
                        context,
                        '/ask-question',
                        arguments: group,
                      );
                    }
                  },
                  backgroundColor: AppColors.primary,
                  icon: Icon(
                    _tabController.index == 2 ? Icons.add : 
                    _tabController.index == 3 ? Icons.upload_file : Icons.question_answer,
                  ),
                  label: Text(
                    _tabController.index == 2 ? 'New Session' : 
                    _tabController.index == 3 ? 'Upload File' : 'Ask Question',
                  ),
                )
              : null,
          bottomNavigationBar: _buildBottomBar(
            group,
            isMember,
            isCreator,
            currentUser?.uid,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(StudyGroupModel group, bool isCreator) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? AppColors.gradientDark : AppColors.gradientLight,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text(
        'Group Details',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          color: Colors.white,
        ),
      ),
      actions: [
        if (isCreator)
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            tooltip: 'View Analytics',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/group-analytics',
                arguments: group,
              );
            },
          ),
        if (isCreator && !group.isPublic)
          StreamBuilder<List<JoinRequestModel>>(
            stream: _firestoreService.getGroupJoinRequests(group.id),
            builder: (context, snapshot) {
              final pendingCount = snapshot.data?.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JoinRequestsScreen(
                            groupId: group.id,
                            groupName: group.name,
                          ),
                        ),
                      );
                    },
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (isCreator)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/edit-group', arguments: group);
            },
          ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            if (isCreator)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
          onSelected: (value) {
            if (value == 'share') {
              _shareGroup(group);
            } else if (value == 'delete') {
              _deleteGroup(group);
            }
          },
        ),
      ],
    );
  }

  Widget _buildHeader(StudyGroupModel group, String? currentUserId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? AppColors.gradientDark : AppColors.gradientLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.groups_rounded, size: 36, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        group.courseCode,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatBadge(
                Icons.people_rounded,
                '${group.memberIds.length}/${group.maxMembers}',
                'Members',
              ),
              const SizedBox(width: 12),
              _buildStatBadge(
                group.isPublic ? Icons.public_rounded : Icons.lock_rounded,
                group.isPublic ? 'Public' : 'Private',
                'Visibility',
              ),
              const SizedBox(width: 12),
              StreamBuilder<List<StudySessionModel>>(
                stream: _firestoreService.getGroupSessions(group.id),
                builder: (context, snapshot) {
                  final sessionCount = snapshot.data?.length ?? 0;
                  return _buildStatBadge(
                    Icons.event_rounded,
                    sessionCount.toString(),
                    'Sessions',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primaryLight.withValues(alpha: 0.1),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: AppColors.primary,
              width: 3,
            ),
          ),
        ),
        tabs: const [
          Tab(text: 'About'),
          Tab(text: 'Members'),
          Tab(text: 'Sessions'),
          Tab(text: 'Resources'),
          Tab(text: 'Q&A'),
        ],
      ),
    );
  }

  Widget _buildAboutTab(StudyGroupModel group) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Description',
            group.description.isNotEmpty
                ? group.description
                : 'No description provided',
          ),
          const SizedBox(height: 20),
          _buildSection('Course', group.courseName),
          const SizedBox(height: 20),
          _buildSection('Schedule', group.schedule),
          const SizedBox(height: 20),
          _buildSection('Location', group.location),
          const SizedBox(height: 20),
          if (group.topics.isNotEmpty) ...[
            const Text(
              'Topics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.topics.map((topic) {
                return Chip(
                  label: Text(topic),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: AppColors.primary),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          _buildSection(
            'Created by',
            group.creatorName,
            subtitle: 'Created ${_formatDate(group.createdAt)}',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(fontSize: 14, color: AppColors.gray700)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
        ],
      ],
    );
  }

  Widget _buildMembersTab(StudyGroupModel group) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: group.memberIds.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final memberId = group.memberIds[index];
        final isCreator = memberId == group.creatorId;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCreator
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : (isDark ? AppColors.gray700 : AppColors.gray200).withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCreator
                      ? [AppColors.primary, AppColors.primaryLight]
                      : [
                          AppColors.accent.withValues(alpha: 0.8),
                          AppColors.accent.withValues(alpha: 0.6),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isCreator ? AppColors.primary : AppColors.accent)
                        .withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            title: Text(
              isCreator ? group.creatorName : 'Member ${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.gray900,
              ),
            ),
            trailing: isCreator
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Creator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildSessionsTab(StudyGroupModel group) {
    return StreamBuilder<List<StudySessionModel>>(
      stream: _firestoreService.getGroupSessions(group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data ?? [];
        final now = DateTime.now();
        final upcomingSessions = sessions
            .where((s) => s.dateTime.isAfter(now))
            .length;
        final pastSessions = sessions
            .where((s) => s.dateTime.isBefore(now))
            .length;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month, size: 80, color: AppColors.primary),
                const SizedBox(height: 20),
                Text(
                  'Study Sessions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray800,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                if (sessions.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSessionCount(
                        upcomingSessions,
                        'Upcoming',
                        AppColors.primary,
                      ),
                      const SizedBox(width: 20),
                      _buildSessionCount(
                        pastSessions,
                        'Past',
                        AppColors.gray500,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  Text(
                    'No sessions scheduled yet',
                    style: TextStyle(fontSize: 14, color: AppColors.gray600),
                  ),
                  const SizedBox(height: 24),
                ],
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/sessions-list',
                      arguments: group,
                    );
                  },
                  icon: const Icon(Icons.event_note),
                  label: const Text('View All Sessions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionCount(int count, String label, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.gray600)),
      ],
    );
  }

  Widget? _buildBottomBar(
    StudyGroupModel group,
    bool isMember,
    bool isCreator,
    String? currentUserId,
  ) {
    if (currentUserId == null) return null;
    if (isCreator) return null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isMember && !group.isPublic) {
      return StreamBuilder<bool>(
        stream: _firestoreService.hasPendingJoinRequestStream(
          group.id,
          currentUserId,
        ),
        builder: (context, snapshot) {
          final hasPendingRequest = snapshot.data ?? false;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: hasPendingRequest
                          ? [AppColors.warning, AppColors.warning.withValues(alpha: 0.8)]
                          : [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (hasPendingRequest ? AppColors.warning : AppColors.primary)
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading || hasPendingRequest
                        ? null
                        : () => _joinGroup(group),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasPendingRequest ? Icons.schedule_rounded : Icons.send_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hasPendingRequest
                                    ? 'Request Pending'
                                    : 'Request to Join',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isMember
                    ? [AppColors.error, AppColors.error.withValues(alpha: 0.8)]
                    : [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (isMember ? AppColors.error : AppColors.primary)
                      .withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (isMember) {
                        _leaveGroup(group);
                      } else {
                        _joinGroup(group);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isMember ? Icons.exit_to_app_rounded : Icons.login_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isMember ? 'Leave Group' : 'Join Group',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
            ),
          ),
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
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error',
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

  Future<void> _joinGroup(StudyGroupModel group) async {
    final authProvider = context.read<app_auth.AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) return;

    if (group.isFull) {
      _showErrorSnackBar('This group is full');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (group.isPublic) {
        await _firestoreService.joinGroup(group.id, currentUser.uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully joined the group!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final hasPending = await _firestoreService.hasPendingJoinRequest(
          group.id,
          currentUser.uid,
        );

        if (hasPending) {
          _showErrorSnackBar(
            'You already have a pending request for this group',
          );
          return;
        }

        final request = JoinRequestModel(
          id: '',
          groupId: group.id,
          userId: currentUser.uid,
          userName: currentUser.name,
          userEmail: currentUser.email,
          userProfileImageUrl: currentUser.profileImageUrl,
          status: 'pending',
          createdAt: DateTime.now(),
        );

        await _firestoreService.createJoinRequest(request);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Join request sent! Waiting for approval.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('$e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _leaveGroup(StudyGroupModel group) async {
    final authProvider = context.read<app_auth.AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) return;

    final confirmed = await _showConfirmDialog(
      'Leave Group',
      'Are you sure you want to leave this group?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await _firestoreService.leaveGroup(group.id, currentUser.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the group')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('$e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _shareGroup(StudyGroupModel group) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  Future<void> _deleteGroup(StudyGroupModel group) async {
    final confirmed = await _showConfirmDialog(
      'Delete Group',
      'Are you sure you want to delete this group? This action cannot be undone.',
    );

    if (!confirmed) return;

    try {
      await _firestoreService.deleteStudyGroup(group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete group: $e');
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  Widget _buildResourcesTab(StudyGroupModel group) {
    return StreamBuilder<List<ResourceModel>>(
      stream: _firestoreService.getGroupResources(group.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final resources = snapshot.data ?? [];

        if (resources.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: AppColors.gray400),
                  const SizedBox(height: 20),
                  Text(
                    'No Resources Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Share study materials, notes, and documents with your group members',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.gray600),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: resources.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final resource = resources[index];
            return _buildResourceCard(resource, group);
          },
        );
      },
    );
  }

  Widget _buildResourceCard(ResourceModel resource, StudyGroupModel group) {
    final authProvider = context.read<app_auth.AuthProvider>();
    final currentUser = authProvider.userModel;
    final isUploader =
        currentUser != null && resource.uploadedBy == currentUser.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData fileIcon;
    Color fileColor;

    switch (resource.fileType) {
      case 'pdf':
        fileIcon = Icons.picture_as_pdf_rounded;
        fileColor = Colors.red;
        break;
      case 'image':
        fileIcon = Icons.image_rounded;
        fileColor = Colors.blue;
        break;
      case 'video':
        fileIcon = Icons.video_file_rounded;
        fileColor = Colors.purple;
        break;
      default:
        fileIcon = Icons.insert_drive_file_rounded;
        fileColor = AppColors.gray600;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.gray700 : AppColors.gray200).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _downloadResource(resource),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            fileColor.withValues(alpha: 0.8),
                            fileColor.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: fileColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(fileIcon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: isDark ? Colors.white : AppColors.gray900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: fileColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: fileColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              resource.fileName,
                              style: TextStyle(
                                fontSize: 11,
                                color: fileColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUploader)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _confirmDeleteResource(resource),
                        ),
                      ),
                  ],
                ),
                if (resource.description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    resource.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.gray400 : AppColors.gray700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        (isDark ? AppColors.gray700 : AppColors.gray300).withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 15, color: AppColors.gray500),
                    const SizedBox(width: 5),
                    Text(
                      resource.uploaderName,
                      style: TextStyle(fontSize: 12, color: AppColors.gray600, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.access_time_rounded, size: 15, color: AppColors.gray500),
                    const SizedBox(width: 5),
                    Text(
                      _formatDate(resource.uploadedAt),
                      style: TextStyle(fontSize: 12, color: AppColors.gray600, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            fileColor.withValues(alpha: 0.15),
                            fileColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: fileColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        resource.formattedFileSize,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: fileColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (resource.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: resource.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.12),
                              AppColors.primaryLight.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showUploadResourceDialog(
    StudyGroupModel group,
    dynamic currentUser,
  ) async {
    if (currentUser == null) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final tagsController = TextEditingController();
    File? selectedFile;
    String? fileName;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Upload Resource'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedFile == null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: [
                            'pdf',
                            'doc',
                            'docx',
                            'ppt',
                            'pptx',
                            'jpg',
                            'jpeg',
                            'png',
                            'txt',
                            'zip',
                          ],
                        );

                        if (result != null) {
                          setState(() {
                            selectedFile = File(result.files.single.path!);
                            fileName = result.files.single.name;
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Select File'),
                    )
                  else
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(fileName ?? 'Unknown file'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              selectedFile = null;
                              fileName = null;
                            });
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., Chapter 3 Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Brief description of the resource',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (optional)',
                      hintText: 'exam, notes, lecture (comma separated)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    selectedFile == null || titleController.text.trim().isEmpty
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        await _uploadResource(
                          group,
                          currentUser,
                          selectedFile!,
                          fileName!,
                          titleController.text.trim(),
                          descriptionController.text.trim(),
                          tagsController.text.trim(),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Upload'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _uploadResource(
    StudyGroupModel group,
    dynamic currentUser,
    File file,
    String fileName,
    String title,
    String description,
    String tagsString,
  ) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Uploading file...'),
              ],
            ),
            duration: const Duration(minutes: 5),
          ),
        );
      }

      final fileUrl = await CloudinaryConfig.uploadFile(file);

      if (fileUrl == null) {
        throw 'Failed to upload file to cloud storage';
      }

      final extension = fileName.split('.').last.toLowerCase();
      String fileType;
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        fileType = 'image';
      } else if (extension == 'pdf') {
        fileType = 'pdf';
      } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
        fileType = 'video';
      } else {
        fileType = 'other';
      }

      final tags = tagsString.isEmpty
          ? <String>[]
          : tagsString
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();

      final resource = ResourceModel(
        id: '',
        groupId: group.id,
        uploadedBy: currentUser.uid,
        uploaderName: currentUser.name,
        title: title,
        description: description,
        fileUrl: fileUrl,
        fileType: fileType,
        fileName: fileName,
        fileSizeBytes: await file.length(),
        uploadedAt: DateTime.now(),
        tags: tags,
      );

      await _firestoreService.uploadResource(resource);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to upload resource', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        _showErrorSnackBar('Failed to upload resource: $e');
      }
    }
  }

  Future<void> _downloadResource(ResourceModel resource) async {
    try {
      final url = Uri.parse(resource.fileUrl);

      final launched = await launchUrl(url, mode: LaunchMode.platformDefault);

      if (!launched) {
        final launchedExternal = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );

        if (!launchedExternal) {
          throw 'Could not open file. Please check if you have a PDF viewer installed.';
        }
      }
    } catch (e) {
      AppLogger.error('Failed to download resource', e, StackTrace.current);
      if (mounted) {
        _showErrorSnackBar('Failed to open file: $e');
      }
    }
  }

  Future<void> _confirmDeleteResource(ResourceModel resource) async {
    final confirmed = await _showConfirmDialog(
      'Delete Resource',
      'Are you sure you want to delete "${resource.title}"? This action cannot be undone.',
    );

    if (!confirmed) return;

    try {
      await _firestoreService.deleteResource(resource.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to delete resource', e, StackTrace.current);
      if (mounted) {
        _showErrorSnackBar('Failed to delete resource: $e');
      }
    }
  }

  Widget _buildQnaTab(StudyGroupModel group) {
    return QnaListScreen(group: group);
  }
}
