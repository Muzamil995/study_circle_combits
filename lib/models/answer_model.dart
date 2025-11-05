import 'package:cloud_firestore/cloud_firestore.dart';

class AnswerModel {
  final String id;
  final String questionId;
  final String groupId;
  final String content;
  final String answeredBy;
  final String answeredByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> upvotedBy;
  final List<String> downvotedBy;
  final bool isAccepted;

  AnswerModel({
    required this.id,
    required this.questionId,
    required this.groupId,
    required this.content,
    required this.answeredBy,
    required this.answeredByName,
    required this.createdAt,
    required this.updatedAt,
    List<String>? upvotedBy,
    List<String>? downvotedBy,
    this.isAccepted = false,
  })  : upvotedBy = upvotedBy ?? [],
        downvotedBy = downvotedBy ?? [];

  // Factory constructor to create from Firestore document
  factory AnswerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AnswerModel(
      id: doc.id,
      questionId: data['questionId'] ?? '',
      groupId: data['groupId'] ?? '',
      content: data['content'] ?? '',
      answeredBy: data['answeredBy'] ?? '',
      answeredByName: data['answeredByName'] ?? '',
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
      isAccepted: data['isAccepted'] ?? false,
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'questionId': questionId,
      'groupId': groupId,
      'content': content,
      'answeredBy': answeredBy,
      'answeredByName': answeredByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'upvotedBy': upvotedBy,
      'downvotedBy': downvotedBy,
      'isAccepted': isAccepted,
    };
  }

  // Helper getters
  int get voteScore => upvotedBy.length - downvotedBy.length;

  bool hasUserUpvoted(String userId) => upvotedBy.contains(userId);
  bool hasUserDownvoted(String userId) => downvotedBy.contains(userId);

  // CopyWith method for immutability
  AnswerModel copyWith({
    String? id,
    String? questionId,
    String? groupId,
    String? content,
    String? answeredBy,
    String? answeredByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? upvotedBy,
    List<String>? downvotedBy,
    bool? isAccepted,
  }) {
    return AnswerModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      groupId: groupId ?? this.groupId,
      content: content ?? this.content,
      answeredBy: answeredBy ?? this.answeredBy,
      answeredByName: answeredByName ?? this.answeredByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      upvotedBy: upvotedBy ?? this.upvotedBy,
      downvotedBy: downvotedBy ?? this.downvotedBy,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }
}
