import 'package:cloud_firestore/cloud_firestore.dart';

class StudySessionModel {
  final String id;
  final String groupId;
  final String title;
  final String topic;
  final DateTime dateTime;
  final int durationMinutes;
  final String agenda;
  final String location;
  final String createdBy;
  final List<String> rsvpList;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudySessionModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.topic,
    required this.dateTime,
    required this.durationMinutes,
    required this.agenda,
    required this.location,
    required this.createdBy,
    required this.rsvpList,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create from Firestore document
  factory StudySessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudySessionModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      title: data['title'] ?? '',
      topic: data['topic'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 60,
      agenda: data['agenda'] ?? '',
      location: data['location'] ?? '',
      createdBy: data['createdBy'] ?? '',
      rsvpList: List<String>.from(data['rsvpList'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'title': title,
      'topic': topic,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'agenda': agenda,
      'location': location,
      'createdBy': createdBy,
      'rsvpList': rsvpList,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // CopyWith method for immutability
  StudySessionModel copyWith({
    String? id,
    String? groupId,
    String? title,
    String? topic,
    DateTime? dateTime,
    int? durationMinutes,
    String? agenda,
    String? location,
    String? createdBy,
    List<String>? rsvpList,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudySessionModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      agenda: agenda ?? this.agenda,
      location: location ?? this.location,
      createdBy: createdBy ?? this.createdBy,
      rsvpList: rsvpList ?? this.rsvpList,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
