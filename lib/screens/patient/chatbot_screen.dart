import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/chatbot_service.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:intl/intl.dart';
import 'package:chemo_monitor_app/widgets/common/markdown_text_widget.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  final HealthDataService _healthDataService = HealthDataService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  HealthDataModel? _latestHealthData;

  @override
  void initState() {
    super.initState();
    _loadLatestHealthData();
    _addWelcomeMessage();
  }

  Future<void> _loadLatestHealthData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await _healthDataService.getLatestHealthData(user.uid);
      setState(() {
        _latestHealthData = data;
      });
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: '''Hello! I'm your AI health assistant. 🤖

I can help you with:
- Understanding your vitals
- Managing side effects
- General health guidance

How can I assist you today?''',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final aiResponse = await _chatbotService.getResponse(
        userMessage,
        latestHealthData: _latestHealthData,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Sorry, I encountered an error. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Ensure background color is set
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.smart_toy),
            SizedBox(width: 8),
            Text('AI Health Assistant'),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 215, 123, 231),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Warning Banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.orange[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.orange[900]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is an AI assistant. Always consult your doctor for medical decisions.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color.fromARGB(255, 255, 123, 51), 
                      fontSize: 12
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),

          // Typing Indicator
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(left: 20, bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.purple[100],
                    child: Icon(Icons.smart_toy, color: Colors.purple, size: 18),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'AI is typing...',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          // Message Input Area
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask about your health...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 235, 150, 250),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    // Calculate width limit (75% of screen width)
    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI Icon (Left Side)
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple[100],
              child: Icon(Icons.smart_toy, color: const Color.fromARGB(255, 209, 131, 222), size: 18),
            ),
            SizedBox(width: 8),
          ],

          // Chat Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.purple : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: message.isUser ? Radius.circular(20) : Radius.circular(4),
                  bottomRight: message.isUser ? Radius.circular(4) : Radius.circular(20),
                ),
                boxShadow: [
                  if (!message.isUser)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isUser)
                    MarkdownTextWidget(
                      text: message.text,
                      textColor: AppColors.textPrimary,
                    )
                  else
                    Text(
                      message.text,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    ),
                  
                  SizedBox(height: 4),
                  
                  // Timestamp
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      DateFormat('hh:mm a').format(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: message.isUser ? Colors.white70 : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}