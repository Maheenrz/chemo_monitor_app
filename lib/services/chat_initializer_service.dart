// lib/services/chat_initializer.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Call this once when app starts or when user logs in
  Future<void> initializeUserChats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    print('🔄 Initializing chats for user: ${user.uid}');
    
    try {
      // Get all messages for current user
      final messages = await _firestore
          .collection('messages')
          .where('participants', arrayContains: user.uid)
          .get();
      
      print('📨 Found ${messages.docs.length} messages');
      
      // Group by chatId
      final chats = <String, Map<String, dynamic>>{};
      
      for (var doc in messages.docs) {
        final data = doc.data();
        final chatId = data['chatId'];
        
        if (chatId != null && !chats.containsKey(chatId)) {
          final participants = List<String>.from(data['participants'] ?? []);
          
          chats[chatId] = {
            'chatId': chatId,
            'participants': participants,
            'lastMessage': data['message'] ?? '',
            'lastMessageSenderId': data['senderId'] ?? '',
            'lastMessageTimestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
        }
      }
      
      // Save to chats collection
      for (var chat in chats.values) {
        await _firestore.collection('chats').doc(chat['chatId']).set(chat);
      }
      
      print('✅ Initialized ${chats.length} chats for user ${user.uid}');
      
    } catch (e) {
      print('❌ Error initializing chats: $e');
    }
  }

  // Call this when a new message is sent
  Future<void> updateChatOnNewMessage({
    required String chatId,
    required String lastMessage,
    required String senderId,
    required List<String> participants,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'lastMessage': lastMessage,
        'lastMessageSenderId': senderId,
        'participants': participants,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Updated chat: $chatId');
    } catch (e) {
      print('❌ Error updating chat: $e');
    }
  }

  // Get user's chats
  Stream<List<Map<String, dynamic>>> getUserChatsStream(String userId) {
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
              'id': doc.id,
              'chatId': data['chatId'] ?? doc.id,
              'lastMessage': data['lastMessage'] ?? '',
              'lastMessageSenderId': data['lastMessageSenderId'] ?? '',
              'lastMessageTimestamp': data['lastMessageTimestamp'] ?? Timestamp.now(),
              'participants': participants,
              'otherUserId': otherUserId,
              'updatedAt': data['updatedAt'] ?? Timestamp.now(),
            };
          }).toList();
        });
  }
}
