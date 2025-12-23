import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/chatbot_service.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:intl/intl.dart';
import 'package:chemo_monitor_app/widgets/common/markdown_text_widget.dart';
import 'package:chemo_monitor_app/widgets/common/glass_card.dart';
import 'package:chemo_monitor_app/widgets/common/glass_button.dart';

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

  void _showHealthSummary() {
    if (_latestHealthData == null) {
      _addSystemMessage('No recent health data available. Please check back after your next reading.');
      return;
    }
    
    final data = _latestHealthData!;
    final riskLevel = data.getRiskLevelString();
    final timestamp = DateFormat('MMM dd, hh:mm a').format(data.timestamp);
    
    final summary = '''
📊 **Latest Health Summary** ($timestamp)

**Risk Level:** ${riskLevel.toUpperCase()}
**Heart Rate:** ${data.heartRate} bpm
**SpO₂ Level:** ${data.spo2Level}%
**Temperature:** ${data.temperature.toStringAsFixed(1)}°C
**Blood Pressure:** ${data.systolicBP}/${data.diastolicBP} mmHg

${_getRiskAdvice(data.riskLevel)}
''';
    
    _addSystemMessage(summary);
  }

  String _getRiskAdvice(int? riskLevel) {
    switch (riskLevel) {
      case 0:
        return '✅ You are in the normal range. Continue with your regular monitoring schedule.';
      case 1:
        return '⚠️ Moderate risk detected. Please rest and monitor your symptoms. Contact your doctor if symptoms persist.';
      case 2:
        return '🚨 High risk detected. Please seek immediate medical attention.';
      default:
        return '📋 Please consult with your healthcare provider for personalized advice.';
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // Check for quick actions
    if (userMessage.toLowerCase().contains('summary') || 
        userMessage.toLowerCase().contains('vitals')) {
      _showHealthSummary();
      return;
    }

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

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Row(
          children: [
            GlassCard(
              padding: const EdgeInsets.all(4),
              blurSigma: 5,
              child: Icon(Icons.smart_toy_rounded, color: AppColors.primaryBlue, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Health Assistant',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Warning Banner (Glassmorphism style)
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 20, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI assistant for guidance only. Always consult your doctor for medical decisions.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GlassButton(
                    onPressed: _showHealthSummary,
                    child: const Row(
                      children: [
                        Icon(Icons.health_and_safety_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Health Summary'),
                      ],
                    ),
                    type: ButtonType.secondary,
                    height: 36,
                  ),
                  const SizedBox(width: 8),
                  GlassButton(
                    onPressed: () {
                      _messageController.text = 'What should I do about side effects?';
                      _sendMessage();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.medical_services_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Side Effects'),
                      ],
                    ),
                    type: ButtonType.secondary,
                    height: 36,
                  ),
                  const SizedBox(width: 8),
                  GlassButton(
                    onPressed: () {
                      _messageController.text = 'When should I contact my doctor?';
                      _sendMessage();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.contact_support_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('When to Call'),
                      ],
                    ),
                    type: ButtonType.secondary,
                    height: 36,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),

          // Typing Indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 10),
              child: Row(
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(6),
                    blurSigma: 5,
                    child: Icon(Icons.smart_toy_rounded, color: AppColors.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI is thinking...',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          // Message Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ask about your health...',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GlassButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    type: ButtonType.primary,
                    height: 48,
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
    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI Icon (Left Side)
          if (!message.isUser) ...[
            GlassCard(
              padding: const EdgeInsets.all(6),
              blurSigma: 5,
              child: Icon(Icons.smart_toy_rounded, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 8),
          ],

          // Chat Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                margin: message.isUser ? const EdgeInsets.only(left: 40) : const EdgeInsets.only(right: 40),
                color: message.isUser ? AppColors.primaryBlue.withOpacity(0.8) : Colors.white,
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
                    
                    const SizedBox(height: 4),
                    
                    // Timestamp
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        DateFormat('hh:mm a').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: message.isUser ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // User Icon (Right Side)
          if (message.isUser) ...[
            const SizedBox(width: 8),
            GlassCard(
              padding: const EdgeInsets.all(6),
              blurSigma: 5,
              child: Icon(Icons.person_rounded, color: AppColors.softPurple, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}