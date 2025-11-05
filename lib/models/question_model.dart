import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final String askedBy;
  final String askedByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> upvotedBy;
  final List<String> downvotedBy;
  final int answerCount;
  final bool isResolved;

  QuestionModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.askedBy,
    required this.askedByName,
    required this.createdAt,
    required this.updatedAt,
    List<String>? upvotedBy,
    List<String>? downvotedBy,
    this.answerCount = 0,
    this.isResolved = false,
  })  : upvotedBy = upvotedBy ?? [],
        downvotedBy = downvotedBy ?? [];

  // Factory constructor to create from Firestore document
  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return QuestionModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      askedBy: data['askedBy'] ?? '',
      askedByName: data['askedByName'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      upvotedBy: data['upvotedBy'] != null
          ? List<String>.from(data['upvotedBy'])
          : [],
      downvotedBy: data['downvotedBy'] != null
          ? List<String>.from(data['downvotedBy'])
          : [],
      answerCount: data['answerCount'] ?? 0,
      isResolved: data['isResolved'] ?? false,
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'askedBy': askedBy,
      'askedByName': askedByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'upvotedBy': upvotedBy,
      'downvotedBy': downvotedBy,
      'answerCount': answerCount,
      'isResolved': isResolved,
    };
  }

  // Helper getters
  int get voteScore => upvotedBy.length - downvotedBy.length;

  bool hasUserUpvoted(String userId) => upvotedBy.contains(userId);
  bool hasUserDownvoted(String userId) => downvotedBy.contains(userId);

  // CopyWith method for immutability
  QuestionModel copyWith({
    String? id,
    String? groupId,
    String? title,
    String? description,
    String? askedBy,
    String? askedByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? upvotedBy,
    List<String>? downvotedBy,
    int? answerCount,
    bool? isResolved,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      askedBy: askedBy ?? this.askedBy,
      askedByName: askedByName ?? this.askedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      upvotedBy: upvotedBy ?? this.upvotedBy,
      downvotedBy: downvotedBy ?? this.downvotedBy,
      answerCount: answerCount ?? this.answerCount,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}
