import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/models/message_model.dart';
import 'package:chemo_monitor_app/services/messaging_service.dart';
import 'package:chemo_monitor_app/services/cloudinary_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole; // Added to fix constructor

  const ChatScreen({
    super.key, // Modern syntax
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final MessagingService _messagingService = MessagingService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  // Optimistic UI list
  final List<MessageModel> _optimisticMessages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mark messages as read when screen opens
    _markRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markRead();
    }
  }

  Future<void> _markRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _messagingService.markConversationAsRead(user.uid, widget.otherUserId);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Small delay to allow list to render new item
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent, // min because of reverse: true
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage({String? fileUrl, String? fileName}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String messageText = _messageController.text.trim();
    if (messageText.isEmpty && fileUrl == null) return;

    _messageController.clear();

    // 1. Create Optimistic Message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = MessageModel(
      id: tempId,
      senderId: user.uid,
      senderName: user.displayName ?? user.email ?? 'User',
      receiverId: widget.otherUserId,
      receiverName: widget.otherUserName,
      message: messageText.isEmpty ? '📎 Sent an attachment' : messageText,
      fileUrl: fileUrl,
      fileName: fileName,
      timestamp: DateTime.now(),
      isRead: false,
      chatId: 'temp', 
      participants: [user.uid, widget.otherUserId],
    );

    setState(() {
      _optimisticMessages.insert(0, optimisticMsg); // Insert at top (reverse list)
    });
    
    _scrollToBottom();

    try {
      // 2. Send to Backend
      await _messagingService.sendMessage(
        senderId: user.uid,
        senderName: user.displayName ?? user.email ?? 'User',
        receiverId: widget.otherUserId,
        receiverName: widget.otherUserName,
        message: messageText.isEmpty ? '📎 Sent an attachment' : messageText,
        fileUrl: fileUrl,
        fileName: fileName,
      );

      // 3. Remove Optimistic Message (Firestore stream will replace it)
      if (mounted) {
        setState(() {
          _optimisticMessages.removeWhere((m) => m.id == tempId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticMessages.removeWhere((m) => m.id == tempId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isUploading = true);
        String fileUrl = await _cloudinaryService.uploadFile(
          file: File(image.path),
          folder: 'chat_attachments',
        );
        await _sendMessage(fileUrl: fileUrl, fileName: image.name);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Camera'),
            onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: Icon(Icons.photo),
            title: Text('Gallery'),
            onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName, style: TextStyle(fontSize: 16)),
            Text(
              widget.otherUserRole == 'doctor' ? 'Doctor' : 'Patient',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messagingService.getConversation(user.uid, widget.otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                // Reverse Firestore messages for chat view
                final firestoreMessages = (snapshot.data ?? []).reversed.toList();
                final allMessages = [..._optimisticMessages, ...firestoreMessages];

                if (allMessages.isEmpty) {
                  return Center(child: Text('Start a conversation!'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Newest at bottom
                  padding: EdgeInsets.all(16),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final message = allMessages[index];
                    final isMe = message.senderId == user.uid;
                    final isOptimistic = message.id.startsWith('temp_');

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      isOptimistic: isOptimistic,
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading) LinearProgressIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_photo_alternate, color: AppColors.primary),
              onPressed: _isUploading ? null : _showImageOptions,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                maxLines: null,
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: AppColors.primary),
              onPressed: _isUploading ? null : () => _sendMessage(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isOptimistic;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isOptimistic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Opacity(
              opacity: isOptimistic ? 0.6 : 1.0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
                    bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.fileUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.fileUrl!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    if (message.message != '📎 Sent an attachment')
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('hh:mm a').format(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        if (isMe) ...[
                          SizedBox(width: 4),
                          Icon(
                            isOptimistic ? Icons.access_time : (message.isRead ? Icons.done_all : Icons.done),
                            size: 12,
                            color: Colors.white70,
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}