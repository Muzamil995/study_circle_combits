import 'package:study_circle/services/firestore_service.dart';
import 'package:study_circle/utils/logger.dart';

/// Service to handle gamification triggers
class GamificationService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Track when user joins a group
  Future<void> trackGroupJoined(String userId) async {
    try {
      final stats = await _firestoreService.getUserStats(userId);
      if (stats == null) {
        await _firestoreService.initializeUserStats(userId);
      }

      await _firestoreService.updateUserStats(userId, {
        'totalGroupsJoined': (stats?.totalGroupsJoined ?? 0) + 1,
        'totalPoints': (stats?.totalPoints ?? 0) + 10,
      });

      await _firestoreService.updateUserStreak(userId);
      await _firestoreService.checkAndUpdateAchievements(userId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to track group joined', e, stackTrace);
    }
  }

  /// Track when user creates a group
  Future<void> trackGroupCreated(String userId) async {
    try {
      final stats = await _firestoreService.getUserStats(userId);
      if (stats == null) {
        await _firestoreService.initializeUserStats(userId);
      }

      await _firestoreService.updateUserStats(userId, {
        'totalGroupsCreated': (stats?.totalGroupsCreated ?? 0) + 1,
        'totalPoints': (stats?.totalPoints ?? 0) + 25,
      });

      await _firestoreService.updateUserStreak(userId);
      await _firestoreService.checkAndUpdateAchievements(userId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to track group created', e, stackTrace);
    }
  }

  /// Track when user attends a session
  Future<void> trackSessionAttended(String userId) async {
    try {
      final stats = await _firestoreService.getUserStats(userId);
      if (stats == null) {
        await _firestoreService.initializeUserStats(userId);
      }

      await _firestoreService.updateUserStats(userId, {
        'totalSessionsAttended': (stats?.totalSessionsAttended ?? 0) + 1,
        'totalPoints': (stats?.totalPoints ?? 0) + 15,
      });

      await _firestoreService.updateUserStreak(userId);
      await _firestoreService.checkAndUpdateAchievements(userId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to track session attended', e, stackTrace);
    }
  }

  /// Track when user uploads a resource
  Future<void> trackResourceUploaded(String userId) async {
    try {
      final stats = await _firestoreService.getUserStats(userId);
      if (stats == null) {
        await _firestoreService.initializeUserStats(userId);
      }

      await _firestoreService.updateUserStats(userId, {
        'totalResourcesUploaded': (stats?.totalResourcesUploaded ?? 0) + 1,
        'totalPoints': (stats?.totalPoints ?? 0) + 5,
      });

      await _firestoreService.updateUserStreak(userId);
      await _firestoreService.checkAndUpdateAchievements(userId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to track resource uploaded', e, stackTrace);
    }
  }

  /// Initialize stats and achievements for a new user
  Future<void> initializeForNewUser(String userId) async {
    try {
      await _firestoreService.initializeUserStats(userId);
      await _firestoreService.initializeUserAchievements(userId);
      AppLogger.info('Gamification initialized for new user: $userId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize gamification', e, stackTrace);
    }
  }

  /// Update group analytics after an event
  Future<void> updateGroupAnalytics(String groupId) async {
    try {
      await _firestoreService.updateGroupAnalytics(groupId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update group analytics', e, stackTrace);
    }
  }
}
