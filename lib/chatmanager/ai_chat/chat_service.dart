import 'package:hive/hive.dart';
import '../../Hivemodel/health_report.dart';
import '../../Hivemodel/history_entry.dart';
import '../../Hivemodel/medicine.dart';
import '../../Hivemodel/user_settings.dart';
import 'gemini_provider.dart';

class ChatService {
  late final GeminiProvider _aiProvider;
  String apiKey = "AIzaSyDT1NimstllZmAz-mX56tFC03V4lOZp0OY";

  // Hive boxes
  late Box<Medicine> _medicineBox;
  late Box<HistoryEntry> _historyBox;
  late Box<UserSettings> _userBox;
  late Box<HealthReport> _reportBox;
  late Box _sessionBox;

  ChatService() {
    _aiProvider = GeminiProvider(apiKey: apiKey); // safe here
    _initializeBoxes();
  }

  void _initializeBoxes() {
    _medicineBox = Hive.box<Medicine>('medicinesBox');
    _historyBox = Hive.box<HistoryEntry>('historyBox');
    _userBox = Hive.box<UserSettings>('settingsBox');
    _reportBox = Hive.box<HealthReport>('healthReportsBox');
    _sessionBox = Hive.box('session');
  }

  /// Main method to get personalized AI response
  Future<String> getPersonalizedResponse(String userInput) async {
    try {
      String currentChildId = _sessionBox.get('childId', defaultValue: '');
      String query = userInput.toLowerCase().trim();

      // GREETING CHECK
      if (query == 'hi' ||
          query == 'hello' ||
          query == 'hey' ||
          query.startsWith('hi ') ||
          query.startsWith('hello ') ||
          query.contains('how are you') ||
          query.contains('good morning')) {
        return "Hello! 👋 I'm your personal health assistant. I can help you manage your medicines, track your health reports, and provide general health information. How can I assist you today?";
      }

      // Medicine Management Queries
      if (_isMedicineQuery(query)) {
        return await _handleMedicineQuery(query, currentChildId);
      }

      // Health Report Queries
      if (_isHealthReportQuery(query)) {
        return await _handleHealthReportQuery(query, currentChildId);
      }

      // User Information Queries
      if (_isUserInfoQuery(query)) {
        return _handleUserInfoQuery(query, currentChildId);
      }

      // Symptom-Based Queries
      if (_isSymptomQuery(query)) {
        return await _handleSymptomQuery(userInput, currentChildId);
      }

      // Medicine Info Queries like "paracetamol info"
      if (query.contains("info") || query.contains("information")) {
        try {
          // Extract medicine name by removing keywords
          String medicineName =
              query.replaceAll("info", "").replaceAll("information", "").trim();

          final chatService = ChatService();
          // Call instance method
          String aiResponse = await chatService.getAiMedicineInfo(medicineName);
          return aiResponse;
        } catch (e) {
          print('Error fetching medicine info: $e');
          return "I couldn't fetch detailed information for the medicine mentioned. "
              "Please consult your healthcare provider or pharmacist for accurate info.\n\n"
              "⚠️ Always consult a doctor before taking any medicine.";
        }
      }

      // Default fallback
      return _getDefaultResponse();
    } catch (e) {
      print('ChatService error: $e');
      return "Sorry, I couldn't access your health data right now. Please try again.";
    }
  }

  // Query type checkers
  bool _isMedicineQuery(String query) {
    List<String> medicineKeywords = [
      'medicine',
      'medication',
      'dose',
      'pill',
      'tablet',
      'dosage',
      'take',
      'missed',
      'taken',
      'refill',
      'quantity',
      'add medicine'
    ];
    return medicineKeywords.any((keyword) => query.contains(keyword));
  }

  bool _isHealthReportQuery(String query) {
    List<String> reportKeywords = [
      'blood pressure',
      'bp',
      'cholesterol',
      'health report',
      'test result',
      'reading',
      'systolic',
      'diastolic'
    ];
    return reportKeywords.any((keyword) => query.contains(keyword));
  }

  bool _isUserInfoQuery(String query) {
    List<String> userKeywords = [
      'my name',
      'who am i',
      'my profile',
      'about me',
      'hi',
      'hello',
      'hey',
      'greetings',
      'how are you',
      'good morning',
      'good afternoon',
      'good evening'
    ];

    // Check for exact matches or word boundaries to avoid false positives
    return userKeywords.any((keyword) {
      return query == keyword ||
          query.startsWith(keyword + ' ') ||
          query.contains(' ' + keyword + ' ') ||
          query.endsWith(' ' + keyword);
    });
  }

  bool _isSymptomQuery(String query) {
    List<String> symptomKeywords = [
      'pain',
      'fever',
      'cough',
      'headache',
      'nausea',
      'dizzy',
      'tired',
      'chest pain',
      'shortness of breath',
      'palpitations',
      'swelling',
      'weakness',
      'breathing',
      'heart',
      'stomach',
      'back pain',
      'hurt',
      'ache',
      'sick',
      'unwell',
      'symptoms',
      'feel bad',
      'blood pressure high',
      'bp high',
      'sugar high',
      'diabetes',
      'throat',
      'nose',
      'ear',
      'eye',
      'rash',
      'itching',
      'vomit',
      'diarrhea',
      'constipation',
      'sleep',
      'insomnia'
    ];

    return symptomKeywords.any((keyword) => query.contains(keyword));
  }

  // Query handlers
  Future<String> _handleMedicineQuery(String query, String childId) async {
    if (query.contains('add medicine') || query.contains('new medicine')) {
      return "I'd be happy to help you add a new medicine! Go to the Medicines section and tap the '+' button to enter the details of your new medication.";
    }

    if (query.contains('today medicine') || query.contains('today dose')) {
      return _getTodayMedicines(childId);
    }

    if (query.contains('missed') && query.contains('today')) {
      return _getMissedMedicinesToday(childId);
    }

    if (query.contains('refill') ||
        query.contains('running low') ||
        query.contains('quantity')) {
      return _getRefillAlerts(childId);
    }

    return _getAllMedicinesInfo(childId);
  }

  Future<String> _handleHealthReportQuery(String query, String childId) async {
    if (query.contains('blood pressure') || query.contains('bp')) {
      return _getBloodPressureInfo(childId);
    }

    if (query.contains('cholesterol')) {
      return _getCholesterolInfo(childId);
    }

    return _getLatestHealthReport(childId);
  }

  String _handleUserInfoQuery(String query, String childId) {
    try {
      final normalized = query.toLowerCase().trim();

      // Simple greeting check
      if (normalized == 'hi' ||
          normalized == 'hello' ||
          normalized == 'hey' ||
          normalized.startsWith('hi ') ||
          normalized.startsWith('hello ') ||
          normalized.startsWith('hey ')) {
        return "Hello! 👋 I'm your personal health assistant. I can help you manage your medicines, track your health reports, and provide general health information. How can I assist you today?";
      }

      // Other greeting patterns
      if (normalized.contains('how are you') ||
          normalized.contains('good morning') ||
          normalized.contains('good afternoon') ||
          normalized.contains('good evening')) {
        return "Hello! 👋 I'm your personal health assistant. I can help you manage your medicines, track your health reports, and provide general health information. How can I assist you today?";
      }

      // Rest of your existing logic...
      final user = _userBox.values.firstWhere(
        (u) => u.childId == childId,
        orElse: () => throw Exception('User not found'),
      );

      if (normalized.contains('name')) {
        return "Your name is ${user.username}. How can I help you today?";
      }

      if (normalized.contains('profile')) {
        return "I have your profile info, ${user.username}. You can ask me about medicines, health reports, or general health guidance.";
      }

      return "Hello ${user.username}! How can I support you with your health today?";
    } catch (e) {
      return "Hello! I'm here to help you with your medicines and health information.";
    }
  }

  /// Returns detailed information about a specific medicine
  Future<String> getMedicineDetailsResponse(String medicineName) async {
    try {
      final medicineBox = Hive.box<Medicine>('medicinesBox');

      final medicine = medicineBox.values.firstWhere(
        (med) => med.name.toLowerCase() == medicineName.toLowerCase(),
        orElse: () => throw Exception('Medicine not found'),
      );

      return "Medicine: ${medicine.name}\n"
          "Dosage: ${medicine.dosage}\n"
          "Quantity Left: ${medicine.quantityLeft}\n"
          "Expiry Date: ${_formatDate(medicine.expiryDate)}\n"
          "Daily Intake Times: ${medicine.dailyIntakeTimes.join(', ')}";
    } catch (e) {
      print('Error fetching medicine details: $e');
      return "Sorry, I could not find details for $medicineName.";
    }
  }

  Future<String> fetchDetailedMedicineInfo(String medicineName) async {
    try {
      // Build a detailed, safe AI prompt
      String prompt = '''
You are a careful medical AI assistant. Provide safe, general information about the medicine "$medicineName".

Format your response neatly using sections and bullet points. For each section, provide **up to 3 main points only**.

Medicine Name: $medicineName

1. Purpose / Main Use:
- List up to 3 main purposes
2. Common Use Cases:
- List up to 3 typical scenarios
3. Common Side Effects / Problems:
- List up to 3 common side effects

Keep it concise, clear, and safe.
Do NOT give personal medical advice.
Do not include extra information beyond what is requested.
Always recommend consulting a healthcare provider.
''';

      // Fetch AI response directly from Gemini
      String aiResponse = await _aiProvider.generateContent(prompt);

      return aiResponse;
    } catch (e) {
      print('Error fetching detailed medicine info: $e');
      return "I couldn't fetch detailed information for $medicineName at the moment. Please consult your healthcare provider or pharmacist for accurate information.\n\n⚠️ Always consult your doctor before taking any medicine.";
    }
  }

  Future<String> getAiMedicineInfo(String medicineName) async {
    try {
      medicineName = medicineName.trim();
      if (medicineName.isEmpty) throw StateError('No medicine name provided');

      // Build AI prompt
      String prompt = '''
You are a careful medical AI assistant. Provide safe, general information about the medicine "$medicineName".

Format your response neatly using sections and bullet points. For each section, provide **up to 3 main points only**.

Medicine Name: $medicineName

1. Purpose / Main Use:
- List up to 3 main purposes
2. Common Use Cases:
- List up to 3 typical scenarios
3. Common Side Effects / Problems:
- List up to 3 common side effects

Keep it concise, clear, and safe.
Do NOT give personal medical advice.
Do not include extra information beyond what is requested.
Always recommend consulting a healthcare provider.
''';

      // Fetch AI response via your existing provider method (Gemini + creds)
      String aiResponse = await _aiProvider.generateContent(prompt);

      return aiResponse;
    } catch (e) {
      print('Error fetching medicine info: $e');
      return "I couldn't fetch detailed information for the medicine mentioned. "
          "Please consult your healthcare provider or pharmacist for accurate info.\n\n"
          "⚠️ Always consult a doctor before taking any medicine.";
    }
  }

  Future<String> _handleSymptomQuery(String userInput, String childId) async {
    try {
      // Get user's health context with null safety
      var userMedicines = _medicineBox.values // Add this filter
          .map((m) => "${m.name} ${m.dosage}")
          .toList();

      var healthReports = _reportBox.values
          .where((r) => r.childId == childId) // Add this filter
          .toList();

      // Build safe, context-aware prompt
      String prompt = '''
You are a careful medical AI assistant for elderly patients. Provide only safe, general guidance.

Patient Context:
- Current medicines: ${userMedicines.isEmpty ? "None recorded" : userMedicines.join(", ")}
- Latest BP: ${_getLatestReportValue(healthReports, 'systolic')}/${_getLatestReportValue(healthReports, 'diastolic')} mmHg
- Latest cholesterol: ${_getLatestReportValue(healthReports, 'cholesterol')} mg/dL

Patient asked: "$userInput"

Guidelines:
1. Give only general, supportive advice
2. Consider their current health readings and medicines
3. ALWAYS recommend consulting their healthcare provider
4. Be empathetic and reassuring
5. Keep response to 3-4 sentences maximum
6. Never provide diagnosis or specific medical recommendations
7. If symptoms seem serious, emphasize urgent medical attention

Respond safely:
''';

      String response = await _aiProvider.generateContent(prompt);

      // Add emergency warning for serious symptoms
      if (_hasSeriousSymptoms(userInput)) {
        return "🚨 $response\n\n⚠️ **IMPORTANT**: These symptoms may need immediate medical attention. Please contact your doctor or emergency services if symptoms are severe.";
      }

      return response +
          "\n\n⚠️ Please consult your doctor for proper medical evaluation.";
    } catch (e) {
      print('Symptom query error: $e');
      return "I understand you're concerned about your symptoms. Given your current medications and health profile, I'd recommend contacting your healthcare provider for proper guidance.\n\n⚠️ Please consult your doctor for proper medical evaluation.";
    }
  }

// Add this helper method for serious symptom detection
  bool _hasSeriousSymptoms(String input) {
    List<String> seriousSymptoms = [
      'chest pain',
      'shortness of breath',
      'difficulty breathing',
      'severe pain',
      'blood',
      'unconscious',
      'fainting',
      'heart attack',
      'stroke',
      'emergency',
      'can\'t breathe'
    ];

    String normalized = input.toLowerCase();
    return seriousSymptoms.any((symptom) => normalized.contains(symptom));
  }

  // Data retrieval methods
  String _getTodayMedicines(String childId) {
    var todayMedicines = _medicineBox.values.toList();

    if (todayMedicines.isEmpty) {
      return "You don't have any medicines recorded. Would you like to add your current medications?";
    }

    String response = "📋 **Your medicines for today:**\n\n";
    for (int i = 0; i < todayMedicines.length; i++) {
      var medicine = todayMedicines[i];
      response += "${i + 1}. **${medicine.name}** - ${medicine.dosage}\n";
      response += "   Take ${medicine.dailyIntakeTimes.length} times daily\n";
      if (medicine.instructions != null && medicine.instructions!.isNotEmpty) {
        response += "   📝 ${medicine.instructions}\n";
      }
      response += "\n";
    }

    return response + "💊 Remember to take them as prescribed!";
  }

  String _getMissedMedicinesToday(String childId) {
    var today = DateTime.now();
    var todayStart = DateTime(today.year, today.month, today.day);

    var missedToday = _historyBox.values
        .where((h) => h.date.isAfter(todayStart) && h.status == 'skipped')
        .toList();

    if (missedToday.isEmpty) {
      return "✅ Great! You haven't missed any medicines today. Keep up the good work!";
    }

    String response = "⚠️ **Missed medicines today:**\n\n";
    for (var entry in missedToday) {
      response +=
          "• ${entry.medicineName} at ${entry.time ?? 'scheduled time'}\n";
    }

    return response + "\n💡 Try setting reminders to help you remember!";
  }

  String _getRefillAlerts(String childId) {
    var lowStockMedicines = _medicineBox.values
        .where((m) => m.quantityLeft <= m.refillThreshold)
        .toList();

    if (lowStockMedicines.isEmpty) {
      return "✅ All your medicines have sufficient stock. No refills needed right now!";
    }

    String response = "🔔 **Refill alerts:**\n\n";
    for (var medicine in lowStockMedicines) {
      response += "• **${medicine.name}**: ${medicine.quantityLeft} left\n";
      if (medicine.quantityLeft == 0) {
        response += "  ❌ **Out of stock** - Refill immediately!\n";
      } else {
        response += "  ⚠️ Running low - Consider refilling soon\n";
      }
      response += "\n";
    }

    return response + "💡 Contact your pharmacy or doctor for refills.";
  }

  String _getBloodPressureInfo(String childId) {
    var reports = _reportBox.values.where((r) => r.childId == childId).toList();

    if (reports.isEmpty) {
      return "No blood pressure readings found. Please add your latest BP readings to track your health.";
    }

    String systolic = _getLatestReportValue(reports, 'systolic');
    String diastolic = _getLatestReportValue(reports, 'diastolic');

    String response =
        "🩺 **Your latest blood pressure:** $systolic/$diastolic mmHg\n\n";

    // Safe interpretation
    int? sys = int.tryParse(systolic);
    int? dia = int.tryParse(diastolic);

    if (sys != null && dia != null) {
      if (sys > 140 || dia > 90) {
        response +=
            "📊 This reading appears elevated. Please discuss with your doctor about blood pressure management.";
      } else if (sys < 90 || dia < 60) {
        response +=
            "📊 This reading appears low. Consider consulting your healthcare provider.";
      } else {
        response +=
            "📊 This reading appears within normal range. Keep monitoring regularly!";
      }
    }

    return response +
        "\n\n💡 Continue taking your BP medications as prescribed.";
  }

  String _getCholesterolInfo(String childId) {
    var reports = _reportBox.values.toList();
    String cholesterol = _getLatestReportValue(reports, 'cholesterol');

    if (cholesterol == "Not available") {
      return "No cholesterol readings found. Regular cholesterol checks are important for heart health.";
    }

    String response = "💛 **Your latest cholesterol:** $cholesterol mg/dL\n\n";

    int? chol = int.tryParse(cholesterol);
    if (chol != null) {
      if (chol > 240) {
        response +=
            "📊 This level is high. Please follow your doctor's advice for cholesterol management.";
      } else if (chol > 200) {
        response +=
            "📊 This level is borderline. Continue monitoring and follow dietary recommendations.";
      } else {
        response += "📊 This level looks good! Maintain your healthy habits.";
      }
    }

    return response +
        "\n\n🥗 Continue with heart-healthy diet and prescribed medications.";
  }

  String _getAllMedicinesInfo(String childId) {
    var medicines = _medicineBox.values.toList();

    if (medicines.isEmpty) {
      return "You don't have any medicines recorded. Would you like to add your current medications?";
    }

    String response = "💊 **All your medicines:**\n\n";
    for (int i = 0; i < medicines.length; i++) {
      var med = medicines[i];
      response += "${i + 1}. **${med.name}** - ${med.dosage}\n";
      response += "   Frequency: ${med.dailyIntakeTimes.length} times daily\n";
      response += "   Stock: ${med.quantityLeft} remaining\n\n";
    }

    return response;
  }

  String _getLatestHealthReport(String childId) {
    var reports = _reportBox.values.where((r) => r.childId == childId).toList();

    if (reports.isEmpty) {
      return "No health reports found. Adding your health readings helps me provide better guidance.";
    }

    // Sort by date, get latest
    reports.sort((a, b) => b.reportDate.compareTo(a.reportDate));
    var latest = reports.first;

    String response =
        "📊 **Latest Health Report** (${_formatDate(latest.reportDate)}):\n\n";

    if (latest.systolic != null) {
      response +=
          "• Blood Pressure: ${latest.systolic}/${latest.diastolic} mmHg\n";
    }
    if (latest.cholesterol != null) {
      response += "• Cholesterol: ${latest.cholesterol} mg/dL\n";
    }

    return response +
        "\n💡 Share these readings with your healthcare provider during visits.";
  }

  String _getDefaultResponse() {
    return "I don't have enough information to assist with that. Please ask about your medicines, health reports, or general health questions.I'm your personal health assistant! I can help you with:\n\n" +
        "💊 Medicine management: Today's doses, missed medications, refill alerts\n" +
        "📊 Health reports: Blood pressure, cholesterol readings\n" +
        "❓ Health questions: Symptoms, medicine information, general health tips\n" +
        "👤 Personal info: Your profile and health history\n\n" +
        "What would you like to know about your health today?";
  }

  // Utility methods
  String _getLatestReportValue(List<HealthReport> reports, String key) {
    if (reports.isEmpty) return "Not available";

    // Sort by date, get latest
    reports.sort((a, b) => b.reportDate.compareTo(a.reportDate));

    var latest = reports.first;
    switch (key) {
      case 'systolic':
        return latest.systolic ?? "Not available";
      case 'diastolic':
        return latest.diastolic ?? "Not available";
      case 'cholesterol':
        return latest.cholesterol ?? "Not available";
      default:
        return "Not available";
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // Image analysis enhancement methods
  Future<String> enhancePrescriptionAnalysis(String aiAnalysis) async {
    try {
      // Get user's current medicines for comparison
      var userMedicines = _medicineBox.values.map((m) => m.name).toList();

      String prompt = '''
You are helping an elderly patient analyze their prescription. 

Current medicines they're taking: ${userMedicines.join(", ")}

AI extracted from prescription: "$aiAnalysis"

Provide:
1. Clear summary of new medicines
2. Check for potential duplicates with current medicines
3. Simple reminders about following doctor's instructions
4. Suggest adding to their medicine tracker
5. Maximum 4-5 sentences in simple language

Be helpful and encouraging:
''';

      String response = await _aiProvider.generateContent(prompt);
      return response +
          "\n\n💊 Would you like me to help you add these medicines to your tracker?";
    } catch (e) {
      return aiAnalysis +
          "\n\n💡 I've analyzed your prescription. Please follow your doctor's instructions.";
    }
  }

  Future<String> enhanceHealthReportAnalysis(String aiAnalysis) async {
    try {
      String currentChildId = _sessionBox.get('childId', defaultValue: '');

      // Get user's health history for comparison
      var previousReports =
          _reportBox.values.where((r) => r.childId == currentChildId).toList();

      String prompt = '''
You are helping an elderly patient understand their health report.

Previous health readings: 
${previousReports.map((r) => "BP: ${r.systolic}/${r.diastolic}, Cholesterol: ${r.cholesterol}").join(", ")}

AI extracted from report: "$aiAnalysis"

Provide:
1. Simple explanation of the readings
2. How they compare to previous readings (if any)
3. General encouragement or gentle guidance
4. Remind to discuss with doctor
5. Maximum 4-5 sentences in simple language

Be supportive and clear:
''';

      String response = await _aiProvider.generateContent(prompt);
      return response +
          "\n\n📊 Would you like me to save these readings to your health tracker?";
    } catch (e) {
      return aiAnalysis +
          "\n\n💡 Please discuss these results with your healthcare provider.";
    }
  }
}
