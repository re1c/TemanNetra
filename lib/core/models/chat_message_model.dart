import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? messageText;
  final String? messageUrl;
  final DateTime createdAt;
  final String messageType;
  final bool isPlayed;
  final int? duration;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.messageText,
    this.messageUrl,
    required this.createdAt,
    this.messageType = 'text',
    this.isPlayed = false,
    this.duration,
  });

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? messageText,
    String? messageUrl,
    DateTime? createdAt,
    String? messageType,
    bool? isPlayed,
    int? duration,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      messageText: messageText ?? this.messageText,
      messageUrl: messageUrl ?? this.messageUrl,
      createdAt: createdAt ?? this.createdAt,
      messageType: messageType ?? this.messageType,
      isPlayed: isPlayed ?? this.isPlayed,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'messageText': messageText,
      'messageUrl': messageUrl,
      'createdAt': createdAt.toIso8601String(),
      'messageType': messageType,
      'isPlayed': isPlayed,
      'duration': duration,
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
      messageType: map['messageType'] as String? ?? 'text',
      isPlayed: map['isPlayed'] as bool? ?? false,
      duration: map['duration'] as int?,
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
