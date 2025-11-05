import 'package:cloud_firestore/cloud_firestore.dart';

/// Achievement model representing a user achievement
class AchievementModel {
  final String id;
  final String userId;
  final String type; // 'sessions_attended', 'groups_joined', 'streak', 'resources_uploaded', etc.
  final String title;
  final String description;
  final String iconName; // Icon identifier
  final int targetValue; // Target to unlock (e.g., 5 sessions)
  final int currentValue; // Current progress
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final DateTime createdAt;

  AchievementModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.iconName,
    required this.targetValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create AchievementModel from Firestore document
  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AchievementModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'emoji_events',
      targetValue: data['targetValue'] ?? 0,
      currentValue: data['currentValue'] ?? 0,
      isUnlocked: data['isUnlocked'] ?? false,
      unlockedAt: (data['unlockedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert AchievementModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'iconName': iconName,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Get progress percentage
  double get progress {
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Create a copy with updated fields
  AchievementModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? description,
    String? iconName,
    int? targetValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    DateTime? createdAt,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AchievementModel(id: $id, type: $type, title: $title, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }
}
