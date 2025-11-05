import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_circle/models/study_group_model.dart';
import 'package:study_circle/models/study_session_model.dart';
import 'package:study_circle/models/join_request_model.dart';
import 'package:study_circle/providers/auth_provider.dart' as app_auth;
import 'package:study_circle/services/firestore_service.dart';
import 'package:study_circle/screens/groups/join_requests_screen.dart';
import 'package:study_circle/theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to update FAB visibility
      }
    });
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
        final isCreator = currentUser != null && group.isCreator(currentUser.uid);

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
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: isMember && _tabController.index == 2
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/create-session',
                      arguments: {
                        'group': group,
                        'session': null,
                      },
                    );
                  },
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add),
                  label: const Text('New Session'),
                )
              : null,
          bottomNavigationBar: _buildBottomBar(group, isMember, isCreator, currentUser?.uid),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(StudyGroupModel group, bool isCreator) {
    return AppBar(
      title: const Text(
        'Group Details',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      actions: [
        if (isCreator && !group.isPublic)
          StreamBuilder<List<JoinRequestModel>>(
            stream: _firestoreService.getGroupJoinRequests(group.id),
            builder: (context, snapshot) {
              final pendingCount = snapshot.data?.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add),
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
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit-group',
                arguments: group,
              );
            },
          ),
        PopupMenuButton(
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.groups,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.courseCode,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBadge(
                Icons.people,
                '${group.memberIds.length}/${group.maxMembers}',
                'Members',
              ),
              const SizedBox(width: 12),
              _buildStatBadge(
                Icons.visibility,
                group.isPublic ? 'Public' : 'Private',
                'Visibility',
              ),
              const SizedBox(width: 12),
              StreamBuilder<List<StudySessionModel>>(
                stream: _firestoreService.getGroupSessions(group.id),
                builder: (context, snapshot) {
                  final sessionCount = snapshot.data?.length ?? 0;
                  return _buildStatBadge(
                    Icons.event,
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'About'),
        Tab(text: 'Members'),
        Tab(text: 'Sessions'),
      ],
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
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.gray700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMembersTab(StudyGroupModel group) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: group.memberIds.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final memberId = group.memberIds[index];
        final isCreator = memberId == group.creatorId;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            isCreator ? group.creatorName : 'Member ${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: isCreator
              ? Chip(
                  label: const Text('Creator'),
                  backgroundColor: AppColors.primary,
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  padding: EdgeInsets.zero,
                )
              : null,
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
        final upcomingSessions = sessions.where((s) => s.dateTime.isAfter(now)).length;
        final pastSessions = sessions.where((s) => s.dateTime.isBefore(now)).length;

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
                      _buildSessionCount(upcomingSessions, 'Upcoming', AppColors.primary),
                      const SizedBox(width: 20),
                      _buildSessionCount(pastSessions, 'Past', AppColors.gray500),
                    ],
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  Text(
                    'No sessions scheduled yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.gray600,
          ),
        ),
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
    if (isCreator) return null; // Creators don't need to join/leave

    // For non-members of private groups, check if they have a pending request
    if (!isMember && !group.isPublic) {
      return StreamBuilder<bool>(
        stream: _firestoreService.hasPendingJoinRequestStream(group.id, currentUserId),
        builder: (context, snapshot) {
          final hasPendingRequest = snapshot.data ?? false;
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || hasPendingRequest
                      ? null
                      : () => _joinGroup(group),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPendingRequest ? AppColors.warning : AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.warning.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                            if (hasPendingRequest)
                              const Icon(Icons.schedule, size: 20),
                            if (hasPendingRequest)
                              const SizedBox(width: 8),
                            Text(
                              hasPendingRequest ? 'Request Pending' : 'Request to Join',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      );
    }

    // For public groups and members, show regular join/leave button
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
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
              backgroundColor: isMember ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                : Text(
                    isMember ? 'Leave Group' : 'Join Group',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray600,
              ),
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
        // Public group: instant join
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
        // Private group: send join request
        // Check if user already has a pending request
        final hasPending = await _firestoreService.hasPendingJoinRequest(
          group.id,
          currentUser.uid,
        );
        
        if (hasPending) {
          _showErrorSnackBar('You already have a pending request for this group');
          return;
        }
        
        // Create join request
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
          const SnackBar(
            content: Text('You have left the group'),
          ),
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
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
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
}
