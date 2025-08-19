import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Hivemodel/user_settings.dart';
import '../../utils/customsnackbar.dart';
import '../../utils/successdialogue.dart';

class LoginForgotPinPage extends StatefulWidget {
  @override
  _LoginForgotPinPageState createState() => _LoginForgotPinPageState();
}

class _LoginForgotPinPageState extends State<LoginForgotPinPage> {
  final phoneController = TextEditingController();
  final answerController = TextEditingController();
  final newPinController = TextEditingController();
  bool _isphoneloading = false;
  bool _isanswerloading = false;
  bool _ispinloading = false;

  String? securityQuestion;
  bool showQuestion = false;
  bool showResetPin = false;
  String? correctAnswer = '';
  final supabase = Supabase.instance.client;

  Future<void> fetchSecurityQuestion() async {
    setState(() {
      _isphoneloading = true; // start loading
    });

    final phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      setState(() {
        _isphoneloading = false; // stop loading
      });
      AppSnackbar.show(context,
          message: "Enter a valid phone number", success: false);
      return;
    }

    try {
      final response = await supabase
          .from('user_settings')
          .select('security_question, security_answer')
          .eq('phone', phone) // probably parent_phone in your schema
          .maybeSingle();

      setState(() {
        _isphoneloading = false; // stop loading after query
      });

      if (response == null) {
        AppSnackbar.show(context, message: "Phone not found", success: false);
        return;
      }

      securityQuestion = response['security_question'];
      correctAnswer = response['security_answer']?.toString();

      if (correctAnswer == null || correctAnswer!.isEmpty) {
        AppSnackbar.show(context,
            message: "Security question not set", success: false);
        return;
      }

      setState(() => showQuestion = true);
    } catch (e) {
      setState(() {
        _isphoneloading = false;
      });
      AppSnackbar.show(context,
          message: "Error fetching security question", success: false);
    }
  }

  void checkAnswer() {
    setState(() {
      _isanswerloading = true; // start loading
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      // simulate async if you ever make it API call
      if (answerController.text.trim().toLowerCase() ==
          correctAnswer?.trim().toLowerCase()) {
        setState(() {
          _isanswerloading = false; // stop loading
          showResetPin = true;
        });
      } else {
        setState(() {
          _isanswerloading = false; // stop loading
        });
        AppSnackbar.show(context, message: "Incorrect answer", success: false);
      }
    });
  }

  Future<void> resetPin() async {
    setState(() {
      _ispinloading = true; // start loading
    });

    final newPin = newPinController.text.trim();
    if (newPin.length != 4 || int.tryParse(newPin) == null) {
      setState(() => _ispinloading = false); // stop loading
      AppSnackbar.show(context,
          message: "PIN must be 4 digits", success: false);
      return;
    }

    try {
      final result = await supabase
          .from('user_settings')
          .update({'pin': newPin})
          .eq('phone', phoneController.text.trim()) // use correct col name
          .select();

      setState(() {
        _ispinloading = false; // stop loading after query
      });

      if (result.isEmpty) {
        AppSnackbar.show(context,
            message: "Failed to update PIN", success: false);
        return;
      }
      // Step 2: Fetch updated full user record
      final updatedUserResponse = await supabase
          .from('user_settings')
          .select()
          .eq('phone', phoneController.text.trim())
          .maybeSingle();

      if (updatedUserResponse != null) {
        // Step 3: Save to Hive
        final userBox = Hive.box<UserSettings>('settingsBox');
        final updatedUser = UserSettings(
          parentId: updatedUserResponse['parent_id'] ?? '',
          childId: updatedUserResponse['child_id'] ?? '',
          username: updatedUserResponse['username'] ?? '',
          pin: updatedUserResponse['pin'] ?? '',
          alarmSound: updatedUserResponse['alarm_sound'] ?? '',
          securityQuestion: updatedUserResponse['security_question'] ?? '',
          securityAnswer: updatedUserResponse['security_answer'] ?? '',
          phone: updatedUserResponse['phone'] ?? '',
          parentEmail: updatedUserResponse['parent_email'] ?? '',
        );

        await userBox.put('user', updatedUser);
      }
      showDialog(
        context: context,
        builder: (_) => const SuccessDialog(
          title: "Success",
          message: "PIN changed successfully",
        ),
      );
    } catch (e) {
      setState(() {
        _ispinloading = false; // stop loading
      });
      AppSnackbar.show(context, message: "Error updating PIN", success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forgot PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: fetchSecurityQuestion,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                child: _isphoneloading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text('Next'),
              ),
            ),
            if (showQuestion) ...[
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  securityQuestion ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextField(
                controller: answerController,
                decoration: InputDecoration(
                  labelText: "Your Answer",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.name,
              ),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: checkAnswer,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                  child: _isanswerloading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text('Verify Answer'),
                ),
              ),
            ],
            if (showResetPin) ...[
              SizedBox(height: 20),
              TextField(
                style: const TextStyle(
                    letterSpacing: 5, fontWeight: FontWeight.bold),
                controller: newPinController,
                decoration: InputDecoration(
                  labelText: "New PIN",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: resetPin,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                  child: _ispinloading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text('Reset PIN '),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
