
import 'package:flutter/material.dart';
import 'package:medremind/bottomnavbar.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../services/auth_services.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AuthService _auth = AuthService();
  String enteredPin = '';

  void _verifyPin(String pin) {
    if (_auth.validatePin(pin)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Bottomnavbar()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.green[700],
                    child: const Icon(Icons.medication_liquid_rounded,
                        size: 90, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text('MedRemind',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 25),
                  const Text('Welcome Back',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: Colors.white)),
                  const Text('Please enter your 4-digit PIN',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w300)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: PinCodeTextField(
                length: 4,
                obscureText: true,
                animationType: AnimationType.scale,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(25),
                  fieldHeight: 50,
                  fieldWidth: 50,
                  selectedFillColor: Colors.white,
                  activeFillColor: Colors.teal.shade100,
                  selectedColor: Colors.grey,
                  inactiveColor: Colors.grey,
                  inactiveFillColor: Colors.green[100],
                ),
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
                onChanged: (value) => enteredPin = value,
                appContext: context,
                onCompleted: _verifyPin,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // You can redirect to a forgot screen or show a dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Forgot PIN coming soon!")),
                );
              },
              child: const Text('Forgot PIN?',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
