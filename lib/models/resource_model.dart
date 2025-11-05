import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {
  final String id;
  final String groupId;
  final String uploadedBy;
  final String uploaderName;
  final String title;
  final String description;
  final String fileUrl; // Cloudinary URL
  final String fileType; // 'image', 'pdf', 'video', 'other'
  final String fileName;
  final int fileSizeBytes;
  final DateTime uploadedAt;
  final List<String> tags;

  ResourceModel({
    required this.id,
    required this.groupId,
    required this.uploadedBy,
    required this.uploaderName,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileType,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.tags,
  });

  // Factory constructor to create from Firestore document
  factory ResourceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResourceModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      uploaderName: data['uploaderName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      fileType: data['fileType'] ?? 'other',
      fileName: data['fileName'] ?? '',
      fileSizeBytes: data['fileSizeBytes'] ?? 0,
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'uploadedBy': uploadedBy,
      'uploaderName': uploaderName,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'tags': tags,
    };
  }

  // CopyWith method for immutability
  ResourceModel copyWith({
    String? id,
    String? groupId,
    String? uploadedBy,
    String? uploaderName,
    String? title,
    String? description,
    String? fileUrl,
    String? fileType,
    String? fileName,
    int? fileSizeBytes,
    DateTime? uploadedAt,
    List<String>? tags,
  }) {
    return ResourceModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploaderName: uploaderName ?? this.uploaderName,
      title: title ?? this.title,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      tags: tags ?? this.tags,
    );
  }

  // Helper method to get human-readable file size
  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(2)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
