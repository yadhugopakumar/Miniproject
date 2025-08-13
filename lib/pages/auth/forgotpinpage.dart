import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Hivemodel/user_settings.dart';
import '../../utils/customsnackbar.dart';
import '../../utils/successdialogue.dart';

class ForgotPinPage extends StatefulWidget {
  const ForgotPinPage({super.key});

  @override
  State<ForgotPinPage> createState() => _ForgotPinPageState();
}

class _ForgotPinPageState extends State<ForgotPinPage> {
  final phoneController = TextEditingController();
  String? question;
  String answerInput = '';
  String newPin = '';
  String? correctAnswer;
  bool isPhoneVerified = false;
  bool isVerified = false;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> _checkPhone() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      AppSnackbar.show(context, message: "Enter phone number", success: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('user_settings')
          .select('id')
          .eq('phone', phone)
          .maybeSingle();

      if (response == null) {
        AppSnackbar.show(context, message: "Phone not found", success: false);
        setState(() => _isLoading = false);
        return;
      }

      final userSettings = await supabase
          .from('user_settings')
          .select('security_question, security_answer')
          .eq('phone', phone)
          .maybeSingle();

      if (userSettings == null) {
        AppSnackbar.show(context,
            message: "No security question set for this account",
            success: false);
      } else {
        setState(() {
          question = userSettings['security_question'];
          correctAnswer = userSettings['security_answer'];
          isPhoneVerified = true;
        });
      }
    } catch (e) {
      AppSnackbar.show(context,
          message: "Error checking phone", success: false);
    }

    setState(() => _isLoading = false);
  }

  void _verifyAnswer() {
    if (answerInput.trim().toLowerCase() ==
        correctAnswer?.trim().toLowerCase()) {
      setState(() {
        isVerified = true;
      });
    } else {
      AppSnackbar.show(context, message: "Incorrect answer", success: false);
    }
  }

  Future<void> _updatePin() async {
    if (newPin.length != 4 || int.tryParse(newPin) == null) {
      AppSnackbar.show(context,
          message: "Enter a valid 4-digit PIN", success: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phone = phoneController.text.trim();
      final childRecord = await supabase
          .from('user_settings')
          .select('child_id')
          .eq('phone', phone)
          .maybeSingle();

      if (childRecord == null) {
        AppSnackbar.show(context,
            message: "User not found on server", success: false);
        setState(() => _isLoading = false);
        return;
      }

      final childId = childRecord['child_id'];

      await supabase
          .from('user_settings')
          .update({'pin': newPin}).eq('child_id', childId);

      // Update locally
      final userBox = Hive.box<UserSettings>('settingsBox');
      final localUser = userBox.get('user');
      if (localUser != null) {
        final updatedUser = UserSettings(
            username: localUser.username,
            pin: newPin,
            alarmSound: localUser.alarmSound,
            securityQuestion: localUser.securityQuestion,
            securityAnswer: localUser.securityAnswer,
            phone: localUser.phone,
            parentEmail: localUser.parentEmail,
            childId: localUser.childId);
        await userBox.put('user', updatedUser);
      }

      showDialog(
        context: context,
        builder: (_) => const SuccessDialog(
          title: "Success",
          message: "PIN updated",
        ),
      );
    } catch (e) {
      print(e);
      AppSnackbar.show(context,
          message: "Failed to update PIN", success: false);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot PIN"),
        backgroundColor: Colors.green.shade600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
            ),
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: isPhoneVerified
                  ? SizedBox(
                      height: 10,
                    )
                  : ElevatedButton(
                      onPressed: _isLoading ? null : _checkPhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Next", style: TextStyle(fontSize: 16)),
                    ),
            ),
            SizedBox(
              height: 20,
            ),
            if (isPhoneVerified) ...[
              Text(
                question ?? '',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: "Your Answer",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => answerInput = v,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: isVerified
                    ? SizedBox(
                        height: 10,
                      )
                    : ElevatedButton(
                        onPressed: _verifyAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Verify",
                            style: TextStyle(fontSize: 16)),
                      ),
              ),
            ],
            SizedBox(
              height: 20,
            ),
            if (isVerified) ...[
              TextField(
                style: const TextStyle(
                    letterSpacing: 5, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: "New PIN",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (v) => newPin = v,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Update PIN",
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
