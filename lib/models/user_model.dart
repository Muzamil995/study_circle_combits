import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing a student in the StudyCircle app
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String department;
  final int semester;
  final int year;
  final String profileImageUrl;
  final List<String> groupsJoined;
  final List<String> groupsCreated;
  final int sessionsAttended;
  final bool isDarkMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.department,
    required this.semester,
    required this.year,
    this.profileImageUrl = '',
    List<String>? groupsJoined,
    List<String>? groupsCreated,
    this.sessionsAttended = 0,
    this.isDarkMode = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : groupsJoined = groupsJoined ?? [],
        groupsCreated = groupsCreated ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
      semester: data['semester'] ?? 1,
      year: data['year'] ?? 2024,
      profileImageUrl: data['profileImageUrl'] ?? '',
      groupsJoined: List<String>.from(data['groupsJoined'] ?? []),
      groupsCreated: List<String>.from(data['groupsCreated'] ?? []),
      sessionsAttended: data['sessionsAttended'] ?? 0,
      isDarkMode: data['isDarkMode'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
      semester: data['semester'] ?? 1,
      year: data['year'] ?? 2024,
      profileImageUrl: data['profileImageUrl'] ?? '',
      groupsJoined: List<String>.from(data['groupsJoined'] ?? []),
      groupsCreated: List<String>.from(data['groupsCreated'] ?? []),
      sessionsAttended: data['sessionsAttended'] ?? 0,
      isDarkMode: data['isDarkMode'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'department': department,
      'semester': semester,
      'year': year,
      'profileImageUrl': profileImageUrl,
      'groupsJoined': groupsJoined,
      'groupsCreated': groupsCreated,
      'sessionsAttended': sessionsAttended,
      'isDarkMode': isDarkMode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert UserModel to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'department': department,
      'semester': semester,
      'year': year,
      'profileImageUrl': profileImageUrl,
      'groupsJoined': groupsJoined,
      'groupsCreated': groupsCreated,
      'sessionsAttended': sessionsAttended,
      'isDarkMode': isDarkMode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? department,
    int? semester,
    int? year,
    String? profileImageUrl,
    List<String>? groupsJoined,
    List<String>? groupsCreated,
    int? sessionsAttended,
    bool? isDarkMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      year: year ?? this.year,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      groupsJoined: groupsJoined ?? this.groupsJoined,
      groupsCreated: groupsCreated ?? this.groupsCreated,
      sessionsAttended: sessionsAttended ?? this.sessionsAttended,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, department: $department)';
  }
}
