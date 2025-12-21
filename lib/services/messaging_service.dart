import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chemo_monitor_app/models/message_model.dart';
import 'package:uuid/uuid.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String messagesCollection = 'messages';

  // Helper: Generates a consistent Chat ID for any two users
  String _getChatId(String id1, String id2) {
    return id1.hashCode <= id2.hashCode ? '${id1}_${id2}' : '${id2}_${id1}';
  }

  /// Send a text message
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String message,
    String? fileUrl,
    String? fileName,
  }) async {
    try {
      final String id = const Uuid().v4();
      final String chatId = _getChatId(senderId, receiverId);
      
      final messageModel = MessageModel(
        id: id,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        receiverName: receiverName,
        message: message,
        fileUrl: fileUrl,
        fileName: fileName,
        timestamp: DateTime.now(),
        isRead: false,
        chatId: chatId,
        participants: [senderId, receiverId],
      );

      await _firestore
          .collection(messagesCollection)
          .doc(id)
          .set(messageModel.toMap());
      
      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get conversation between two users
  Stream<List<MessageModel>> getConversation(String userId, String otherUserId) {
    try {
      final String chatId = _getChatId(userId, otherUserId);
      
      print('🔍 Loading chat: $chatId');

      return _firestore
          .collection(messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .handleError((error) {
            print('❌ Firestore Stream Error: $error');
            if (error.toString().contains('index')) {
              print('⚠️ MISSING INDEX! Check Firebase Console for the index creation link.');
            }
          })
          .map((snapshot) {
            print('📨 Loaded ${snapshot.docs.length} messages');
            return snapshot.docs
                .map((doc) {
                  try {
                    return MessageModel.fromMap(doc.data());
                  } catch (e) {
                    print('⚠️ Error parsing message ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<MessageModel>() // Filter out nulls
                .toList();
          });
    } catch (e) {
      print('❌ Error setting up conversation stream: $e');
      return Stream.error(e);
    }
  }

  /// Mark a single message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await _firestore
          .collection(messagesCollection)
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking message as read: $e');
    }
  }

  /// ✅ NEW: Mark all unread messages in a conversation as read
  Future<void> markConversationAsRead(String currentUserId, String otherUserId) async {
    final chatId = _getChatId(currentUserId, otherUserId);
    
    try {
      // Find all messages sent TO me in this chat that are unread
      final snapshot = await _firestore
          .collection(messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print("✅ Marked ${snapshot.docs.length} messages as read.");
    } catch (e) {
      print('❌ Error marking conversation as read: $e');
    }
  }

  /// ✅ NEW: Debug helper to check if messages exist
  Future<void> debugCheckMessages(String userId1, String userId2) async {
    final chatId = _getChatId(userId1, userId2);
    print("🔍 DEBUG: Checking messages for ChatID: $chatId");
    
    try {
      final snapshot = await _firestore
          .collection(messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .get();
          
      print("🔍 DEBUG: Found ${snapshot.docs.length} messages in Firestore.");
      for (var doc in snapshot.docs) {
        print("   - Msg: ${doc.data()['message']} (Sender: ${doc.data()['senderName']})");
      }
    } catch (e) {
      print("❌ DEBUG ERROR: Could not fetch messages. $e");
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(messagesCollection)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }
}