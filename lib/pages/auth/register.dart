//   void _register() async {
//     final name = _nameController.text.trim();
//     final pin = _pinController.text.trim();
//     final answer = _answerController.text.trim();
//     final phone = _phoneController.text.trim();
//     final parentEmail = _parentEmailController.text.trim();

//     if (name.isEmpty ||
//         pin.length != 4 ||
//         int.tryParse(pin) == null ||
//         answer.isEmpty ||
//         _selectedQuestion == null ||
//         phone.isEmpty ||
//         parentEmail.isEmpty ||
//         !parentEmail.contains('@')) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please fill all fields correctly.")),
//       );
//       return;
//     }

//     final userBox = Hive.box<UserSettings>('settingsBox');

//     // ✅ Prevent duplicate usernames
//     if (userBox.values.any((u) => u.username == name)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text("Username already exists. Choose another.")),
//       );
//       return;
//     }

//     final user = UserSettings(
//       username: name,
//       pin: pin,
//       alarmSound: 'alarm.mp3',
//       securityQuestion: _selectedQuestion!,
//       securityAnswer: answer,
//       phone: phone,
//       parentEmail: parentEmail,
//     );

//     await userBox.put('user',
//         user); // You can make this .put(name, user) to use username as key

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const LockScreen()),
//     );
//   }

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:medremind/pages/auth/loginpage.dart';
import 'package:medremind/pages/auth/pinlogin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Hivemodel/user_settings.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _answerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentEmailController = TextEditingController();

  // Example security questions
  final List<String> _questions = [
    'What is your favorite color?',
    'What is your car name?',
    'What is your pet\'s name?',
    'What is your favorite food?',
  ];
  String? _selectedQuestion;

  @override
  void initState() {
    super.initState();
    _selectedQuestion = _questions[0];
  }

  void _register() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final answer = _answerController.text.trim();
    final phone = _phoneController.text.trim();
    final parentEmail = _parentEmailController.text.trim();

    if (name.isEmpty ||
        pin.length != 4 ||
        int.tryParse(pin) == null ||
        answer.isEmpty ||
        _selectedQuestion == null ||
        phone.isEmpty ||
        parentEmail.isEmpty ||
        !parentEmail.contains('@')) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields correctly.")),
      );
      return;
    }

    final userBox = Hive.box<UserSettings>('settingsBox');

    // Prevent duplicate usernames locally
    if (userBox.values.any((u) => u.username == name)) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Username already exists. Choose another.")),
      );
      return;
    }

    final supabase = Supabase.instance.client;
    try {
      // 1️⃣ Fetch child + parent's email with join
      final result = await supabase
          .from('child_with_parent')
          .select()
          .eq('child_phone', phone)
          .maybeSingle();

      if (result == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Child phone not found.")),
        );
        return;
      }
      final fetchedParentEmail =
          result['email']; // direct access from view column

      if (fetchedParentEmail == null || fetchedParentEmail != parentEmail) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Parent email does not match.")),
        );
        return;
      }

      final insertRes = await supabase
          .from('user_settings')
          .insert({
            'child_id': result['child_id'], // from view alias
            'username': name,
            'pin': pin, // hash in real app
            'parent_phone': phone,
            'parent_email': fetchedParentEmail,
            'alarm_sound': 'alarm.mp3',
            'security_question': _selectedQuestion!,
            'security_answer': answer,
          })
          .select()
          .single(); // throws if >1 or error

      // If it reached here, insert succeeded:
      final user = UserSettings(
        username: name,
        pin: pin,
        alarmSound: 'alarm.mp3',
        securityQuestion: _selectedQuestion!,
        securityAnswer: answer,
        phone: phone,
        parentEmail: fetchedParentEmail,
      );

      await userBox.put('user', user);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LockScreen()),
      );
    } on PostgrestException catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Supabase error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to register: ${e.message}")),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unexpected error, please try again")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: iconGreen,
                    child: Icon(
                      Icons.medication_liquid_rounded,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App Name
                  const Text(
                    "MedRemind",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Welcome Text
                  const Text(
                    "Welcome!",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Please register with your details",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Name Field
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Name",
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          const Icon(Icons.person, color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 16),
// Parent Phone
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Mobile Number",
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          const Icon(Icons.phone, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 16),
// Parent Email
                  TextField(
                    controller: _parentEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Parent's Email",
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          const Icon(Icons.email, color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // PIN Field
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
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Security Question Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedQuestion,
                    isExpanded: true,
                    dropdownColor: backgroundGreen,
                    items: _questions
                        .map(
                          (q) => DropdownMenuItem(
                              value: q,
                              child: Text(q,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14))),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedQuestion = val;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Security Question",
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          const Icon(Icons.security, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  // Security Answer
                  TextField(
                    controller: _answerController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Your Answer",
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.question_answer,
                          color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Save & Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Text(
                              "Save & Continue",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Already Registered, Login",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
