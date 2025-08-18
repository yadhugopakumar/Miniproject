import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:medremind/pages/auth/loginpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Hivemodel/user_settings.dart';
import '../../utils/customsnackbar.dart';
import '../../utils/successdialogue.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;
  bool _obscurePin = true; // Add this in your State

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
    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final answer = _answerController.text.trim();
    final phone = _phoneController.text.trim();
    final parentEmail = _parentEmailController.text.trim();

    // Basic validation
    if (name.isEmpty ||
        pin.length != 4 ||
        int.tryParse(pin) == null ||
        answer.isEmpty ||
        _selectedQuestion == null ||
        phone.isEmpty ||
        parentEmail.isEmpty ||
        !parentEmail.contains('@')) {
      setState(() => _isLoading = false);

      AppSnackbar.show(context,
          message: "Please fill all fields correctly", success: false);
      return;
    }

    // // Check local duplicate username
    final userBox = Hive.box<UserSettings>('settingsBox');
    // if (userBox.values.any((u) => u.username == name)) {
    //   setState(() => _isLoading = false);
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Username already exists locally.")),
    //   );
    //   return;
    // }

    final supabase = Supabase.instance.client;

    try {
      // 1️⃣ Fetch child + parent
      final result = await supabase
          .from('child_users')
          .select('id, child_phone,parent_id, parent:parent_profiles(email)')
          .eq('child_phone', phone)
          .maybeSingle();
     
      if (result == null || result['parent'] == null) {
        setState(() => _isLoading = false);

        AppSnackbar.show(context,
            message: "Child phone or linked parent not found", success: false);
        return;
      }

      final fetchedParentEmail = result['parent']?['email'];
      final childId = result['id'];
      final parentId = result['parent_id'];

      if (fetchedParentEmail == null || fetchedParentEmail != parentEmail) {
        setState(() => _isLoading = false);

        AppSnackbar.show(context,
            message: "Parent email does not match.", success: false);
        return;
      }

      // 2️⃣ Check in DB if this child is already registered in user_settings
      final existingSettings = await supabase
          .from('user_settings')
          .select('id')
          .eq('child_id', childId)
          .maybeSingle();

      if (existingSettings != null) {
        setState(() => _isLoading = false);

        AppSnackbar.show(context,
            message: "User already registered. Please log in.", success: false);

        return;
      }

      // 3️⃣ Insert new settings
      final inserted = await supabase
          .from('user_settings')
          .insert({
            'child_id': childId,
            'username': name,
            'pin': pin, // later hash in production
            'phone': phone,
            'parent_email': fetchedParentEmail,
            'alarm_sound': 'alarm.mp3',
            'security_question': _selectedQuestion!,
            'security_answer': answer,
          })
          .select()
          .maybeSingle();

      if (inserted == null) throw Exception("Insert returned null");

      // 4️⃣ Save locally
      final user = UserSettings(
        parentId: parentId,
        username: name,
        pin: pin,
        alarmSound: 'alarm.mp3',
        securityQuestion: _selectedQuestion!,
        securityAnswer: answer,
        phone: phone,
        parentEmail: fetchedParentEmail,
        childId: childId, // ✅ use the variable you defined above
      );
      await userBox.put('user', user);

      showDialog(
        context: context,
        builder: (_) => const SuccessDialog(
          title: "Registration Success",
          message:
              "Your account has been created.enter the PIN to unloack app.",
        ),
      );
    } on PostgrestException catch (e) {
      debugPrint("Supabase error full: ${e.toJson()}");

      AppSnackbar.show(context,
          message: "Failed to register: Server Error", success: false);
    } catch (e) {
      AppSnackbar.show(context,
          message: "Unexpected error, please try again", success: false);
    } finally {
      setState(() => _isLoading = false);
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
                  const CircleAvatar(
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
                    obscureText: _obscurePin,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      letterSpacing: 16,
                      fontSize: 22,
                    ),
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
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          icon: Icon(
                            _obscurePin
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePin = !_obscurePin;
                            });
                          },
                        ),
                      ),
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
