// voice_chat_manager.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:words_numbers/words_numbers.dart';

import '../Hivemodel/health_report.dart';
import '../Hivemodel/history_entry.dart';
import '../Hivemodel/medicine.dart';
import '../Hivemodel/user_settings.dart';

enum VoiceMode { normal, addMedicine }

class VoiceChatManager {
  static final VoiceChatManager _instance = VoiceChatManager._internal();
  factory VoiceChatManager() => _instance;
  VoiceChatManager._internal();

  bool _isListening = false;
  bool _isProcessing = false;
  String _currentTranscript = '';
  String _currentResponse = ''; // ADD THIS - was missing

  // Callbacks for UI updates
  VoidCallback? onStateChanged;
  Function(String)? onShowAnswer; // ADD THIS - was missing
  Function(String)? onShowError; // ADD THIS - was missing
  Function(Map<String, dynamic>)? onAddMedicineCompleted;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get currentTranscript => _currentTranscript;
  String get currentResponse => _currentResponse; // ADD THIS getter
//for choosing the type of iput from user
  VoiceMode _mode = VoiceMode.normal;
  int _step = 0;
  Map<String, dynamic> _answers = {};
//for choosing the type of iput from user

  Future<void> initialize() async {
    try {
      await _tts.setLanguage("en-IN"); // Changed to Indian English
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0); // ADD pitch setting
      print("VoiceChatManager initialized successfully");
    } catch (e) {
      print("TTS initialization error: $e");
    }
  }

  void startListening() {
    _isListening = true;
    _notifyListeners();
    _startSpeechRecognition();
  }

  void stopListening() {
    _isListening = false;
    _speech.stop();
    _notifyListeners();
  }

  void setProcessing(bool processing) {
    _isProcessing = processing;
    _notifyListeners();
  }

  void setTranscript(String transcript) {
    _currentTranscript = transcript;
    _notifyListeners();
  }

  void setResponse(String response) {
    // ADD THIS METHOD
    _currentResponse = response;
    _notifyListeners();
  }

  void _notifyListeners() {
    onStateChanged?.call();
  }

  // FIXED DISPOSE METHOD:
  void dispose() {
    try {
      _speech.stop();
      _tts.stop(); // FIXED: was _flutterTts, should be _tts
      _mode = VoiceMode.normal;
      // Reset all state
      _isListening = false;
      _isProcessing = false;
      _currentTranscript = '';
      _currentResponse = '';

      // Clear callbacks
      onStateChanged = null;
      onShowAnswer = null;
      onShowError = null;

      print("VoiceChatManager disposed successfully");
    } catch (e) {
      print("Error disposing VoiceChatManager: $e");
    }
  }

  Future<void> _startSpeechRecognition() async {
    try {
      bool available = await _speech.initialize(onStatus: (status) {
        print("Speech status: $status");
        if (status == "listening") {
          _isListening = true;
          _notifyListeners();
        } else if (status == "notListening") {
          _isListening = false;
          _notifyListeners();
        }
      }, onError: (error) {
        print("Speech error: ${error.errorMsg}");
        _isListening = false;
        _notifyListeners();

        if (error.errorMsg == 'error_no_match') {
          onShowError
              ?.call("Couldn't understand. Please try speaking clearly.");
        } else {
          onShowError?.call("Speech recognition error. Please try again.");
        }
      });

      if (available) {
        await _speech.listen(
          onResult: (result) {
            setTranscript(result.recognizedWords);

            if (result.finalResult &&
                result.recognizedWords.trim().isNotEmpty) {
              print("Recognized: ${result.recognizedWords}");
              stopListening();
              _processResponse(result.recognizedWords.toLowerCase().trim());
            }
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation,
            partialResults: false,
          ),
        );
      } else {
        onShowError?.call("Speech recognition is not available.");
      }
    } catch (e) {
      print("Speech initialization error: $e");
      onShowError
          ?.call("Failed to start speech recognition. Please try again.");
      _isListening = false;
      _notifyListeners();
    }
  }

  Future<void> _processResponse(String text) async {
    setProcessing(true);

    try {
      String response;

      if (_mode == VoiceMode.addMedicine) {
        response = await _handleAddMedicineStep(text);
      } else {
        response = await _getAIResponse(text); // existing Q&A
      }
      setResponse(response); // ADD THIS LINE
      await _speak(response);
      onShowAnswer?.call(response); // ADD THIS LINE
    } catch (e) {
      print('Error: $e');
    } finally {
      setProcessing(false);
      // Don't clear transcript immediately, let overlay handle it
    }
  }

//for add medicine mode

  // Future<void> startAddMedicineFlow() async {
  //   _mode = VoiceMode.addMedicine;
  //   _step = 0;
  //   _answers.clear();
  //   await _speak("Let's add a new medicine. What is the medicine name?");
  // }
  DateTime _parseExpiryDate(String text) {
    try {
      // Split text into parts
      final parts = text.trim().split(RegExp(r'\s+'));
      if (parts.length < 3) return DateTime.now().add(Duration(days: 90));

      // Convert day and year words to numbers
      final day =
          int.tryParse(WordsNumbers.convertTextNumberToString(parts[0])) ?? 1;
      final month = _monthFromString(parts[1]);
      final year =
          int.tryParse(WordsNumbers.convertTextNumberToString(parts[2])) ??
              DateTime.now().year;

      return DateTime(year, month, day);
    } catch (e) {
      print("Error parsing expiry date: $e");
      return DateTime.now().add(Duration(days: 90));
    }
  }

  int _monthFromString(String month) {
    switch (month.toLowerCase()) {
      case 'january':
        return 1;
      case 'february':
        return 2;
      case 'march':
        return 3;
      case 'april':
        return 4;
      case 'may':
        return 5;
      case 'june':
        return 6;
      case 'july':
        return 7;
      case 'august':
        return 8;
      case 'september':
        return 9;
      case 'october':
        return 10;
      case 'november':
        return 11;
      case 'december':
        return 12;
      default:
        // Try converting month as a number word
        return int.tryParse(WordsNumbers.convertTextNumberToString(month)) ??
            DateTime.now().month;
    }
  }

  TimeOfDay _parseTimeOfDay(String text) {
    try {
      final parts =
          text.trim().split(RegExp(r'[:\s]+')); // Split by space or colon
      if (parts.isEmpty) return TimeOfDay.now();

      // Convert first part to hour
      int hour =
          int.tryParse(WordsNumbers.convertTextNumberToString(parts[0])) ?? 0;

      // Convert second part to minute if exists
      int minute = 0;
      if (parts.length > 1) {
        minute =
            int.tryParse(WordsNumbers.convertTextNumberToString(parts[1])) ?? 0;
      }

      // Check for AM/PM in the text
      if (text.toLowerCase().contains('pm') && hour < 12) hour += 12;
      if (text.toLowerCase().contains('am') && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print("Error parsing time: $e");
      return TimeOfDay.now();
    }
  }

  Future<String> _handleAddMedicineStep(String text) async {
    switch (_step) {
      case 0:
        _answers['name'] = text;
        _step++;
        return "What is the dosage?";
      case 1:
        _answers['dosage'] =
            int.tryParse(WordsNumbers.convertTextNumberToString(text)) ?? 0;
        _step++;
        return "How many tablets do you have in total?";
      case 2:
        // Convert spoken quantity like "two" -> 2
        _answers['quantity'] =
            int.tryParse(WordsNumbers.convertTextNumberToString(text)) ?? 0;
        _step++;
        return "When should I remind you to refill? Say a number like 5.";

      case 3:
        _answers['threshold'] =
            int.tryParse(WordsNumbers.convertTextNumberToString(text)) ?? 0;
        _step++;
        return "What is the expiry date? Please say in format day month year.";
      case 4:
        // Convert spoken date like "five September two zero two five" -> DateTime
        _answers['expiryDate'] = _parseExpiryDate(text);
        _step++;
        return "How many times per day should you take this medicine?";

      case 5:
        _answers['timesPerDay'] =
            int.tryParse(WordsNumbers.convertTextNumberToString(text)) ?? 1;
        _answers['doseTimes'] = [];
        _step++;
        return "Please say the first intake time, for example 8 AM.";
      case 6:
        // Parse spoken time like "eight thirty AM" or "8 30"
        final time = _parseTimeOfDay(text);
        _answers['doseTimes'].add(time);

        if (_answers['doseTimes'].length < _answers['timesPerDay']) {
          return "Please say the next intake time.";
        } else {
          _step++;
          return "Do you want me to save this medicine?";
        }

      case 7:
        if (text.toLowerCase().contains("yes")) {
          try {
            // 1️⃣ Get current child ID from session
            final session = Hive.box('session');
            final currentChildId = session.get('childId', defaultValue: '');

            final medicineBox = Hive.box<Medicine>('medicinesBox');

            // 2️⃣ Insert into Supabase first
            final supabase = Supabase.instance.client;
            final response = await supabase
                .from('medicine')
                .insert({
                  'child_id': currentChildId,
                  'name': _answers['name'] ?? '',
                  'dosage': _answers['dosage'] ?? '',
                  'expiry_date': (_answers['expiryDate'] ??
                          DateTime.now().add(Duration(days: 90)))
                      .toIso8601String(),
                  'daily_intake_times':
                      (_answers['doseTimes'] as List<TimeOfDay>)
                          .map((t) => "${t.hour}:${t.minute}")
                          .toList(),
                  'total_quantity': _answers['quantity'] ?? 0,
                  'quantity_left': _answers['quantity'] ?? 0,
                  'refill_threshold': _answers['threshold'] ?? 0,
                  'created_at': DateTime.now().toIso8601String(),
                })
                .select()
                .single();

            // 3️⃣ Build Medicine object using Supabase ID
            final medicine = Medicine(
              id: response['id'], // Supabase auto-generated ID
              name: response['name'],
              dosage: response['dosage'],
              expiryDate: DateTime.parse(response['expiry_date']),
              dailyIntakeTimes:
                  List<String>.from(response['daily_intake_times']),
              totalQuantity: response['total_quantity'],
              quantityLeft: response['quantity_left'],
              refillThreshold: response['refill_threshold'],
            );

            // 4️⃣ Save into Hive with the same Supabase ID
            await medicineBox.put(medicine.id, medicine);

            _mode = VoiceMode.normal;
            return "Medicine ${medicine.name} saved successfully!";
          } catch (e) {
            _mode = VoiceMode.normal;
            print("Error saving medicine: $e");
            return "Sorry, I could not save the medicine.";
          }
        } else {
          _mode = VoiceMode.normal;
          return "Okay, I cancelled the medicine entry.";
        }

      default:
        _mode = VoiceMode.normal;
        return "Add medicine flow ended.";
    }
  }

//for add medicine mode
  String _getUserName(Box<UserSettings> userBox, String childId) {
    try {
      final user = userBox.values.firstWhere(
        (user) => user.childId == childId,
        orElse: () => throw StateError('No user found'),
      );
      return "your name is ${user.username}";
    } catch (e) {
      return "User";
    }
  }

  String _getTodayMedicines(Box<Medicine> medicineBox) {
    try {
      final medicines = medicineBox.values.toList();
      if (medicines.isEmpty) {
        return "You have no medicines scheduled.";
      }

      StringBuffer response = StringBuffer("Today's medicines: ");
      for (int i = 0; i < medicines.length; i++) {
        final med = medicines[i];
        response.write("${med.name} at ${med.dailyIntakeTimes.join(', ')}");
        if (i < medicines.length - 1) response.write(", ");
      }
      return response.toString();
    } catch (e) {
      return "Could not fetch today's medicines.";
    }
  }

  String _getMissedMedicinesToday(Box<HistoryEntry> historyBox) {
    try {
      final today = DateTime.now();
      final missed = historyBox.values
          .where((entry) =>
              _isSameDay(entry.date, today) && entry.status == 'skipped')
          .toList();

      if (missed.isEmpty) {
        return "Great! You haven't missed any medicines today.";
      }

      StringBuffer response = StringBuffer("Missed medicines today: ");
      for (int i = 0; i < missed.length; i++) {
        response.write(missed[i].medicineName);
        if (i < missed.length - 1) response.write(", ");
      }
      return response.toString();
    } catch (e) {
      return "Could not fetch missed medicines.";
    }
  }

  String _getTakenMedicinesToday(Box<HistoryEntry> historyBox) {
    try {
      final today = DateTime.now();
      final taken = historyBox.values
          .where((entry) =>
              _isSameDay(entry.date, today) && entry.status == 'taken')
          .toList();

      if (taken.isEmpty) {
        return "You haven't taken any medicines yet today.";
      }

      return "You've taken ${taken.length} medicine${taken.length == 1 ? '' : 's'} today. Good job!";
    } catch (e) {
      return "Could not fetch taken medicines.";
    }
  }

  String _getMedicineQuantities(Box<Medicine> medicineBox) {
    try {
      final medicines = medicineBox.values.toList();
      if (medicines.isEmpty) {
        return "No medicines in your inventory.";
      }

      StringBuffer response = StringBuffer("Medicine quantities: ");
      for (int i = 0; i < medicines.length; i++) {
        final med = medicines[i];
        response.write("${med.name}: ${med.quantityLeft} tablets left");
        if (i < medicines.length - 1) response.write(", ");
      }
      return response.toString();
    } catch (e) {
      return "Could not fetch medicine quantities.";
    }
  }

  String _getRefillAlerts(Box<Medicine> medicineBox) {
    try {
      final lowStock = medicineBox.values
          .where((med) => med.quantityLeft <= med.refillThreshold)
          .toList();

      if (lowStock.isEmpty) {
        return "All your medicines have sufficient stock.";
      }

      StringBuffer response = StringBuffer("Refill needed for: ");
      for (int i = 0; i < lowStock.length; i++) {
        final med = lowStock[i];
        response.write("${med.name} (${med.quantityLeft} left)");
        if (i < lowStock.length - 1) response.write(", ");
      }
      return response.toString();
    } catch (e) {
      return "Could not fetch refill alerts.";
    }
  }

  String _getExpiringMedicines(Box<Medicine> medicineBox) {
    try {
      final now = DateTime.now();
      final thirtyDaysLater = now.add(Duration(days: 30));

      final expiring = medicineBox.values
          .where((med) => med.expiryDate.isBefore(thirtyDaysLater))
          .toList();

      if (expiring.isEmpty) {
        return "No medicines are expiring in the next 30 days.";
      }

      StringBuffer response = StringBuffer("Expiring soon: ");
      for (int i = 0; i < expiring.length; i++) {
        final med = expiring[i];
        final daysLeft = med.expiryDate.difference(now).inDays;
        response.write("${med.name} (expires in $daysLeft days)");
        if (i < expiring.length - 1) response.write(", ");
      }
      return response.toString();
    } catch (e) {
      return "Could not fetch expiring medicines.";
    }
  }

  String _getHealthReports(Box<HealthReport> reportBox, String childId) {
    try {
      final reports = reportBox.values
          .where((report) => report.childId == childId)
          .toList();

      if (reports.isEmpty) {
        return "No health reports found.";
      }

      // Get latest report
      reports.sort((a, b) => b.reportDate.compareTo(a.reportDate));
      final latest = reports.first;

      return "Latest health report from ${_formatDate(latest.reportDate)}: ${latest.notes}. "
          "${latest.systolic != null ? 'BP: ${latest.systolic}/${latest.diastolic}' : ''}"
          "${latest.cholesterol != null ? ', Cholesterol: ${latest.cholesterol}' : ''}";
    } catch (e) {
      return "Could not fetch health reports.";
    }
  }

  String _getMedicineInfo(String text, Box<Medicine> medicineBox) {
    try {
      // Extract medicine name from text
      String medicineName = "";
      if (text.contains("paracetamol")) medicineName = "paracetamol";
      // Add more medicine name extractions as needed

      final medicine = medicineBox.values.firstWhere(
        (med) => med.name.toLowerCase().contains(medicineName.toLowerCase()),
        orElse: () => throw StateError('Medicine not found'),
      );

      return "You have ${medicine.name}, ${medicine.dosage} strength. "
          "${medicine.quantityLeft} tablets left. Take at ${medicine.dailyIntakeTimes.join(', ')}.";
    } catch (e) {
      return "Paracetamol is commonly used to reduce fever and relieve pain. Please check with your doctor for proper dosage.";
    }
  }

// Utility methods
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<String> _getAIResponse(String text) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate processing

    try {
      // Get Hive boxes
      final medicineBox = Hive.box<Medicine>('medicinesBox');
      final historyBox = Hive.box<HistoryEntry>('historyBox');
      final userBox = Hive.box<UserSettings>('settingsBox');
      final reportBox =
          Hive.box<HealthReport>('healthReportsBox'); // Add if you have this
      final session = Hive.box('session');

      String currentChildId = session.get('childId', defaultValue: '');
// 1️⃣ Start Add Medicine Flow
      if (text.contains("add medicine") || text.contains("new medicine")) {
        _answers.clear();
        String prompt = "Go to Add Medicine page to add a new medicine, "
            "or go to the Chat page to add medicine from the prescription list.";
        await _speak(prompt);
        return prompt;
      }

      // 2️⃣ If already in add medicine mode, process steps
      if (_mode == VoiceMode.addMedicine) {
        return await _handleAddMedicineStep(text);
      }
      // User name queries
      if (text.contains("my name") || text.contains("what is my name")) {
        return _getUserName(userBox, currentChildId);
      }

      // Today's medicines
      else if (text.contains("today") &&
          (text.contains("medicine") || text.contains("dose"))) {
        return _getTodayMedicines(medicineBox);
      }

      // Missed medicines today
      else if (text.contains("missed") && text.contains("today")) {
        return _getMissedMedicinesToday(historyBox);
      }

      // Taken medicines today
      else if (text.contains("taken") && text.contains("today")) {
        return _getTakenMedicinesToday(historyBox);
      }

      // Medicine quantity/refill
      else if (text.contains("how many") ||
          text.contains("quantity") ||
          text.contains("left")) {
        return _getMedicineQuantities(medicineBox);
      }

      // Refill alerts
      else if (text.contains("refill") || text.contains("running low")) {
        return _getRefillAlerts(medicineBox);
      }

      // Expiring medicines
      else if (text.contains("expir") || text.contains("old medicine")) {
        return _getExpiringMedicines(medicineBox);
      }

      // Health reports
      else if (text.contains("health") && text.contains("report")) {
        return _getHealthReports(reportBox, currentChildId);
      }

      // Medicine information
      else if (text.contains("paracetamol") || text.contains("medicine info")) {
        return _getMedicineInfo(text, medicineBox);
      }

      // How app works
      else if (text.contains("how") &&
          (text.contains("work") || text.contains("help"))) {
        return "MedRemind helps you track medicines, set reminders, and monitor your health. You can ask about today's medicines, missed doses, refill alerts, and health reports.";
      }

      // Greeting
      else if (text.contains("hello") || text.contains("hi")) {
        String userName = _getUserName(userBox, currentChildId);
        return "Hello $userName! How can I help you with your medicines today?";
      } else {
        return "I can help you with: your medicines today, missed doses, refill alerts, expiring medicines, health reports, or medicine information, Add medicine. What would you like to know?";
      }
    } catch (e) {
      print('Database error: $e');
      return "Sorry, I couldn't access your medicine data right now. Please try again.";
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.setLanguage("en-IN");
      await _tts.setPitch(1.0);
      await _tts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  void reset() {
    _isListening = false;
    _isProcessing = false;
    _currentTranscript = '';
    _currentResponse = '';
    _speech.stop();
    _tts.stop();
    _notifyListeners();
    _mode = VoiceMode.normal;
  }
}
