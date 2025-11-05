import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_circle/models/user_model.dart';
import 'package:study_circle/models/study_group_model.dart';
import 'package:study_circle/models/study_session_model.dart';
import 'package:study_circle/models/join_request_model.dart';
import 'package:study_circle/models/resource_model.dart';
import 'package:study_circle/models/rsvp_model.dart';
import 'package:study_circle/models/achievement_model.dart';
import 'package:study_circle/models/user_stats_model.dart';
import 'package:study_circle/models/group_analytics_model.dart';
import 'package:study_circle/models/question_model.dart';
import 'package:study_circle/models/answer_model.dart';
import 'package:study_circle/services/gamification_service.dart';
import 'package:study_circle/utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _groupsCollection => _firestore.collection('study_groups');
  CollectionReference get _sessionsCollection => _firestore.collection('study_sessions');
  CollectionReference get _requestsCollection => _firestore.collection('join_requests');
  CollectionReference get _resourcesCollection => _firestore.collection('resources');
  CollectionReference get _achievementsCollection => _firestore.collection('achievements');
  CollectionReference get _userStatsCollection => _firestore.collection('user_stats');
  CollectionReference get _groupAnalyticsCollection => _firestore.collection('group_analytics');
  CollectionReference get _questionsCollection => _firestore.collection('questions');
  CollectionReference get _answersCollection => _firestore.collection('answers');

  // ==================== USER OPERATIONS ====================

  // Create or update user profile
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      AppLogger.info('Creating/updating user profile: ${user.uid}');
      await _usersCollection.doc(user.uid).set(
            user.toFirestore(),
            SetOptions(merge: true),
          );
      AppLogger.info('User profile saved successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save user profile', e, stackTrace);
      throw 'Failed to save profile. Please try again.';
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user', e, stackTrace);
      throw 'Failed to load user profile.';
    }
  }

  // Get user stream (real-time updates)
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _usersCollection
          .where('nameLower', isGreaterThanOrEqualTo: queryLower)
          .where('nameLower', isLessThan: '${queryLower}z')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search users', e, stackTrace);
      return [];
    }
  }

  // ==================== STUDY GROUP OPERATIONS ====================

  // Create study group
  Future<String> createStudyGroup(StudyGroupModel group) async {
    try {
      AppLogger.info('Creating study group: ${group.name}');
      final docRef = await _groupsCollection.add(group.toFirestore());
      final groupId = docRef.id;
      AppLogger.info('Study group created: $groupId');
      
      // Update user's joinedGroupIds and createdGroupIds
      await _usersCollection.doc(group.creatorId).update({
        'joinedGroupIds': FieldValue.arrayUnion([groupId]),
        'createdGroupIds': FieldValue.arrayUnion([groupId]),
      });
      
      // Track group creation for gamification
      final gamificationService = GamificationService();
      await gamificationService.trackGroupCreated(group.creatorId);
      
      AppLogger.info('User group IDs updated successfully');
      return groupId;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create study group', e, stackTrace);
      throw 'Failed to create group. Please try again.';
    }
  }

  // Update study group
  Future<void> updateStudyGroup(StudyGroupModel group) async {
    try {
      AppLogger.info('Updating study group: ${group.id}');
      await _groupsCollection.doc(group.id).update(group.toFirestore());
      AppLogger.info('Study group updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update study group', e, stackTrace);
      throw 'Failed to update group. Please try again.';
    }
  }

  // Get study group by ID
  Future<StudyGroupModel?> getStudyGroupById(String groupId) async {
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      if (doc.exists) {
        return StudyGroupModel.fromFirestore(doc);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get study group', e, stackTrace);
      throw 'Failed to load group.';
    }
  }

  // Get study group stream
  Stream<StudyGroupModel?> getStudyGroupStream(String groupId) {
    return _groupsCollection.doc(groupId).snapshots().map((doc) {
      if (doc.exists) {
        return StudyGroupModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Get public study groups
  Stream<List<StudyGroupModel>> getPublicGroups() {
    return _groupsCollection
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudyGroupModel.fromFirestore(doc))
            .toList());
  }

  // Get all study groups (both public and private)
  Stream<List<StudyGroupModel>> getAllGroups() {
    return _groupsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudyGroupModel.fromFirestore(doc))
            .toList());
  }

  // Get user's groups
  Stream<List<StudyGroupModel>> getUserGroups(String userId) {
    return _groupsCollection
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudyGroupModel.fromFirestore(doc))
            .toList());
  }

  // Search study groups (searches all groups, both public and private)
  Future<List<StudyGroupModel>> searchStudyGroups(String query) async {
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _groupsCollection.get();

      // Filter by name, course code, or description
      return snapshot.docs
          .map((doc) => StudyGroupModel.fromFirestore(doc))
          .where((group) =>
              group.name.toLowerCase().contains(queryLower) ||
              group.courseCode.toLowerCase().contains(queryLower) ||
              group.courseName.toLowerCase().contains(queryLower) ||
              group.description.toLowerCase().contains(queryLower))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search study groups', e, stackTrace);
      return [];
    }
  }

  // Delete study group
  Future<void> deleteStudyGroup(String groupId) async {
    try {
      AppLogger.info('Deleting study group: $groupId');
      await _groupsCollection.doc(groupId).delete();
      AppLogger.info('Study group deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete study group', e, stackTrace);
      throw 'Failed to delete group. Please try again.';
    }
  }

  // Join a public group (instant join)
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      AppLogger.info('User $userId joining group $groupId');
      
      // Get the group document
      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) {
        throw 'Group not found.';
      }
      
      final group = StudyGroupModel.fromFirestore(groupDoc);
      
      // Check if already a member
      if (group.memberIds.contains(userId)) {
        throw 'You are already a member of this group.';
      }
      
      // Check if group is full
      if (group.isFull) {
        throw 'This group is full.';
      }
      
      // Add user to group members using Firestore arrayUnion
      await _groupsCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });
      
      // Update user's joined groups
      await _usersCollection.doc(userId).update({
        'joinedGroupIds': FieldValue.arrayUnion([groupId]),
      });
      
      // Track group joined for gamification
      final gamificationService = GamificationService();
      await gamificationService.trackGroupJoined(userId);
      
      AppLogger.info('User joined group successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to join group', e, stackTrace);
      if (e is String) rethrow;
      throw 'Failed to join group. Please try again.';
    }
  }

  // Leave a group
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      AppLogger.info('User $userId leaving group $groupId');
      
      // Get the group document
      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) {
        throw 'Group not found.';
      }
      
      final group = StudyGroupModel.fromFirestore(groupDoc);
      
      // Check if user is the creator
      if (group.creatorId == userId) {
        throw 'Group creators cannot leave their own group. Please delete the group instead.';
      }
      
      // Remove user from group members using Firestore arrayRemove
      await _groupsCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
      });
      
      // Update user's joined groups
      await _usersCollection.doc(userId).update({
        'joinedGroupIds': FieldValue.arrayRemove([groupId]),
      });
      
      AppLogger.info('User left group successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to leave group', e, stackTrace);
      if (e is String) rethrow;
      throw 'Failed to leave group. Please try again.';
    }
  }

  // Check if user has a pending join request for a group
  Future<bool> hasPendingJoinRequest(String groupId, String userId) async {
    try {
      final snapshot = await _requestsCollection
          .where('groupId', isEqualTo: groupId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check join request', e, stackTrace);
      return false;
    }
  }

  // Stream version: Check if user has a pending join request for a group (real-time)
  Stream<bool> hasPendingJoinRequestStream(String groupId, String userId) {
    return _requestsCollection
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  // Approve join request
  Future<void> approveJoinRequest(String requestId, String groupId, String userId) async {
    try {
      AppLogger.info('Approving join request: $requestId');
      
      // Get the group to check if it's full
      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) {
        throw 'Group not found.';
      }
      
      final group = StudyGroupModel.fromFirestore(groupDoc);
      
      if (group.isFull) {
        throw 'This group is full.';
      }
      
      // Update request status
      await _requestsCollection.doc(requestId).update({
        'status': 'approved',
        'respondedAt': FieldValue.serverTimestamp(),
      });
      
      // Add user to group
      await _groupsCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });
      
      // Update user's joined groups
      await _usersCollection.doc(userId).update({
        'joinedGroupIds': FieldValue.arrayUnion([groupId]),
      });
      
      // Track group joined for gamification
      final gamificationService = GamificationService();
      await gamificationService.trackGroupJoined(userId);
      
      AppLogger.info('Join request approved successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to approve join request', e, stackTrace);
      if (e is String) rethrow;
      throw 'Failed to approve request. Please try again.';
    }
  }

  // Reject join request
  Future<void> rejectJoinRequest(String requestId) async {
    try {
      AppLogger.info('Rejecting join request: $requestId');
      
      await _requestsCollection.doc(requestId).update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('Join request rejected successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to reject join request', e, stackTrace);
      throw 'Failed to reject request. Please try again.';
    }
  }

  // ==================== STUDY SESSION OPERATIONS ====================

  // Create study session
  Future<String> createStudySession(StudySessionModel session) async {
    try {
      AppLogger.info('Creating study session: ${session.title}');
      final docRef = await _sessionsCollection.add(session.toFirestore());
      AppLogger.info('Study session created with ID: ${docRef.id}');
      AppLogger.debug('Session details - groupId: ${session.groupId}, dateTime: ${session.dateTime}, location: ${session.location}');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create study session', e, stackTrace);
      throw 'Failed to create session. Please try again.';
    }
  }

  // Update study session
  Future<void> updateStudySession(StudySessionModel session) async {
    try {
      AppLogger.info('Updating study session: ${session.id}');
      await _sessionsCollection.doc(session.id).update(session.toFirestore());
      AppLogger.info('Study session updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update study session', e, stackTrace);
      throw 'Failed to update session. Please try again.';
    }
  }

  // Get single session by ID
  Stream<StudySessionModel> getSession(String sessionId) {
    return _sessionsCollection
        .doc(sessionId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            throw Exception('Session not found');
          }
          return StudySessionModel.fromFirestore(doc);
        });
  }

  // Get group sessions
  Stream<List<StudySessionModel>> getGroupSessions(String groupId) {
    AppLogger.debug('getGroupSessions: Querying sessions for group: $groupId');
    
    return _sessionsCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map((doc) => StudySessionModel.fromFirestore(doc))
              .toList();
          AppLogger.debug('getGroupSessions: Found ${sessions.length} sessions for group $groupId');
          return sessions;
        });
  }

  // Get upcoming sessions for user
  Stream<List<StudySessionModel>> getUpcomingSessions(List<String> groupIds) {
    if (groupIds.isEmpty) {
      AppLogger.debug('getUpcomingSessions: No group IDs provided, returning empty stream');
      return Stream.value([]);
    }

    AppLogger.debug('getUpcomingSessions: Querying sessions for ${groupIds.length} groups: $groupIds');
    
    return _sessionsCollection
        .where('groupId', whereIn: groupIds)
        .where('dateTime', isGreaterThan: Timestamp.now())
        .orderBy('dateTime', descending: false)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map((doc) => StudySessionModel.fromFirestore(doc))
              .toList();
          AppLogger.debug('getUpcomingSessions: Found ${sessions.length} upcoming sessions');
          return sessions;
        });
  }

  // Delete study session
  Future<void> deleteStudySession(String sessionId) async {
    try {
      AppLogger.info('Deleting study session: $sessionId');
      await _sessionsCollection.doc(sessionId).delete();
      AppLogger.info('Study session deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete study session', e, stackTrace);
      throw 'Failed to delete session. Please try again.';
    }
  }

  // Alias for deleteStudySession
  Future<void> deleteSession(String sessionId) => deleteStudySession(sessionId);

  // Update RSVP for a session
  Future<void> updateSessionRsvp({
    required String sessionId,
    required String userId,
    required String userName,
    required RsvpStatus status,
  }) async {
    try {
      AppLogger.info('Updating RSVP for session: $sessionId, user: $userId, status: $status');
      
      final rsvp = RsvpModel(
        userId: userId,
        userName: userName,
        status: status,
        respondedAt: DateTime.now(),
      );
      
      await _sessionsCollection.doc(sessionId).update({
        'rsvps.$userId': rsvp.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Track session attendance for gamification when status is attending
      if (status == RsvpStatus.attending) {
        final gamificationService = GamificationService();
        await gamificationService.trackSessionAttended(userId);
      }
      
      AppLogger.info('RSVP updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update RSVP', e, stackTrace);
      throw 'Failed to update RSVP. Please try again.';
    }
  }

  // Remove RSVP for a session
  Future<void> removeSessionRsvp({
    required String sessionId,
    required String userId,
  }) async {
    try {
      AppLogger.info('Removing RSVP for session: $sessionId, user: $userId');
      
      await _sessionsCollection.doc(sessionId).update({
        'rsvps.$userId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('RSVP removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to remove RSVP', e, stackTrace);
      throw 'Failed to remove RSVP. Please try again.';
    }
  }

  // ==================== JOIN REQUEST OPERATIONS ====================

  // Create join request
  Future<String> createJoinRequest(JoinRequestModel request) async {
    try {
      AppLogger.info('Creating join request for group: ${request.groupId}');
      final docRef = await _requestsCollection.add(request.toFirestore());
      AppLogger.info('Join request created: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create join request', e, stackTrace);
      throw 'Failed to send request. Please try again.';
    }
  }

  // Update join request
  Future<void> updateJoinRequest(JoinRequestModel request) async {
    try {
      AppLogger.info('Updating join request: ${request.id}');
      await _requestsCollection.doc(request.id).update(request.toFirestore());
      AppLogger.info('Join request updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update join request', e, stackTrace);
      throw 'Failed to update request. Please try again.';
    }
  }

  // Get pending requests for a group
  Stream<List<JoinRequestModel>> getGroupJoinRequests(String groupId) {
    return _requestsCollection
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JoinRequestModel.fromFirestore(doc))
            .toList());
  }

  // Get user's join requests
  Stream<List<JoinRequestModel>> getUserJoinRequests(String userId) {
    return _requestsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JoinRequestModel.fromFirestore(doc))
            .toList());
  }

  // ==================== RESOURCE OPERATIONS ====================

  // Upload resource
  Future<String> uploadResource(ResourceModel resource) async {
    try {
      AppLogger.info('Uploading resource: ${resource.fileName}');
      final docRef = await _resourcesCollection.add(resource.toFirestore());
      AppLogger.info('Resource uploaded: ${docRef.id}');
      
      // Track resource upload for gamification
      final gamificationService = GamificationService();
      await gamificationService.trackResourceUploaded(resource.uploadedBy);
      
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload resource', e, stackTrace);
      throw 'Failed to upload resource. Please try again.';
    }
  }

  // Get group resources
  Stream<List<ResourceModel>> getGroupResources(String groupId) {
    return _resourcesCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ResourceModel.fromFirestore(doc))
            .toList());
  }

  // Delete resource
  Future<void> deleteResource(String resourceId) async {
    try {
      AppLogger.info('Deleting resource: $resourceId');
      await _resourcesCollection.doc(resourceId).delete();
      AppLogger.info('Resource deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete resource', e, stackTrace);
      throw 'Failed to delete resource. Please try again.';
    }
  }

  // ==================== GAMIFICATION OPERATIONS ====================

  // Initialize user stats for new user
  Future<void> initializeUserStats(String userId) async {
    try {
      AppLogger.info('Initializing user stats: $userId');
      final stats = UserStatsModel(userId: userId);
      await _userStatsCollection.doc(userId).set(stats.toFirestore());
      AppLogger.info('User stats initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize user stats', e, stackTrace);
      // Don't throw - this is not critical
    }
  }

  // Get user stats
  Future<UserStatsModel?> getUserStats(String userId) async {
    try {
      final doc = await _userStatsCollection.doc(userId).get();
      if (doc.exists) {
        return UserStatsModel.fromFirestore(doc);
      }
      // Initialize if doesn't exist
      await initializeUserStats(userId);
      return UserStatsModel(userId: userId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user stats', e, stackTrace);
      return null;
    }
  }

  // Get user stats stream
  Stream<UserStatsModel?> getUserStatsStream(String userId) {
    return _userStatsCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserStatsModel.fromFirestore(doc);
      }
      return UserStatsModel(userId: userId);
    });
  }

  // Update user stats
  Future<void> updateUserStats(String userId, Map<String, dynamic> updates) async {
    try {
      AppLogger.info('Updating user stats: $userId');
      updates['updatedAt'] = Timestamp.now();
      await _userStatsCollection.doc(userId).set(updates, SetOptions(merge: true));
      AppLogger.info('User stats updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user stats', e, stackTrace);
      // Don't throw - this is not critical
    }
  }

  // Update streak for user
  Future<void> updateUserStreak(String userId) async {
    try {
      final stats = await getUserStats(userId);
      if (stats == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      int newStreak = stats.currentStreak;
      
      if (stats.lastActivityDate != null) {
        final lastActivity = DateTime(
          stats.lastActivityDate!.year,
          stats.lastActivityDate!.month,
          stats.lastActivityDate!.day,
        );
        
        final difference = today.difference(lastActivity).inDays;
        
        if (difference == 1) {
          // Consecutive day - increment streak
          newStreak = stats.currentStreak + 1;
        } else if (difference > 1) {
          // Streak broken - reset
          newStreak = 1;
        }
        // If same day, keep current streak
      } else {
        // First activity
        newStreak = 1;
      }

      final longestStreak = newStreak > stats.longestStreak ? newStreak : stats.longestStreak;

      await updateUserStats(userId, {
        'currentStreak': newStreak,
        'longestStreak': longestStreak,
        'lastActivityDate': Timestamp.fromDate(now),
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user streak', e, stackTrace);
    }
  }

  // Get user achievements
  Stream<List<AchievementModel>> getUserAchievements(String userId) {
    return _achievementsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AchievementModel.fromFirestore(doc))
            .toList());
  }

  // Initialize default achievements for user
  Future<void> initializeUserAchievements(String userId) async {
    try {
      AppLogger.info('Initializing achievements for user: $userId');
      
      final defaultAchievements = [
        AchievementModel(
          id: '',
          userId: userId,
          type: 'sessions_attended',
          title: 'First Session',
          description: 'Attend your first study session',
          iconName: 'school',
          targetValue: 1,
        ),
        AchievementModel(
          id: '',
          userId: userId,
          type: 'sessions_attended',
          title: 'Study Enthusiast',
          description: 'Attend 5 study sessions',
          iconName: 'local_library',
          targetValue: 5,
        ),
        AchievementModel(
          id: '',
          userId: userId,
          type: 'sessions_attended',
          title: 'Study Master',
          description: 'Attend 20 study sessions',
          iconName: 'emoji_events',
          targetValue: 20,
        ),
        AchievementModel(
          id: '',
          userId: userId,
          type: 'groups_joined',
          title: 'Social Learner',
          description: 'Join 3 study groups',
          iconName: 'group_add',
          targetValue: 3,
        ),
        AchievementModel(
          id: '',
          userId: userId,
          type: 'streak',
          title: 'Dedicated Student',
          description: 'Maintain a 7-day streak',
          iconName: 'local_fire_department',
          targetValue: 7,
        ),
        AchievementModel(
          id: '',
          userId: userId,
          type: 'resources_uploaded',
          title: 'Knowledge Sharer',
          description: 'Upload 5 resources',
          iconName: 'upload_file',
          targetValue: 5,
        ),
      ];

      for (final achievement in defaultAchievements) {
        await _achievementsCollection.add(achievement.toFirestore());
      }
      
      AppLogger.info('Achievements initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize achievements', e, stackTrace);
    }
  }

  // Check and update achievements
  Future<void> checkAndUpdateAchievements(String userId) async {
    try {
      final stats = await getUserStats(userId);
      if (stats == null) return;

      final achievementsSnapshot = await _achievementsCollection
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in achievementsSnapshot.docs) {
        final achievement = AchievementModel.fromFirestore(doc);
        if (achievement.isUnlocked) continue;

        int currentValue = 0;
        switch (achievement.type) {
          case 'sessions_attended':
            currentValue = stats.totalSessionsAttended;
            break;
          case 'groups_joined':
            currentValue = stats.totalGroupsJoined;
            break;
          case 'streak':
            currentValue = stats.currentStreak;
            break;
          case 'resources_uploaded':
            currentValue = stats.totalResourcesUploaded;
            break;
        }

        if (currentValue >= achievement.targetValue && !achievement.isUnlocked) {
          // Unlock achievement
          await _achievementsCollection.doc(doc.id).update({
            'currentValue': currentValue,
            'isUnlocked': true,
            'unlockedAt': Timestamp.now(),
          });
          AppLogger.info('Achievement unlocked: ${achievement.title}');
        } else {
          // Update progress
          await _achievementsCollection.doc(doc.id).update({
            'currentValue': currentValue,
          });
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check achievements', e, stackTrace);
    }
  }

  // ==================== ANALYTICS OPERATIONS ====================

  // Get or create group analytics
  Future<GroupAnalyticsModel> getGroupAnalytics(String groupId) async {
    try {
      final doc = await _groupAnalyticsCollection.doc(groupId).get();
      if (doc.exists) {
        return GroupAnalyticsModel.fromFirestore(doc);
      }
      // Create new analytics
      final analytics = GroupAnalyticsModel(groupId: groupId);
      await _groupAnalyticsCollection.doc(groupId).set(analytics.toFirestore());
      return analytics;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get group analytics', e, stackTrace);
      return GroupAnalyticsModel(groupId: groupId);
    }
  }

  // Get group analytics stream
  Stream<GroupAnalyticsModel> getGroupAnalyticsStream(String groupId) {
    return _groupAnalyticsCollection.doc(groupId).snapshots().map((doc) {
      if (doc.exists) {
        return GroupAnalyticsModel.fromFirestore(doc);
      }
      return GroupAnalyticsModel(groupId: groupId);
    });
  }

  // Update group analytics
  Future<void> updateGroupAnalytics(String groupId) async {
    try {
      AppLogger.info('Updating analytics for group: $groupId');
      
      final group = await getStudyGroupById(groupId);
      if (group == null) return;

      final sessionsSnapshot = await _sessionsCollection
          .where('groupId', isEqualTo: groupId)
          .get();
      
      final resourcesSnapshot = await _resourcesCollection
          .where('groupId', isEqualTo: groupId)
          .get();

      int totalAttendance = 0;
      int sessionCount = 0;
      final Map<String, int> activityScores = {};
      final Map<String, int> attendanceTrend = {};

      for (final sessionDoc in sessionsSnapshot.docs) {
        final session = StudySessionModel.fromFirestore(sessionDoc);
        // Only count completed sessions or sessions in the past
        if (session.dateTime.isBefore(DateTime.now())) {
          sessionCount++;
          final attendingCount = session.attendingCount;
          totalAttendance += attendingCount;
          
          // Track attendance by date
          final dateKey = '${session.dateTime.year}-${session.dateTime.month}-${session.dateTime.day}';
          attendanceTrend[dateKey] = (attendanceTrend[dateKey] ?? 0) + attendingCount;
          
          // Add points for attendees (those with attending status)
          for (final entry in session.rsvps.entries) {
            if (entry.value.status == RsvpStatus.attending) {
              activityScores[entry.key] = (activityScores[entry.key] ?? 0) + 10;
            }
          }
        }
      }

      // Add points for resource uploads
      for (final resourceDoc in resourcesSnapshot.docs) {
        final resource = ResourceModel.fromFirestore(resourceDoc);
        activityScores[resource.uploadedBy] = (activityScores[resource.uploadedBy] ?? 0) + 5;
      }

      // Calculate average attendance
      final averageAttendance = sessionCount > 0 && group.memberIds.isNotEmpty
          ? (totalAttendance / (sessionCount * group.memberIds.length)) * 100
          : 0.0;

      // Get top 3 contributors
      final sortedContributors = activityScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topContributors = sortedContributors.take(3).map((e) => e.key).toList();

      final analytics = GroupAnalyticsModel(
        groupId: groupId,
        totalSessions: sessionsSnapshot.docs.length,
        totalMembers: group.memberIds.length,
        totalResources: resourcesSnapshot.docs.length,
        averageAttendance: averageAttendance,
        memberActivityScores: activityScores,
        topContributorIds: topContributors,
        sessionAttendanceTrend: attendanceTrend,
      );

      await _groupAnalyticsCollection.doc(groupId).set(
        analytics.toFirestore(),
        SetOptions(merge: true),
      );
      
      AppLogger.info('Group analytics updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update group analytics', e, stackTrace);
    }
  }

  // ==================== Q&A OPERATIONS ====================

  // Create a new question
  Future<String> createQuestion({
    required String groupId,
    required String title,
    required String description,
    required String userId,
    required String userName,
  }) async {
    try {
      AppLogger.info('Creating question for group: $groupId');
      
      final question = QuestionModel(
        id: '',
        groupId: groupId,
        title: title,
        description: description,
        askedBy: userId,
        askedByName: userName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _questionsCollection.add(question.toFirestore());
      AppLogger.info('Question created successfully: ${docRef.id}');
      
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create question', e, stackTrace);
      throw 'Failed to post question. Please try again.';
    }
  }

  // Get questions for a group
  Stream<List<QuestionModel>> getGroupQuestions(String groupId) {
    return _questionsCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuestionModel.fromFirestore(doc))
            .toList());
  }

  // Get a single question
  Future<QuestionModel?> getQuestionById(String questionId) async {
    try {
      final doc = await _questionsCollection.doc(questionId).get();
      if (doc.exists) {
        return QuestionModel.fromFirestore(doc);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get question', e, stackTrace);
      return null;
    }
  }

  // Toggle question upvote
  Future<void> toggleQuestionUpvote(String questionId, String userId) async {
    try {
      final question = await getQuestionById(questionId);
      if (question == null) return;

      List<String> upvotedBy = List.from(question.upvotedBy);
      List<String> downvotedBy = List.from(question.downvotedBy);

      // Remove from downvotes if exists
      downvotedBy.remove(userId);

      // Toggle upvote
      if (upvotedBy.contains(userId)) {
        upvotedBy.remove(userId);
      } else {
        upvotedBy.add(userId);
      }

      await _questionsCollection.doc(questionId).update({
        'upvotedBy': upvotedBy,
        'downvotedBy': downvotedBy,
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info('Question upvote toggled');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to toggle question upvote', e, stackTrace);
      throw 'Failed to update vote. Please try again.';
    }
  }

  // Toggle question downvote
  Future<void> toggleQuestionDownvote(String questionId, String userId) async {
    try {
      final question = await getQuestionById(questionId);
      if (question == null) return;

      List<String> upvotedBy = List.from(question.upvotedBy);
      List<String> downvotedBy = List.from(question.downvotedBy);

      // Remove from upvotes if exists
      upvotedBy.remove(userId);

      // Toggle downvote
      if (downvotedBy.contains(userId)) {
        downvotedBy.remove(userId);
      } else {
        downvotedBy.add(userId);
      }

      await _questionsCollection.doc(questionId).update({
        'upvotedBy': upvotedBy,
        'downvotedBy': downvotedBy,
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info('Question downvote toggled');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to toggle question downvote', e, stackTrace);
      throw 'Failed to update vote. Please try again.';
    }
  }

  // Mark question as resolved
  Future<void> markQuestionAsResolved(String questionId, bool isResolved) async {
    try {
      await _questionsCollection.doc(questionId).update({
        'isResolved': isResolved,
        'updatedAt': Timestamp.now(),
      });
      AppLogger.info('Question marked as ${isResolved ? 'resolved' : 'unresolved'}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update question status', e, stackTrace);
      throw 'Failed to update question. Please try again.';
    }
  }

  // Create an answer
  Future<String> createAnswer({
    required String questionId,
    required String groupId,
    required String content,
    required String userId,
    required String userName,
  }) async {
    try {
      AppLogger.info('Creating answer for question: $questionId');

      final answer = AnswerModel(
        id: '',
        questionId: questionId,
        groupId: groupId,
        content: content,
        answeredBy: userId,
        answeredByName: userName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _answersCollection.add(answer.toFirestore());

      // Update question answer count
      final question = await getQuestionById(questionId);
      if (question != null) {
        await _questionsCollection.doc(questionId).update({
          'answerCount': question.answerCount + 1,
          'updatedAt': Timestamp.now(),
        });
      }

      AppLogger.info('Answer created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create answer', e, stackTrace);
      throw 'Failed to post answer. Please try again.';
    }
  }

  // Get answers for a question (sorted by votes)
  Stream<List<AnswerModel>> getQuestionAnswers(String questionId) {
    return _answersCollection
        .where('questionId', isEqualTo: questionId)
        .snapshots()
        .map((snapshot) {
      final answers = snapshot.docs
          .map((doc) => AnswerModel.fromFirestore(doc))
          .toList();
      
      // Sort by: accepted first, then by vote score
      answers.sort((a, b) {
        if (a.isAccepted && !b.isAccepted) return -1;
        if (!a.isAccepted && b.isAccepted) return 1;
        return b.voteScore.compareTo(a.voteScore);
      });
      
      return answers;
    });
  }

  // Toggle answer upvote
  Future<void> toggleAnswerUpvote(String answerId, String userId) async {
    try {
      final doc = await _answersCollection.doc(answerId).get();
      if (!doc.exists) return;

      final answer = AnswerModel.fromFirestore(doc);
      List<String> upvotedBy = List.from(answer.upvotedBy);
      List<String> downvotedBy = List.from(answer.downvotedBy);

      // Remove from downvotes if exists
      downvotedBy.remove(userId);

      // Toggle upvote
      if (upvotedBy.contains(userId)) {
        upvotedBy.remove(userId);
      } else {
        upvotedBy.add(userId);
      }

      await _answersCollection.doc(answerId).update({
        'upvotedBy': upvotedBy,
        'downvotedBy': downvotedBy,
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info('Answer upvote toggled');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to toggle answer upvote', e, stackTrace);
      throw 'Failed to update vote. Please try again.';
    }
  }

  // Toggle answer downvote
  Future<void> toggleAnswerDownvote(String answerId, String userId) async {
    try {
      final doc = await _answersCollection.doc(answerId).get();
      if (!doc.exists) return;

      final answer = AnswerModel.fromFirestore(doc);
      List<String> upvotedBy = List.from(answer.upvotedBy);
      List<String> downvotedBy = List.from(answer.downvotedBy);

      // Remove from upvotes if exists
      upvotedBy.remove(userId);

      // Toggle downvote
      if (downvotedBy.contains(userId)) {
        downvotedBy.remove(userId);
      } else {
        downvotedBy.add(userId);
      }

      await _answersCollection.doc(answerId).update({
        'upvotedBy': upvotedBy,
        'downvotedBy': downvotedBy,
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info('Answer downvote toggled');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to toggle answer downvote', e, stackTrace);
      throw 'Failed to update vote. Please try again.';
    }
  }

  // Accept an answer (only question owner can do this)
  Future<void> acceptAnswer(String questionId, String answerId) async {
    try {
      // Unaccept all previous answers for this question
      final answersSnapshot = await _answersCollection
          .where('questionId', isEqualTo: questionId)
          .get();

      final batch = _firestore.batch();
      
      for (final doc in answersSnapshot.docs) {
        batch.update(doc.reference, {
          'isAccepted': doc.id == answerId,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();

      // Mark question as resolved
      await markQuestionAsResolved(questionId, true);

      AppLogger.info('Answer accepted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to accept answer', e, stackTrace);
      throw 'Failed to accept answer. Please try again.';
    }
  }
}
