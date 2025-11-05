import 'package:cloud_firestore/cloud_firestore.dart';

/// User statistics model for tracking gamification data
class UserStatsModel {
  final String userId;
  final int totalSessionsAttended;
  final int totalGroupsJoined;
  final int totalGroupsCreated;
  final int totalResourcesUploaded;
  final int currentStreak; // Days in a row with activity
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int totalPoints; // Overall gamification points
  final List<String> earnedBadgeIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserStatsModel({
    required this.userId,
    this.totalSessionsAttended = 0,
    this.totalGroupsJoined = 0,
    this.totalGroupsCreated = 0,
    this.totalResourcesUploaded = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.totalPoints = 0,
    List<String>? earnedBadgeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : earnedBadgeIds = earnedBadgeIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create UserStatsModel from Firestore document
  factory UserStatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserStatsModel(
      userId: doc.id,
      totalSessionsAttended: data['totalSessionsAttended'] ?? 0,
      totalGroupsJoined: data['totalGroupsJoined'] ?? 0,
      totalGroupsCreated: data['totalGroupsCreated'] ?? 0,
      totalResourcesUploaded: data['totalResourcesUploaded'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastActivityDate: (data['lastActivityDate'] as Timestamp?)?.toDate(),
      totalPoints: data['totalPoints'] ?? 0,
      earnedBadgeIds: List<String>.from(data['earnedBadgeIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert UserStatsModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalSessionsAttended': totalSessionsAttended,
      'totalGroupsJoined': totalGroupsJoined,
      'totalGroupsCreated': totalGroupsCreated,
      'totalResourcesUploaded': totalResourcesUploaded,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate != null
          ? Timestamp.fromDate(lastActivityDate!)
          : null,
      'totalPoints': totalPoints,
      'earnedBadgeIds': earnedBadgeIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  UserStatsModel copyWith({
    String? userId,
    int? totalSessionsAttended,
    int? totalGroupsJoined,
    int? totalGroupsCreated,
    int? totalResourcesUploaded,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? totalPoints,
    List<String>? earnedBadgeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserStatsModel(
      userId: userId ?? this.userId,
      totalSessionsAttended:
          totalSessionsAttended ?? this.totalSessionsAttended,
      totalGroupsJoined: totalGroupsJoined ?? this.totalGroupsJoined,
      totalGroupsCreated: totalGroupsCreated ?? this.totalGroupsCreated,
      totalResourcesUploaded:
          totalResourcesUploaded ?? this.totalResourcesUploaded,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      totalPoints: totalPoints ?? this.totalPoints,
      earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserStatsModel(userId: $userId, streak: $currentStreak, points: $totalPoints)';
  }
}
