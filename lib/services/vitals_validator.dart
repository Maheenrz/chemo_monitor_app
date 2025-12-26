class VitalsValidator {
  // Clinical ranges for oncology patients
  static const Map<String, Map<String, dynamic>> _vitalRanges = {
    'heartRate': {
      'min': 40,
      'max': 200,
      'normalMin': 60,
      'normalMax': 100,
      'warningLow': 50,
      'warningHigh': 120,
      'criticalLow': 40,
      'criticalHigh': 150,
      'unit': 'bpm',
      'errorMessage': 'Heart rate must be between 40-200 bpm',
    },
    'spo2': {
      'min': 70,
      'max': 100,
      'normalMin': 95,
      'normalMax': 100,
      'warningLow': 94,
      'criticalLow': 90,
      'unit': '%',
      'errorMessage': 'SpO2 must be between 70-100%',
    },
    'systolicBP': {
      'min': 70,
      'max': 250,
      'normalMin': 90,
      'normalMax': 120,
      'warningLow': 85,
      'warningHigh': 140,
      'criticalLow': 80,
      'criticalHigh': 180,
      'unit': 'mmHg',
      'errorMessage': 'Systolic BP must be between 70-250 mmHg',
    },
    'diastolicBP': {
      'min': 40,
      'max': 150,
      'normalMin': 60,
      'normalMax': 80,
      'warningLow': 50,
      'warningHigh': 90,
      'criticalLow': 40,
      'criticalHigh': 120,
      'unit': 'mmHg',
      'errorMessage': 'Diastolic BP must be between 40-150 mmHg',
    },
    'temperature': {
      'min': 35.0,
      'max': 42.0,
      'normalMin': 36.1,
      'normalMax': 37.2,
      'warningLow': 36.0,
      'warningHigh': 37.5,
      'criticalLow': 35.5,
      'criticalHigh': 39.0,
      'unit': '°C',
      'errorMessage': 'Temperature must be between 35.0-42.0°C',
    },
  };

  /// Validate all vitals
  static ValidationResult validate({
    required int heartRate,
    required int spo2,
    required int systolicBP,
    required int diastolicBP,
    required double temperature,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    final alerts = <String>[];
    
    bool isValid = true;

    // 1. Basic range validation
    if (heartRate < (_vitalRanges['heartRate']!['min'] as int) || 
        heartRate > (_vitalRanges['heartRate']!['max'] as int)) {
      errors.add(_vitalRanges['heartRate']!['errorMessage'] as String);
      isValid = false;
    }
    
    if (spo2 < (_vitalRanges['spo2']!['min'] as int) || 
        spo2 > (_vitalRanges['spo2']!['max'] as int)) {
      errors.add(_vitalRanges['spo2']!['errorMessage'] as String);
      isValid = false;
    }
    
    if (systolicBP < (_vitalRanges['systolicBP']!['min'] as int) || 
        systolicBP > (_vitalRanges['systolicBP']!['max'] as int)) {
      errors.add(_vitalRanges['systolicBP']!['errorMessage'] as String);
      isValid = false;
    }
    
    if (diastolicBP < (_vitalRanges['diastolicBP']!['min'] as int) || 
        diastolicBP > (_vitalRanges['diastolicBP']!['max'] as int)) {
      errors.add(_vitalRanges['diastolicBP']!['errorMessage'] as String);
      isValid = false;
    }
    
    if (temperature < (_vitalRanges['temperature']!['min'] as double) || 
        temperature > (_vitalRanges['temperature']!['max'] as double)) {
      errors.add(_vitalRanges['temperature']!['errorMessage'] as String);
      isValid = false;
    }

    // 2. Medical logic validation
    if (systolicBP <= diastolicBP) {
      errors.add('Systolic blood pressure must be higher than diastolic');
      isValid = false;
    }

    if (systolicBP - diastolicBP > 60) {
      warnings.add('Wide pulse pressure detected');
    }

    // 3. Warning levels
    if (heartRate < (_vitalRanges['heartRate']!['warningLow'] as int)) {
      warnings.add('Low heart rate');
    }
    if (heartRate > (_vitalRanges['heartRate']!['warningHigh'] as int)) {
      warnings.add('Elevated heart rate');
    }
    
    if (spo2 < (_vitalRanges['spo2']!['warningLow'] as int)) {
      warnings.add('Low oxygen saturation');
    }
    
    if (systolicBP < (_vitalRanges['systolicBP']!['warningLow'] as int)) {
      warnings.add('Low blood pressure');
    }
    if (systolicBP > (_vitalRanges['systolicBP']!['warningHigh'] as int)) {
      warnings.add('Elevated blood pressure');
    }
    
    if (temperature < (_vitalRanges['temperature']!['warningLow'] as double)) {
      warnings.add('Low body temperature');
    }
    if (temperature > (_vitalRanges['temperature']!['warningHigh'] as double)) {
      warnings.add('Elevated body temperature');
    }

    // 4. Critical alerts
    if (heartRate < (_vitalRanges['heartRate']!['criticalLow'] as int) ||
        heartRate > (_vitalRanges['heartRate']!['criticalHigh'] as int)) {
      alerts.add('Critical heart rate level');
    }
    
    if (spo2 < (_vitalRanges['spo2']!['criticalLow'] as int)) {
      alerts.add('Critical oxygen level');
    }
    
    if (temperature < (_vitalRanges['temperature']!['criticalLow'] as double) ||
        temperature > (_vitalRanges['temperature']!['criticalHigh'] as double)) {
      alerts.add('Critical body temperature');
    }

    return ValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
      alerts: alerts,
    );
  }

  /// Check for emergency conditions (immediate action needed)
  static bool isInEmergencyRange({
    required int heartRate,
    required int spo2,
    required int systolicBP,
    required int diastolicBP,
    required double temperature,
  }) {
    return spo2 < 90 || 
           heartRate > 150 || 
           heartRate < 40 || 
           temperature > 39.0 ||
           temperature < 35.5 ||
           systolicBP > 180 ||
           diastolicBP > 120;
  }

  /// Get normal range for a specific vital
  static String getNormalRange(String vital) {
    final range = _vitalRanges[vital];
    return 'Normal: ${range!['normalMin']}-${range['normalMax']} ${range['unit']}';
  }

  /// Get all normal ranges as text
  static String getAllNormalRanges() {
    return '''
• Heart Rate: ${getNormalRange('heartRate')}
• Oxygen (SpO2): ${getNormalRange('spo2')}
• Blood Pressure: ${getNormalRange('systolicBP')}/${getNormalRange('diastolicBP').replaceAll('Normal: ', '')}
• Temperature: ${getNormalRange('temperature')}
''';
  }

  /// Check if value is in normal range
  static bool isNormal(String vital, dynamic value) {
    final range = _vitalRanges[vital];
    return value >= range!['normalMin'] && value <= range['normalMax'];
  }

  /// Get color for vital status
  static String getStatusColor(String vital, dynamic value) {
    final range = _vitalRanges[vital];
    
    if (vital == 'spo2') {
      if (value < range!['criticalLow']) return 'red';
      if (value < range['warningLow']) return 'orange';
      if (value < range['normalMin']) return 'yellow';
      return 'green';
    }
    
    if (value < (range!['criticalLow'] as dynamic) || value > (range['criticalHigh'] as dynamic)) {
      return 'red';
    }
    if (value < (range['warningLow'] as dynamic) || value > (range['warningHigh'] as dynamic)) {
      return 'orange';
    }
    if (value < (range['normalMin'] as dynamic) || value > (range['normalMax'] as dynamic)) {
      return 'yellow';
    }
    return 'green';
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final List<String> alerts;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.alerts,
  });
  
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasAlerts => alerts.isNotEmpty;
}