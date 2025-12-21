import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String message;
  final String? fileUrl;
  final String? fileName;
  final DateTime timestamp;
  final bool isRead;
  final String chatId; // NEW: Unique ID for this conversation
  final List<String> participants; // NEW: List of IDs for security rules

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.message,
    this.fileUrl,
    this.fileName,
    required this.timestamp,
    this.isRead = false,
    required this.chatId,
    required this.participants,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'message': message,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'chatId': chatId, // Save this
      'participants': participants, // Save this
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      message: map['message'] ?? '',
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      chatId: map['chatId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
    );
  }
}