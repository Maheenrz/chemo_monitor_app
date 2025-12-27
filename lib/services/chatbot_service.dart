import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';
class ChatbotService {
  static const String apiUrl = 'https://api.mistral.ai/v1/chat/completions';
  static String get apiKey => dotenv.env['MISTRAL_API_KEY'] ?? '';

  // Track conversation context
  final List<Map<String, String>> _conversationHistory = [];

  /// Enhanced AI response with ML prediction awareness
  Future<String> getResponse(String userMessage, {HealthDataModel? latestHealthData}) async {
  print('\n🚀 ═══════════════════════════════════════');
  print('🚀 CHATBOT DEBUG START');
  print('🚀 ═══════════════════════════════════════');
  print('📝 User Message: "$userMessage"');
  print('🔑 API Key Present: ${apiKey.isNotEmpty}');
  print('🔑 API Key Length: ${apiKey.length}');
  print('🔑 API Key Preview: ${apiKey.substring(0, min(10, apiKey.length))}...');
  print('📊 Health Data: ${latestHealthData != null ? "YES (Risk: ${latestHealthData.riskLevel})" : "NO"}');
  
  try {
    // STEP 0: Check API key
    if (apiKey.isEmpty) {
      print('❌ FATAL: API Key is empty!');
      return '❌ Configuration Error: API key not found.';
    }

    // STEP 1: Validate user input
    print('🔍 Validating input...');
    if (!_isValidHealthQuery(userMessage)) {
      print('⚠️ Invalid query rejected');
      return _getInvalidInputResponse();
    }
    print('✅ Input valid');

    // STEP 2: Build messages
    print('📦 Building messages...');
    List<Map<String, String>> messages = [
      {
        'role': 'system',
        'content': _getEnhancedSystemPrompt(latestHealthData),
      },
    ];

    if (_conversationHistory.isNotEmpty) {
      messages.addAll(_conversationHistory.take(6).toList());
      print('📜 Added ${_conversationHistory.take(6).length} history messages');
    }

    messages.add({
      'role': 'user',
      'content': userMessage,
    });
    
    print('✅ Total messages: ${messages.length}');

    // STEP 3: Prepare API request
    final requestBody = {
      'model': 'mistral-small-latest',
      'messages': messages,
      'max_tokens': 500,
      'temperature': 0.7,
    };

    print('📤 ═══════════════════════════════════════');
    print('📤 Sending to Mistral API...');
    print('📤 URL: $apiUrl');
    print('📤 Model: mistral-small-latest');
    print('📤 ═══════════════════════════════════════');

    // STEP 4: Make API call with timeout
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        print('⏱️ REQUEST TIMEOUT after 30 seconds');
        throw Exception('Request timeout');
      },
    );

    print('📥 ═══════════════════════════════════════');
    print('📥 Response received!');
    print('📥 Status Code: ${response.statusCode}');
    print('📥 Status: ${response.statusCode == 200 ? "SUCCESS ✅" : "ERROR ❌"}');
    print('📥 Body Length: ${response.body.length} characters');
    print('📥 ═══════════════════════════════════════');

    if (response.statusCode == 200) {
      print('✅ Parsing response...');
      print('📄 Raw response preview: ${response.body.substring(0, min(300, response.body.length))}...');
      
      final data = jsonDecode(response.body);
      
      // Validate response structure
      if (data['choices'] == null) {
        print('❌ ERROR: No "choices" field in response');
        print('❌ Full response: ${response.body}');
        return _getFallbackResponse(userMessage, latestHealthData);
      }
      
      if (data['choices'].isEmpty) {
        print('❌ ERROR: "choices" array is empty');
        return _getFallbackResponse(userMessage, latestHealthData);
      }
      
      if (data['choices'][0]['message'] == null) {
        print('❌ ERROR: No "message" in first choice');
        return _getFallbackResponse(userMessage, latestHealthData);
      }
      
      if (data['choices'][0]['message']['content'] == null) {
        print('❌ ERROR: No "content" in message');
        return _getFallbackResponse(userMessage, latestHealthData);
      }
      
      String aiResponse = data['choices'][0]['message']['content'];
      print('✅ AI Response extracted!');
      print('📝 Response length: ${aiResponse.length} characters');
      print('📝 Response preview: ${aiResponse.substring(0, min(150, aiResponse.length))}...');
      
      // Clean response
      print('🧹 Cleaning response...');
      aiResponse = _cleanAIResponse(aiResponse);
      print('✅ Response cleaned (${aiResponse.length} chars after cleaning)');
      
      // Save to history
      _conversationHistory.insert(0, {'role': 'user', 'content': userMessage});
      _conversationHistory.insert(0, {'role': 'assistant', 'content': aiResponse});
      
      if (_conversationHistory.length > 6) {
        _conversationHistory.removeRange(6, _conversationHistory.length);
      }
      print('💾 Saved to conversation history');
      
      print('🚀 ═══════════════════════════════════════');
      print('🚀 CHATBOT DEBUG END - SUCCESS ✅');
      print('🚀 ═══════════════════════════════════════\n');
      return aiResponse;
      
    } else {
      // API returned error
      print('❌ ═══════════════════════════════════════');
      print('❌ API ERROR DETAILS:');
      print('❌ Status Code: ${response.statusCode}');
      print('❌ Status Message: ${response.reasonPhrase}');
      print('❌ Error Body: ${response.body}');
      print('❌ ═══════════════════════════════════════');
      
      // Common error codes
      switch (response.statusCode) {
        case 401:
          print('💡 HINT: Invalid API key (401 Unauthorized)');
          break;
        case 429:
          print('💡 HINT: Rate limit exceeded (429 Too Many Requests)');
          break;
        case 500:
          print('💡 HINT: Mistral server error (500 Internal Server Error)');
          break;
        case 503:
          print('💡 HINT: Service unavailable (503)');
          break;
      }
      
      print('🚀 CHATBOT DEBUG END - API ERROR ❌\n');
      return _getFallbackResponse(userMessage, latestHealthData);
    }
    
  } catch (e, stackTrace) {
    print('💥 ═══════════════════════════════════════');
    print('💥 EXCEPTION CAUGHT!');
    print('💥 ═══════════════════════════════════════');
    print('❌ Error Type: ${e.runtimeType}');
    print('❌ Error Message: $e');
    print('📚 Stack Trace:');
    print(stackTrace.toString().split('\n').take(10).join('\n'));
    print('💥 ═══════════════════════════════════════');
    print('🚀 CHATBOT DEBUG END - EXCEPTION ❌\n');
    return _getFallbackResponse(userMessage, latestHealthData);
  }
}
  /// ✅ ENHANCED SYSTEM PROMPT - References health data explicitly
  String _getEnhancedSystemPrompt(HealthDataModel? healthData) {
    String basePrompt = '''You are a compassionate medical AI assistant for chemotherapy patients.

YOUR PRIMARY ROLE:
- Provide personalized guidance based on the patient's CURRENT health data
- Reference their actual vital signs and risk level in your responses
- Be empathetic, supportive, and encouraging
- Never diagnose or prescribe medication
- Always recommend consulting their doctor for medical decisions''';

    if (healthData == null) {
      return '''$basePrompt

PATIENT STATUS: No recent health data recorded
GUIDANCE: Encourage patient to log their vitals regularly for personalized support.

RESPONSE FORMAT:
- Use simple paragraphs with line breaks
- Use bullet points with • symbol
- NO markdown formatting (no **, ##, or ###)
- Keep responses concise (3-5 short paragraphs)
- Always end with: "Always consult your doctor for medical decisions."''';
    }

    // ✅ BUILD DETAILED HEALTH CONTEXT
    String riskStatus = _getRiskDescription(healthData.riskLevel);
    String vitalAnalysis = _buildDetailedVitalAnalysis(healthData);
    String recommendations = _buildPersonalizedRecommendations(healthData);

    return '''$basePrompt

═══════════════════════════════════════
PATIENT'S CURRENT HEALTH DATA (CRITICAL - USE THIS IN YOUR RESPONSE):
═══════════════════════════════════════

🚨 ML RISK PREDICTION: ${riskStatus.toUpperCase()}
⏰ Recorded: ${_getTimeAgo(healthData.timestamp)}

📊 VITAL SIGNS:
• Heart Rate: ${healthData.heartRate} bpm ${_getVitalFlag(healthData.heartRate, 60, 100, 'HR')}
• Oxygen Level (SpO2): ${healthData.spo2Level}% ${_getVitalFlag(healthData.spo2Level, 95, 100, 'SpO2')}
• Blood Pressure: ${healthData.systolicBP}/${healthData.diastolicBP} mmHg ${_getBPFlag(healthData.systolicBP, healthData.diastolicBP)}
• Body Temperature: ${healthData.temperature.toStringAsFixed(1)}°C ${_getTempFlag(healthData.temperature)}

$vitalAnalysis

$recommendations

═══════════════════════════════════════

CRITICAL INSTRUCTIONS:
1. ALWAYS reference the patient's actual vitals in your response
2. If their risk is MODERATE or HIGH, express appropriate concern
3. If vitals are abnormal, explain what this means for them
4. Provide specific advice based on their current readings
5. If fever detected (>38°C) or HIGH RISK, emphasize urgency

RESPONSE FORMAT:
- Start by acknowledging their current health status
- Use their actual numbers when discussing vitals
- Provide actionable advice based on their situation
- Use simple paragraphs with line breaks
- Use bullet points with • symbol
- NO markdown formatting (no **, ##, or ###)
- Keep responses concise but informative
- Always end with: "Always consult your doctor for medical decisions."

TONE:
- Warm and supportive
- Clear and simple language
- Appropriately urgent if risk is high
- Professional but friendly''';
  }

  /// Get risk description
  String _getRiskDescription(int? riskLevel) {
    switch (riskLevel) {
      case 0:
        return 'LOW RISK - Stable condition';
      case 1:
        return 'MODERATE RISK - Requires attention';
      case 2:
        return 'HIGH RISK - Needs immediate medical attention';
      default:
        return 'UNKNOWN';
    }
  }

  /// Build detailed vital analysis
  String _buildDetailedVitalAnalysis(HealthDataModel data) {
    List<String> concerns = [];
    List<String> normal = [];
    
    // Heart Rate
    if (data.heartRate > 100) {
      concerns.add('⚠️ ELEVATED HEART RATE (${data.heartRate} bpm) - Tachycardia detected');
    } else if (data.heartRate < 60) {
      concerns.add('⚠️ LOW HEART RATE (${data.heartRate} bpm) - Bradycardia detected');
    } else {
      normal.add('✓ Heart rate normal (${data.heartRate} bpm)');
    }
    
    // Oxygen
    if (data.spo2Level < 95) {
      concerns.add('⚠️ LOW OXYGEN SATURATION (${data.spo2Level}%) - Hypoxemia detected');
    } else {
      normal.add('✓ Oxygen level good (${data.spo2Level}%)');
    }
    
    // Blood Pressure
    if (data.systolicBP > 140 || data.diastolicBP > 90) {
      concerns.add('⚠️ HIGH BLOOD PRESSURE (${data.systolicBP}/${data.diastolicBP}) - Hypertension');
    } else if (data.systolicBP < 90) {
      concerns.add('⚠️ LOW BLOOD PRESSURE (${data.systolicBP}/${data.diastolicBP}) - Hypotension');
    } else {
      normal.add('✓ Blood pressure normal (${data.systolicBP}/${data.diastolicBP})');
    }
    
    // Temperature
    if (data.temperature > 38.0) {
      concerns.add('🚨 FEVER DETECTED (${data.temperature.toStringAsFixed(1)}°C) - URGENT!');
    } else if (data.temperature < 36.0) {
      concerns.add('⚠️ LOW BODY TEMPERATURE (${data.temperature.toStringAsFixed(1)}°C)');
    } else {
      normal.add('✓ Temperature normal (${data.temperature.toStringAsFixed(1)}°C)');
    }
    
    String analysis = '🔍 ANALYSIS:\n';
    
    if (concerns.isNotEmpty) {
      analysis += 'CONCERNS:\n${concerns.join('\n')}\n';
    }
    
    if (normal.isNotEmpty) {
      analysis += '\nNORMAL READINGS:\n${normal.join('\n')}';
    }
    
    return analysis;
  }

  /// Build personalized recommendations
  String _buildPersonalizedRecommendations(HealthDataModel data) {
    List<String> recommendations = [];
    
    if (data.riskLevel == 2) {
      recommendations.add('🚨 HIGH RISK: Recommend immediate medical consultation');
    } else if (data.riskLevel == 1) {
      recommendations.add('⚠️ MODERATE RISK: Suggest rest and continued monitoring');
    } else {
      recommendations.add('✓ LOW RISK: Continue regular monitoring');
    }
    
    if (data.temperature > 38.0) {
      recommendations.add('🌡️ FEVER: This is an emergency during chemotherapy - contact doctor immediately');
    }
    
    if (data.heartRate > 100) {
      recommendations.add('💓 ELEVATED HR: Patient should rest and stay hydrated');
    }
    
    if (data.spo2Level < 95) {
      recommendations.add('🫁 LOW O2: Patient may need supplemental oxygen - urgent doctor visit');
    }
    
    if (recommendations.isEmpty) {
      return '💡 RECOMMENDATIONS: Patient is stable, continue regular monitoring';
    }
    
    return '💡 PERSONALIZED RECOMMENDATIONS:\n${recommendations.join('\n')}';
  }

  /// Get vital flag
  String _getVitalFlag(num value, num min, num max, String type) {
    if (value < min) return '⚠️ LOW';
    if (value > max) return '⚠️ HIGH';
    return '✓ Normal';
  }

  String _getBPFlag(int systolic, int diastolic) {
    if (systolic > 140 || diastolic > 90) return '⚠️ HIGH';
    if (systolic < 90) return '⚠️ LOW';
    return '✓ Normal';
  }

  String _getTempFlag(double temp) {
    if (temp > 38.0) return '🚨 FEVER - URGENT!';
    if (temp < 36.0) return '⚠️ LOW';
    return '✓ Normal';
  }

  /// Get human-readable time ago
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays} days ago';
  }

  /// Validate if the message is a valid health-related query
  bool _isValidHealthQuery(String message) {
    String msg = message.toLowerCase().trim();
    
    // Block gibberish (less than 3 chars or only special characters)
    if (msg.length < 2) return false;
    if (RegExp(r'^[^a-z0-9\s]+$').hasMatch(msg)) return false;
    
    // Accept greetings
    List<String> greetings = ['hi', 'hello', 'hey', 'good morning', 'good evening', 'help'];
    if (greetings.any((g) => msg.startsWith(g))) return true;
    
    // Accept health-related keywords
    List<String> healthKeywords = [
      'health', 'pain', 'nausea', 'vomit', 'fever', 'temperature', 'tired',
      'fatigue', 'sick', 'dizzy', 'weak', 'sleep', 'appetite', 'eat',
      'medicine', 'medication', 'doctor', 'symptom', 'feeling', 'help',
      'what', 'how', 'when', 'should', 'can', 'is', 'vitals', 'blood',
      'risk', 'concern', 'worry', 'advice', 'recommendation'
    ];
    
    return healthKeywords.any((keyword) => msg.contains(keyword)) || msg.split(' ').length >= 2;
  }

  /// Response for invalid input
  String _getInvalidInputResponse() {
    return '''I am here to help with your health concerns during chemotherapy treatment.

I can assist you with:
• Understanding your vital signs and ML risk prediction
• Managing side effects
• General health guidance
• When to contact your doctor

Please ask a clear health-related question, and I will be happy to help.''';
  }

  /// Clean AI response from unwanted formatting
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
    
    // Remove any separator lines
    response = response.replaceAll(RegExp(r'═+'), '');
    response = response.replaceAll(RegExp(r'─+'), '');
    
    return response.trim();
  }

  /// Smart fallback based on keywords and health data
  String _getFallbackResponse(String message, HealthDataModel? data) {
    String msg = message.toLowerCase();
    
    // Build health-aware greeting
    String healthStatus = '';
    if (data != null) {
      String risk = data.getRiskLevelString().toLowerCase();
      healthStatus = '\n\nYour latest health check shows $risk risk. ';
      
      if (data.riskLevel == 2) {
        healthStatus += '🚨 This requires immediate medical attention!';
      } else if (data.riskLevel == 1) {
        healthStatus += '⚠️ Please monitor your symptoms closely.';
      } else {
        healthStatus += '✓ Your vitals are stable.';
      }
    }
    
    // Context-aware greeting
    if (msg.contains('hi') || msg.contains('hello') || msg.contains('hey')) {
      return '''Hello! I am your AI health assistant.$healthStatus

I can help you with:
• Understanding your vital signs and risk level
• Managing chemotherapy side effects
• General health guidance
• When to contact your doctor

What would you like to know?

Always consult your doctor for medical decisions.''';
    }
    
    // Nausea & Vomiting
    if (msg.contains('nausea') || msg.contains('vomit') || msg.contains('sick')) {
      String riskNote = data?.riskLevel == 2 
          ? '\n\n🚨 Note: Your current risk level is HIGH. Please contact your doctor immediately if vomiting persists.'
          : '';
      
      return '''Managing Nausea During Chemotherapy:

Here are some helpful tips:

• Eat small, frequent meals throughout the day
• Stay hydrated with clear fluids (water, ginger tea)
• Avoid strong smells and spicy foods
• Try ginger tea or peppermint
• Rest in a comfortable position after eating
• Keep your room well-ventilated

When to Contact Your Doctor:
• Vomiting more than 3 times in 24 hours
• Unable to keep fluids down
• Signs of dehydration (dark urine, dizziness)
• Persistent nausea despite medication$riskNote

Always consult your doctor for medical decisions.''';
    }
    
    // Fatigue
    if (msg.contains('tired') || msg.contains('fatigue') || msg.contains('weak') || msg.contains('energy')) {
      String heartRateNote = '';
      if (data != null && (data.heartRate > 100 || data.heartRate < 60)) {
        heartRateNote = '\n\n⚠️ Your heart rate (${data.heartRate} bpm) is ${data.heartRate > 100 ? "elevated" : "low"}. Please rest and monitor your symptoms.';
      }
      
      return '''Managing Fatigue:

Fatigue is very common during chemotherapy. Here is what can help:

• Rest when you need to, but stay gently active
• Take short walks if you feel up to it
• Maintain a regular sleep schedule
• Stay hydrated throughout the day
• Eat nutritious, energy-boosting foods
• Ask for help with daily tasks

When to Contact Your Doctor:
• Fatigue prevents you from daily activities
• Accompanied by chest pain or shortness of breath
• Feeling extremely weak or dizzy$heartRateNote

Always consult your doctor for medical decisions.''';
    }
    
    // Fever - URGENT
    if (msg.contains('fever') || msg.contains('hot') || msg.contains('temperature')) {
      String tempWarning = '';
      if (data != null && data.temperature > 38.0) {
        tempWarning = '\n\n🚨 URGENT: Your recorded temperature is ${data.temperature.toStringAsFixed(1)}°C - This is a medical emergency during chemotherapy!';
      }
      
      return '''Fever Alert - This Requires Immediate Attention!

If your temperature is above 38°C (100.4°F):

🚨 Contact your doctor immediately or go to the emergency room!

Why This Is Serious:
• Fever during chemotherapy can indicate infection
• Your immune system is weakened by treatment
• Infections can become life-threatening quickly

What to Do Right Now:
• Take your temperature every hour
• Do NOT take fever medication without doctor approval
• Keep a record of temperature readings
• Stay hydrated
• Rest and monitor symptoms

EMERGENCY - Call doctor or go to ER if:
• Temperature above 38°C (100.4°F)
• Shaking or chills
• Confusion or dizziness
• Rapid heartbeat$tempWarning

Always consult your doctor for medical decisions.''';
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
• Keep a pain diary to track patterns

When to Contact Your Doctor:
• Severe or sudden pain
• Pain not relieved by medication
• New or different type of pain
• Pain accompanied by fever or swelling

Remember: There is no need to "tough it out" - effective pain management helps you feel better and heal.

Always consult your doctor for medical decisions.''';
    }
    
    // Default helpful response with health context
    String defaultContext = data != null
        ? '\n\nYour latest readings show ${data.getRiskLevelString().toLowerCase()} risk with:\n• Heart Rate: ${data.heartRate} bpm\n• Oxygen: ${data.spo2Level}%\n• Temperature: ${data.temperature.toStringAsFixed(1)}°C'
        : '';
    
    return '''I am here to support you through your chemotherapy journey.$defaultContext

I can provide personalized guidance on:
• Managing common side effects (nausea, fatigue, pain)
• Understanding your vital signs and risk level
• When to contact your doctor
• General health tips during treatment

What would you like to know about? Feel free to ask specific questions about your symptoms or health concerns.

Always consult your doctor for medical decisions.''';
  }

  /// Clear conversation history (optional - for new sessions)
  void clearHistory() {
    _conversationHistory.clear();
  }
}