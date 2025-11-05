import 'package:cloud_firestore/cloud_firestore.dart';

/// Group analytics model for tracking group statistics
class GroupAnalyticsModel {
  final String groupId;
  final int totalSessions;
  final int totalMembers;
  final int totalResources;
  final double averageAttendance; // Average percentage of members attending sessions
  final Map<String, int> memberActivityScores; // userId -> activity score
  final List<String> topContributorIds; // Top 3 most active members
  final Map<String, int> sessionAttendanceTrend; // date -> attendance count
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupAnalyticsModel({
    required this.groupId,
    this.totalSessions = 0,
    this.totalMembers = 0,
    this.totalResources = 0,
    this.averageAttendance = 0.0,
    Map<String, int>? memberActivityScores,
    List<String>? topContributorIds,
    Map<String, int>? sessionAttendanceTrend,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : memberActivityScores = memberActivityScores ?? {},
        topContributorIds = topContributorIds ?? [],
        sessionAttendanceTrend = sessionAttendanceTrend ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create GroupAnalyticsModel from Firestore document
  factory GroupAnalyticsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GroupAnalyticsModel(
      groupId: doc.id,
      totalSessions: data['totalSessions'] ?? 0,
      totalMembers: data['totalMembers'] ?? 0,
      totalResources: data['totalResources'] ?? 0,
      averageAttendance: (data['averageAttendance'] ?? 0.0).toDouble(),
      memberActivityScores:
          Map<String, int>.from(data['memberActivityScores'] ?? {}),
      topContributorIds: List<String>.from(data['topContributorIds'] ?? []),
      sessionAttendanceTrend:
          Map<String, int>.from(data['sessionAttendanceTrend'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert GroupAnalyticsModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'totalSessions': totalSessions,
      'totalMembers': totalMembers,
      'totalResources': totalResources,
      'averageAttendance': averageAttendance,
      'memberActivityScores': memberActivityScores,
      'topContributorIds': topContributorIds,
      'sessionAttendanceTrend': sessionAttendanceTrend,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  GroupAnalyticsModel copyWith({
    String? groupId,
    int? totalSessions,
    int? totalMembers,
    int? totalResources,
    double? averageAttendance,
    Map<String, int>? memberActivityScores,
    List<String>? topContributorIds,
    Map<String, int>? sessionAttendanceTrend,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupAnalyticsModel(
      groupId: groupId ?? this.groupId,
      totalSessions: totalSessions ?? this.totalSessions,
      totalMembers: totalMembers ?? this.totalMembers,
      totalResources: totalResources ?? this.totalResources,
      averageAttendance: averageAttendance ?? this.averageAttendance,
      memberActivityScores: memberActivityScores ?? this.memberActivityScores,
      topContributorIds: topContributorIds ?? this.topContributorIds,
      sessionAttendanceTrend:
          sessionAttendanceTrend ?? this.sessionAttendanceTrend,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'GroupAnalyticsModel(groupId: $groupId, sessions: $totalSessions, avgAttendance: ${averageAttendance.toStringAsFixed(1)}%)';
  }
}
