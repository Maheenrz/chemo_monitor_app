class AppRoutes {
  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  
  // Patient Routes
  static const String patientHome = '/patient/home';
  static const String healthDataEntry = '/patient/health-data';
  static const String predictionResult = '/patient/prediction';
  static const String chatbot = '/patient/chatbot';
  static const String patientMessaging = '/patient/messages';
  static const String patientProfile = '/patient/profile';
  
  // Doctor Routes
  static const String doctorHome = '/doctor/home';
  static const String patientList = '/doctor/patients';
  static const String patientDetail = '/doctor/patient-detail';
  static const String predictionHistory = '/doctor/prediction-history';
  static const String doctorMessaging = '/doctor/messages';
  static const String doctorProfile = '/doctor/profile';
}