import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/chatbot_service.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:intl/intl.dart';

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
  final FocusNode _focusNode = FocusNode();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  HealthDataModel? _latestHealthData;

  @override
  void initState() {
    super.initState();
    _loadLatestHealthData();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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
        text: 'Hello! I am your AI health assistant.\n\nI can help you with:\n• Understanding your vital signs\n• Managing side effects\n• General health guidance\n• When to contact your doctor\n\nHow can I assist you today?',
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
    
    final summary = '''Latest Health Summary ($timestamp)

Risk Level: ${riskLevel.toUpperCase()}
Heart Rate: ${data.heartRate} bpm
SpO2 Level: ${data.spo2Level}%
Temperature: ${data.temperature.toStringAsFixed(1)}°C
Blood Pressure: ${data.systolicBP}/${data.diastolicBP} mmHg

${_getRiskAdvice(data.riskLevel)}''';
    
    _addSystemMessage(summary);
  }

  String _getRiskAdvice(int? riskLevel) {
    switch (riskLevel) {
      case 0:
        return 'You are in the normal range. Continue with your regular monitoring schedule.';
      case 1:
        return 'Moderate risk detected. Please rest and monitor your symptoms. Contact your doctor if symptoms persist.';
      case 2:
        return 'High risk detected. Please seek immediate medical attention.';
      default:
        return 'Please consult with your healthcare provider for personalized advice.';
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
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.wisteriaBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 20,
              ),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.wisteriaBlue,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Warning Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.riskModerateBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(
                color: AppColors.riskModerate.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppColors.riskModerate,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI assistant for guidance only. Always consult your doctor for medical decisions.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionButton(
                    icon: Icons.health_and_safety_rounded,
                    label: 'Health Summary',
                    onPressed: _showHealthSummary,
                    color: AppColors.wisteriaBlue,
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    icon: Icons.medical_services_rounded,
                    label: 'Side Effects',
                    onPressed: () {
                      _messageController.text = 'What should I do about side effects?';
                      _sendMessage();
                    },
                    color: AppColors.frozenWater,
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    icon: Icons.contact_support_rounded,
                    label: 'When to Call',
                    onPressed: () {
                      _messageController.text = 'When should I contact my doctor?';
                      _sendMessage();
                    },
                    color: AppColors.pastelPetal,
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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.wisteriaBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
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
              boxShadow: AppShadows.elevation1,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Ask about your health...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.wisteriaBlue,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppShadows.buttonShadow,
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
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

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.wisteriaBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Chat Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: message.isUser 
                    ? const EdgeInsets.only(left: 40) 
                    : const EdgeInsets.only(right: 40),
                decoration: BoxDecoration(
                  color: message.isUser ? AppColors.wisteriaBlue : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: message.isUser 
                        ? const Radius.circular(20) 
                        : const Radius.circular(4),
                    bottomRight: message.isUser 
                        ? const Radius.circular(4) 
                        : const Radius.circular(20),
                  ),
                  boxShadow: AppShadows.elevation1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message Text
                    SelectableText(
                      message.text,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: message.isUser ? Colors.white : AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.pastelPetal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}