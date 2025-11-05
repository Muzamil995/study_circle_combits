import 'package:cloud_firestore/cloud_firestore.dart';

/// Study Group model representing a study group in the app
class StudyGroupModel {
  final String id;
  final String groupName;
  final String courseName;
  final String courseCode;
  final String description;
  final List<String> topics;
  final int maxMembers;
  final String schedule;
  final String location;
  final bool isPublic;
  final String creatorId;
  final String creatorName;
  final List<String> memberIds;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudyGroupModel({
    required this.id,
    required this.groupName,
    required this.courseName,
    required this.courseCode,
    required this.description,
    List<String>? topics,
    required this.maxMembers,
    required this.schedule,
    required this.location,
    required this.isPublic,
    required this.creatorId,
    required this.creatorName,
    List<String>? memberIds,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : topics = topics ?? [],
        memberIds = memberIds ?? [],
        memberCount = memberCount ?? 1,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create StudyGroupModel from Firestore document
  factory StudyGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return StudyGroupModel(
      id: doc.id,
      groupName: data['groupName'] ?? '',
      courseName: data['courseName'] ?? '',
      courseCode: data['courseCode'] ?? '',
      description: data['description'] ?? '',
      topics: List<String>.from(data['topics'] ?? []),
      maxMembers: data['maxMembers'] ?? 10,
      schedule: data['schedule'] ?? '',
      location: data['location'] ?? '',
      isPublic: data['isPublic'] ?? true,
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberCount: data['memberCount'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create StudyGroupModel from Map
  factory StudyGroupModel.fromMap(Map<String, dynamic> data) {
    return StudyGroupModel(
      id: data['id'] ?? '',
      groupName: data['groupName'] ?? '',
      courseName: data['courseName'] ?? '',
      courseCode: data['courseCode'] ?? '',
      description: data['description'] ?? '',
      topics: List<String>.from(data['topics'] ?? []),
      maxMembers: data['maxMembers'] ?? 10,
      schedule: data['schedule'] ?? '',
      location: data['location'] ?? '',
      isPublic: data['isPublic'] ?? true,
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberCount: data['memberCount'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert StudyGroupModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'groupName': groupName,
      'courseName': courseName,
      'courseCode': courseCode,
      'description': description,
      'topics': topics,
      'maxMembers': maxMembers,
      'schedule': schedule,
      'location': location,
      'isPublic': isPublic,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'memberIds': memberIds,
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert StudyGroupModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupName': groupName,
      'courseName': courseName,
      'courseCode': courseCode,
      'description': description,
      'topics': topics,
      'maxMembers': maxMembers,
      'schedule': schedule,
      'location': location,
      'isPublic': isPublic,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'memberIds': memberIds,
      'memberCount': memberCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy of StudyGroupModel with updated fields
  StudyGroupModel copyWith({
    String? id,
    String? groupName,
    String? courseName,
    String? courseCode,
    String? description,
    List<String>? topics,
    int? maxMembers,
    String? schedule,
    String? location,
    bool? isPublic,
    String? creatorId,
    String? creatorName,
    List<String>? memberIds,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyGroupModel(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      description: description ?? this.description,
      topics: topics ?? this.topics,
      maxMembers: maxMembers ?? this.maxMembers,
      schedule: schedule ?? this.schedule,
      location: location ?? this.location,
      isPublic: isPublic ?? this.isPublic,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if group is full
  bool get isFull => memberCount >= maxMembers;

  /// Check if user is a member
  bool isMember(String userId) => memberIds.contains(userId);

  /// Check if user is the creator
  bool isCreator(String userId) => creatorId == userId;

  @override
  String toString() {
    return 'StudyGroupModel(id: $id, groupName: $groupName, courseCode: $courseCode, members: $memberCount/$maxMembers)';
  }
}
