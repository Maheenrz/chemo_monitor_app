// lib/models/message_model.dart
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
  final String? fileType;
  final DateTime timestamp;
  final bool isRead;
  final String chatId;
  final List<String> participants;
  final String messageType;
  
  // New status tracking fields
  final String status; // 'pending', 'sent', 'delivered', 'read'
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? tempId;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.message,
    this.fileUrl,
    this.fileName,
    this.fileType,
    required this.timestamp,
    this.isRead = false,
    required this.chatId,
    required this.participants,
    this.messageType = 'text',
    this.status = 'pending',
    this.deliveredAt,
    this.readAt,
    this.tempId,
  });

  // Factory constructor for pending messages
  factory MessageModel.pending({
    required String tempId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String message,
    required String chatId,
    required List<String> participants,
    String? fileUrl,
    String? fileName,
    String? fileType,
    String messageType = 'text',
  }) {
    return MessageModel(
      id: '',
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      receiverName: receiverName,
      message: message,
      fileUrl: fileUrl,
      fileName: fileName,
      fileType: fileType,
      timestamp: DateTime.now(),
      isRead: false,
      chatId: chatId,
      participants: participants,
      messageType: messageType,
      status: 'pending',
      tempId: tempId,
    );
  }

  // Copy with method
  MessageModel copyWith({
    String? id,
    String? status,
    bool? isRead,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: this.senderId,
      senderName: this.senderName,
      receiverId: this.receiverId,
      receiverName: this.receiverName,
      message: this.message,
      fileUrl: this.fileUrl,
      fileName: this.fileName,
      fileType: this.fileType,
      timestamp: this.timestamp,
      isRead: isRead ?? this.isRead,
      chatId: this.chatId,
      participants: this.participants,
      messageType: this.messageType,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      tempId: this.tempId,
    );
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isSent => status == 'sent';
  bool get isDelivered => status == 'delivered';
  bool get isReadStatus => status == 'read';

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'message': message,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'chatId': chatId,
      'participants': participants,
      'messageType': messageType,
      'status': status,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  // Create from Firestore map
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    // Handle timestamp
    DateTime timestamp;
    if (map['timestamp'] is Timestamp) {
      timestamp = (map['timestamp'] as Timestamp).toDate();
    } else {
      timestamp = DateTime.now();
    }

    // Handle deliveredAt
    DateTime? deliveredAt;
    if (map['deliveredAt'] is Timestamp) {
      deliveredAt = (map['deliveredAt'] as Timestamp).toDate();
    }

    // Handle readAt
    DateTime? readAt;
    if (map['readAt'] is Timestamp) {
      readAt = (map['readAt'] as Timestamp).toDate();
    }

    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      message: map['message'] ?? '',
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      fileType: map['fileType'],
      timestamp: timestamp,
      isRead: map['isRead'] ?? false,
      chatId: map['chatId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      messageType: map['messageType'] ?? 'text',
      status: map['status'] ?? 'sent',
      deliveredAt: deliveredAt,
      readAt: readAt,
    );
  }
}