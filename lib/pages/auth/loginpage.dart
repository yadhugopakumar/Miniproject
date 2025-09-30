import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:medremind/Hivemodel/user_settings.dart';
import 'package:medremind/pages/auth/register.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Hivemodel/alarm_model.dart';
import '../../Hivemodel/medicine.dart';
import '../../reminder/services/alarm_service.dart';
import '../../services/fetch_and_store_medicine.dart';
import '../../utils/customsnackbar.dart';
import '../../utils/successdialogue.dart';
import 'loginforgotpassword.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isloginLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() => _isloginLoading = true);

    final phone = _nameController.text.trim(); // Assuming phone is entered here
    final pin = _pinController.text.trim();

    if (phone.isEmpty || pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _isloginLoading = false);

      AppSnackbar.show(context,
          message: "Please enter valid phone and 4-digit PIN", success: false);
      return;
    }

    final supabase = Supabase.instance.client;
    final userBox = Hive.box<UserSettings>('settingsBox');

    try {
      // Query user_settings by parent_phone and pin
      final response = await supabase
          .from('user_settings')
          .select()
          .eq('phone', phone)
          .eq('pin', pin) // Ideally store hashed PIN and verify accordingly
          .maybeSingle();

      if (response == null) {
        setState(() => _isloginLoading = false);

        AppSnackbar.show(context,
            message: "Invalid phone or PIN", success: false);
        return;
      }
      final pidResponse = await supabase
          .from('child_users')
          .select('parent_id')
          .eq('id', response['child_id'])
          .maybeSingle();

      // Map response data to UserSettings model
      final userSettings = UserSettings(
        parentId: pidResponse?['parent_id'],
        username: response['username'] ?? '',
        pin: response['pin'] ?? '', // Store hashed if implemented
        alarmSound: response['alarm_sound'] ?? 'default_alarm.mp3',
        securityQuestion: response['security_question'] ?? '',
        securityAnswer: response['security_answer'] ?? '',
        phone: response['phone'] ?? '',
        parentEmail: response['parent_email'] ?? '',
        childId: response['child_id'], // <-- store child_id
      );
      // Store fetched user settings locally in Hive
      await userBox.put('user', userSettings);

      // Mark user as logged in
      Hive.box('session').put('loggedIn', true);
      Hive.box('session').put('username', userSettings.username);
      Hive.box('session').put('childId', userSettings.childId);

      // final session = Hive.box('session');

// ✅ Fetch medicines after login
      await _fetchMedicinesAndScheduleAlarms(userSettings.childId);
      // print(session.get('childId'));
      // Navigate to the PIN page (or desired page)
      setState(() => _isloginLoading = false);

      showDialog(
        context: context,
        builder: (_) => const SuccessDialog(
          title: "Login Success",
          message: "Welcome back! Unlock your app using your PIN.",
        ),
      );

      // avigate to PinPage
    } on PostgrestException catch (e) {
      debugPrint("Supabase error full: ${e.toJson()}");
      setState(() => _isloginLoading = false);

      AppSnackbar.show(context, message: "Server Error", success: false);
    } catch (e) {
      debugPrint("Unexpected error: $e");
      setState(() => _isloginLoading = false);

      AppSnackbar.show(context,
          message: "Unexpected error, please try again", success: false);
    }
  }

  Future<void> _fetchMedicinesAndScheduleAlarms(String childId) async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch medicines for this child
      final response = await supabase
          .from('medicine')
          .select()
          .eq('child_id', childId)
          .order('id', ascending: true);

      if (response.isEmpty) {
        debugPrint("⚠️ No medicines found for child $childId");
        return;
      }

      // Hive boxes
      final medicinesBox = Hive.box<Medicine>('medicinesBox');
      final alarmsBox = Hive.box<AlarmModel>('alarms');

      // Clear old data
      await medicinesBox.clear();
      await alarmsBox.clear();

      for (final item in response) {
        // Map to Medicine model
        final medicine = Medicine(
          id: item['id'].toString(),
          name: item['name'],
          dosage: item['dosage'],
          expiryDate: DateTime.parse(item['expiry_date']),
          dailyIntakeTimes: List<String>.from(item['daily_intake_times'] ?? []),
          totalQuantity: item['total_quantity'],
          quantityLeft: item['quantity_left'],
          refillThreshold: item['refill_threshold'],
          instructions: item['instructions'],
        );

        // Save to medicines box
        await medicinesBox.put(medicine.id, medicine);

        // 🔔 Create alarms for each intake time
        for (final time in medicine.dailyIntakeTimes) {
          final parts = time.split(":");
          if (parts.length == 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);

            // Unique alarm id per medicine + time
            final alarmId = '${medicine.id}-$hour$minute'.hashCode;

            final alarm = AlarmModel(
              id: alarmId,
              title: 'Medicine Reminder',
              description: 'Time to take your medicine',
              dosage: medicine.dosage,
              hour: hour,
              minute: minute,
              medicineName: medicine.name,
              isActive: true,
              isRepeating: true, // make true if you want daily repeat
            );

            // ✅ Save & schedule alarm via service
            await AlarmService.saveAlarm(alarm);

            debugPrint(
                "✅ Scheduled alarm for ${medicine.name} at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
          }
        }
      }

      fetchAndStoreRecentHistory();
    } catch (e, st) {
      debugPrint("❌ Failed to fetch medicines or schedule alarms: $e");
      debugPrintStack(stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundGreen = Color(0xFF166D5B);
    const Color iconGreen = Color(0xFF388A6D);

    return Scaffold(
      backgroundColor: backgroundGreen,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: iconGreen,
                  child: Icon(Icons.medication_liquid_rounded,
                      size: 70, color: Colors.white),
                ),
                const SizedBox(height: 32),
                const Text("Welcome Back!",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                const Text("Please log in to continue",
                    style: TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Phone",
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: Colors.white, letterSpacing: 16, fontSize: 22),
                  decoration: InputDecoration(
                    labelText: "4-digit PIN",
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    counterText: "",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isloginLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : const Text("Login",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Don't have an account? Register",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 17.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginForgotPinPage()),
                            );
                          },
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 218, 238, 255),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
