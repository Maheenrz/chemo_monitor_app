// lib/services/messaging_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/models/message_model.dart';
import 'package:chemo_monitor_app/services/cloudinary_service.dart';
import 'package:chemo_monitor_app/services/chat_initializer_service.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Generate chat ID
  String _generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Get conversation between two users
  Stream<List<MessageModel>> getConversation(String userId1, String userId2) {
    final chatId = _generateChatId(userId1, userId2);
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('participants', arrayContains: currentUserId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MessageModel.fromMap(data);
      }).toList();
    });
  }

  // Send text message (Original method - keep this as is)
  Future<void> sendTextMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String message,
  }) async {
    await _sendMessage(
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      receiverName: receiverName,
      message: message,
      messageType: 'text',
    );
  }

  // Send file message (with Cloudinary upload)
  Future<void> sendFileMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required File file,
    String? customFileName,
  }) async {
    try {
      // Upload file to Cloudinary
      final uploadResult = await _cloudinaryService.uploadChatFile(
        file,
        customFileName: customFileName,
      );

      // Get file type
      final fileType = _cloudinaryService.getFileTypeFromFile(file);
      final fileName = uploadResult['fileName'] ?? file.path.split('/').last;

      // Send message with file URL
      await _sendMessage(
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        receiverName: receiverName,
        message: 'File: $fileName',
        messageType: 'file',
        fileUrl: uploadResult['url'],
        fileName: fileName,
        fileType: fileType,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Private method to send any type of message
  Future<void> _sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String message,
    required String messageType,
    String? fileUrl,
    String? fileName,
    String? fileType,
  }) async {
    try {
      final chatId = _generateChatId(senderId, receiverId);
      final timestamp = DateTime.now();
      final participants = [senderId, receiverId];

      final messageData = {
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'message': message,
        'chatId': chatId,
        'participants': participants,
        'timestamp': Timestamp.fromDate(timestamp),
        'isRead': false,
        'messageType': messageType,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileType': fileType,
        'status': 'sent', // Set status to sent
      };

      // Remove null values
      messageData.removeWhere((key, value) => value == null);

      await _firestore.collection('messages').add(messageData);
      
      // Update chat using ChatInitializer
      final chatInitializer = ChatInitializer();
      await chatInitializer.updateChatOnNewMessage(
        chatId: chatId,
        lastMessage: message,
        senderId: senderId,
        participants: participants,
      );
      
    } catch (e) {
      rethrow;
    }
  }

  // For backward compatibility
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String message,
    File? file,
    String? fileName,
    String? fileType,
  }) async {
    if (file != null) {
      await sendFileMessage(
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        receiverName: receiverName,
        file: file,
        customFileName: fileName,
      );
    } else {
      await sendTextMessage(
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        receiverName: receiverName,
        message: message,
      );
    }
  }

  // Mark messages as read
  Future<void> markConversationAsRead(String userId, String otherUserId) async {
    try {
      final chatId = _generateChatId(userId, otherUserId);

      final querySnapshot = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();

        for (var doc in querySnapshot.docs) {
          batch.update(doc.reference, {
            'isRead': true,
            'status': 'read',
            'readAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread message count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get all chats for a user (with last message)
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Find other user ID
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        return {
          'chatId': data['chatId'] ?? doc.id,
          'lastMessage': data['lastMessage'] ?? '',
          'lastMessageSenderId': data['lastMessageSenderId'] ?? '',
          'lastMessageTimestamp':
              data['lastMessageTimestamp'] ?? Timestamp.now(),
          'participants': participants,
          'otherUserId': otherUserId,
          'updatedAt': data['updatedAt'] ?? Timestamp.now(),
        };
      }).toList();
    });
  }
}