import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_circle/models/user_model.dart';
import 'package:study_circle/models/study_group_model.dart';
import 'package:study_circle/models/study_session_model.dart';
import 'package:study_circle/models/join_request_model.dart';
import 'package:study_circle/models/resource_model.dart';
import 'package:study_circle/utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _groupsCollection => _firestore.collection('study_groups');
  CollectionReference get _sessionsCollection => _firestore.collection('study_sessions');
  CollectionReference get _requestsCollection => _firestore.collection('join_requests');
  CollectionReference get _resourcesCollection => _firestore.collection('resources');

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
      AppLogger.info('Study group created: ${docRef.id}');
      return docRef.id;
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

  // Search study groups
  Future<List<StudyGroupModel>> searchStudyGroups(String query) async {
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _groupsCollection
          .where('isPublic', isEqualTo: true)
          .get();

      // Filter by name or course code
      return snapshot.docs
          .map((doc) => StudyGroupModel.fromFirestore(doc))
          .where((group) =>
              group.name.toLowerCase().contains(queryLower) ||
              group.courseCode.toLowerCase().contains(queryLower))
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
      AppLogger.info('Study session created: ${docRef.id}');
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

  // Get group sessions
  Stream<List<StudySessionModel>> getGroupSessions(String groupId) {
    return _sessionsCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudySessionModel.fromFirestore(doc))
            .toList());
  }

  // Get upcoming sessions for user
  Stream<List<StudySessionModel>> getUpcomingSessions(List<String> groupIds) {
    if (groupIds.isEmpty) {
      return Stream.value([]);
    }

    return _sessionsCollection
        .where('groupId', whereIn: groupIds)
        .where('dateTime', isGreaterThan: Timestamp.now())
        .orderBy('dateTime', descending: false)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudySessionModel.fromFirestore(doc))
            .toList());
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
}
