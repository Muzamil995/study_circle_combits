import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequestModel {
  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String userEmail;
  final String userProfileImageUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final String? message; // Optional message from user
  final DateTime createdAt;
  final DateTime? respondedAt;

  JoinRequestModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userProfileImageUrl,
    required this.status,
    this.message,
    required this.createdAt,
    this.respondedAt,
  });

  // Factory constructor to create from Firestore document
  factory JoinRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JoinRequestModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userProfileImageUrl: data['userProfileImageUrl'] ?? '',
      status: data['status'] ?? 'pending',
      message: data['message'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userProfileImageUrl': userProfileImageUrl,
      'status': status,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  // CopyWith method for immutability
  JoinRequestModel copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? userName,
    String? userEmail,
    String? userProfileImageUrl,
    String? status,
    String? message,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return JoinRequestModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
