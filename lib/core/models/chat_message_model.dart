import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? messageText;
  final String? messageUrl;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.messageText,
    this.messageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'messageText': messageText,
      'messageUrl': messageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatMessageModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return ChatMessageModel(
      id: documentId,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      messageText: map['messageText'] as String?,
      messageUrl: map['messageUrl'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }
}
