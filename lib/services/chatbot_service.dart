import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatbotService {
  static const String apiUrl = 'https://api.mistral.ai/v1/chat/completions';
  static String get apiKey => dotenv.env['MISTRAL_API_KEY'] ?? '';

  // Track conversation context
  final List<Map<String, String>> _conversationHistory = [];

  /// Enhanced AI response with context awareness
  Future<String> getResponse(String userMessage, {HealthDataModel? latestHealthData}) async {
    try {
      // 🛡️ STEP 1: Validate user input (block garbage text)
      if (!_isValidHealthQuery(userMessage)) {
        return _getInvalidInputResponse(userMessage);
      }

      // 🧠 STEP 2: Build intelligent context
      String context = _buildSmartHealthContext(latestHealthData);
      
      // 📝 STEP 3: Create clear, formatted system prompt
      String systemPrompt = _getSystemPrompt();
      
      // 💬 STEP 4: Build conversation with history
      List<Map<String, String>> messages = [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': '$context\n\nPatient: $userMessage'},
      ];

      // Add recent conversation history (last 3 exchanges)
      if (_conversationHistory.length > 0) {
        messages.insertAll(1, _conversationHistory.take(6).toList());
      }

      // 🚀 STEP 5: Call API with clean formatting instructions
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'mistral-small-latest',
          'messages': messages,
          'max_tokens': 400,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['choices'][0]['message']['content'];
        
        // 🧹 STEP 6: Clean and format response
        aiResponse = _cleanAIResponse(aiResponse);
        
        // 📚 Save to conversation history
        _conversationHistory.insert(0, {'role': 'user', 'content': userMessage});
        _conversationHistory.insert(0, {'role': 'assistant', 'content': aiResponse});
        
        // Keep only last 6 messages (3 exchanges)
        if (_conversationHistory.length > 6) {
          _conversationHistory.removeRange(6, _conversationHistory.length);
        }
        
        return aiResponse;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return _getFallbackResponse(userMessage, latestHealthData);
      }
    } catch (e) {
      print('Chatbot error: $e');
      return _getFallbackResponse(userMessage, latestHealthData);
    }
  }

  /// 🛡️ Validate if the message is a valid health-related query
  bool _isValidHealthQuery(String message) {
    String msg = message.toLowerCase().trim();
    
    // Block gibberish (less than 3 chars or only special characters)
    if (msg.length < 3) return false;
    if (RegExp(r'^[^a-z0-9\s]+$').hasMatch(msg)) return false;
    
    // Block obvious gibberish patterns
    if (RegExp(r'^[a-z]{1,2}(\s*[a-z]{1,2}){5,}$').hasMatch(msg)) return false;
    
    // Accept greetings
    List<String> greetings = ['hi', 'hello', 'hey', 'good morning', 'good evening'];
    if (greetings.any((g) => msg.startsWith(g))) return true;
    
    // Accept health-related keywords
    List<String> healthKeywords = [
      'health', 'pain', 'nausea', 'vomit', 'fever', 'temperature', 'tired',
      'fatigue', 'sick', 'dizzy', 'weak', 'sleep', 'appetite', 'eat',
      'medicine', 'medication', 'doctor', 'symptom', 'feeling', 'help',
      'what', 'how', 'when', 'should', 'can', 'is', 'vitals', 'blood'
    ];
    
    return healthKeywords.any((keyword) => msg.contains(keyword)) || msg.split(' ').length >= 2;
  }

  /// 🚫 Response for invalid input
  String _getInvalidInputResponse(String message) {
    return '''I'm here to help with your health concerns during chemotherapy treatment.

I can assist you with:
• Managing side effects
• Understanding your vitals
• General health guidance
• When to contact your doctor

Please ask a clear health-related question, and I'll be happy to help! 😊''';
  }

  /// 🧠 Build intelligent health context
  String _buildSmartHealthContext(HealthDataModel? data) {
    if (data == null) {
      return '''[Patient Health Status]
No recent health data recorded yet.
Suggestion: Encourage patient to log vitals regularly.''';
    }
    
    // Analyze vitals and provide context
    String analysis = _analyzeVitals(data);
    
    return '''[Current Health Status - ${_getTimeAgo(data.timestamp)}]
Vitals:
• Heart Rate: ${data.heartRate} bpm ${_getVitalStatus(data.heartRate, 60, 100)}
• SpO2: ${data.spo2Level}% ${_getVitalStatus(data.spo2Level, 95, 100)}
• Blood Pressure: ${data.systolicBP}/${data.diastolicBP} mmHg ${_getBPStatus(data.systolicBP, data.diastolicBP)}
• Temperature: ${data.temperature}°C ${_getTempStatus(data.temperature)}
• AI Risk Level: ${data.getRiskLevelString()}

$analysis''';
  }

  /// 📊 Analyze vitals and provide context
  String _analyzeVitals(HealthDataModel data) {
    List<String> concerns = [];
    List<String> normal = [];
    
    if (data.heartRate > 100) concerns.add('Elevated heart rate');
    else if (data.heartRate < 60) concerns.add('Low heart rate');
    else normal.add('Heart rate is normal');
    
    if (data.spo2Level < 95) concerns.add('Low oxygen saturation');
    else normal.add('Oxygen level is good');
    
    if (data.systolicBP > 140 || data.diastolicBP > 90) concerns.add('High blood pressure');
    else if (data.systolicBP < 90) concerns.add('Low blood pressure');
    else normal.add('Blood pressure is normal');
    
    if (data.temperature > 38.0) concerns.add('Fever detected - URGENT');
    else if (data.temperature < 36.0) concerns.add('Low body temperature');
    else normal.add('Temperature is normal');
    
    if (concerns.isEmpty) {
      return '[Status: Stable]\nAll vitals are within normal ranges.';
    } else {
      return '[Status: Attention Needed]\nConcerns: ${concerns.join(", ")}';
    }
  }

  /// ✅ Get vital status emoji
  String _getVitalStatus(num value, num min, num max) {
    if (value < min) return '⬇️ Low';
    if (value > max) return '⬆️ High';
    return '✅ Normal';
  }

  String _getBPStatus(int systolic, int diastolic) {
    if (systolic > 140 || diastolic > 90) return '⬆️ High';
    if (systolic < 90) return '⬇️ Low';
    return '✅ Normal';
  }

  String _getTempStatus(double temp) {
    if (temp > 38.0) return '🔥 High - Urgent';
    if (temp < 36.0) return '❄️ Low';
    return '✅ Normal';
  }

  /// 🕐 Get human-readable time ago
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  /// 📋 Get clear system prompt (no markdown instructions)
  String _getSystemPrompt() {
    return '''You are a compassionate medical AI assistant for chemotherapy patients.

YOUR ROLE:
- Provide supportive, easy-to-understand health guidance
- Be empathetic and encouraging
- Never diagnose or prescribe medication
- Always recommend consulting their doctor for medical decisions

RESPONSE FORMAT (VERY IMPORTANT):
- Use simple paragraphs with line breaks
- Use bullet points with • symbol (not - or *)
- NO markdown formatting (no **, ##, or ###)
- Use emojis sparingly for clarity (✅, ⚠️, 💊, 🩺)
- Keep responses concise (3-5 short paragraphs maximum)
- Always end with: "⚠️ Always consult your doctor for medical decisions."

TONE:
- Warm and supportive
- Clear and simple language
- Hopeful but realistic
- Professional but friendly''';
  }

  /// 🧹 Clean AI response from unwanted formatting
  String _cleanAIResponse(String response) {
    // Remove markdown formatting
    response = response.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1'); // Bold
    response = response.replaceAll(RegExp(r'\*(.*?)\*'), r'$1'); // Italic
    response = response.replaceAll(RegExp(r'#{1,6}\s'), ''); // Headers
    response = response.replaceAll(RegExp(r'`{1,3}.*?`{1,3}'), ''); // Code
    
    // Clean up multiple newlines
    response = response.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // Replace markdown lists with bullet points
    response = response.replaceAll(RegExp(r'^\s*[-*]\s', multiLine: true), '• ');
    
    return response.trim();
  }

  /// 🆘 Smart fallback based on keywords
  String _getFallbackResponse(String message, HealthDataModel? data) {
    String msg = message.toLowerCase();
    
    // Context-aware greeting
    if (msg.contains('hi') || msg.contains('hello') || msg.contains('hey')) {
      String greeting = data != null 
        ? 'Hello! I see your latest vitals show ${data.getRiskLevelString().toLowerCase()} risk. How can I help you today?'
        : 'Hello! How can I assist you with your health today?';
      
      return '''$greeting

I can help you with:
• Managing chemotherapy side effects
• Understanding your vital signs
• General health guidance
• When to contact your doctor

Feel free to ask any health-related questions! 😊

⚠️ Always consult your doctor for medical decisions.''';
    }
    
    // Nausea & Vomiting
    if (msg.contains('nausea') || msg.contains('vomit') || msg.contains('sick')) {
      return '''Managing Nausea During Chemotherapy:

Here are some helpful tips:

• Eat small, frequent meals throughout the day
• Stay hydrated with clear fluids
• Avoid strong smells and spicy foods
• Try ginger tea or peppermint
• Rest in a comfortable position after eating
• Keep your room well-ventilated

When to Contact Your Doctor:
• Vomiting more than 3 times in 24 hours
• Unable to keep fluids down
• Signs of dehydration (dark urine, dizziness)
• Persistent nausea despite medication

⚠️ Always consult your doctor for medical decisions.''';
    }
    
    // Fatigue
    if (msg.contains('tired') || msg.contains('fatigue') || msg.contains('weak') || msg.contains('energy')) {
      return '''Managing Fatigue:

Fatigue is very common during chemotherapy. Here's what can help:

• Rest when you need to, but stay gently active
• Take short walks if you feel up to it
• Maintain a regular sleep schedule
• Stay hydrated throughout the day
• Eat nutritious, energy-boosting foods
• Ask for help with daily tasks

When to Contact Your Doctor:
• Fatigue prevents you from daily activities
• Accompanied by chest pain or shortness of breath
• Feeling extremely weak or dizzy

⚠️ Always consult your doctor for medical decisions.''';
    }
    
    // Fever - URGENT
    if (msg.contains('fever') || msg.contains('hot') || msg.contains('temperature')) {
      return '''🔥 FEVER ALERT - This Requires Immediate Attention!

If your temperature is above 38°C (100.4°F):

⚠️ CONTACT YOUR DOCTOR IMMEDIATELY

Why This Is Serious:
• Fever during chemotherapy can indicate infection
• Your immune system is weakened
• Infections can become serious quickly

What to Do Right Now:
• Take your temperature every hour
• Do NOT take fever medication without doctor approval
• Keep a record of temperature readings
• Stay hydrated
• Rest and monitor symptoms

Do NOT Wait - Call your doctor or go to emergency if:
• Temperature above 38°C (100.4°F)
• Shaking or chills
• Confusion or dizziness

⚠️ Always consult your doctor for medical decisions.''';
    }
    
    // Pain
    if (msg.contains('pain') || msg.contains('hurt') || msg.contains('ache')) {
      return '''Managing Pain:

Pain management is an important part of your care.

What You Can Do:
• Take prescribed pain medication as directed
• Use heat or cold packs (check with doctor first)
• Try gentle stretching or relaxation techniques
• Maintain good posture
• Distract yourself with activities you enjoy

When to Contact Your Doctor:
• Severe or sudden pain
• Pain not relieved by medication
• New or different type of pain
• Pain accompanied by fever or swelling

Remember: There's no need to "tough it out" - effective pain management helps you feel better and heal.

⚠️ Always consult your doctor for medical decisions.''';
    }
    
    // Default helpful response
    return '''I'm here to support you through your chemotherapy journey.

I can provide guidance on:
• Managing common side effects (nausea, fatigue, pain)
• Understanding your vital signs
• When to contact your doctor
• General health tips during treatment

What would you like to know about? Feel free to ask specific questions about your symptoms or health concerns.

⚠️ Always consult your doctor for medical decisions.''';
  }

  /// Clear conversation history (optional - for new sessions)
  void clearHistory() {
    _conversationHistory.clear();
  }
}