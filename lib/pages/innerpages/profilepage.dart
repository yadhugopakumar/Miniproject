import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:another_flushbar/flushbar.dart';

import '../../Hivemodel/user_settings.dart';
import '../../utils/customsnackbar.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  late Box<UserSettings> settingsBox;
  UserSettings? user;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    var box = await Hive.openBox<UserSettings>('settingsBox');
    setState(() {
      if (box.isNotEmpty) {
        user = box.getAt(0);
      }
    });
  }

  void _showFlush(String msg, {bool isSuccess = true}) {
    Flushbar(
      message: msg,
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      messageColor: Colors.black,
      icon: Icon(
        isSuccess ? Icons.check_circle : Icons.error,
        color: Colors.green[500],
      ),
      leftBarIndicatorColor: isSuccess ? Colors.green[300] : Colors.red,
    ).show(context);
  }

  // Updated PIN change method matching your ForgotPinPage pattern
  void _changePin() {
    TextEditingController oldPin = TextEditingController();
    TextEditingController newPin = TextEditingController();
    TextEditingController confirmPin = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Change PIN",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: oldPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: "Current PIN",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  counterText: "",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: "New PIN",
                  prefixIcon: const Icon(Icons.lock_reset),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  counterText: "",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: "Confirm New PIN",
                  prefixIcon: const Icon(Icons.lock_clock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  counterText: "",
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _updatePin(
                              oldPin.text, newPin.text, confirmPin.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Update PIN"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated PIN update method following your ForgotPinPage pattern
  Future<void> _updatePin(
      String oldPin, String newPin, String confirmPin) async {
    // Validation
    if (oldPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
      AppSnackbar.show(context,
          message: "Please fill all fields", success: false);
      return;
    }

    if (newPin.length != 4 || int.tryParse(newPin) == null) {
      AppSnackbar.show(context,
          message: "Enter a valid 4-digit PIN", success: false);
      return;
    }

    if (newPin != confirmPin) {
      AppSnackbar.show(context,
          message: "New PINs don't match", success: false);
      return;
    }

    if (user == null || user!.pin != oldPin) {
      AppSnackbar.show(context,
          message: "Incorrect current PIN", success: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update in Supabase first (following your pattern)
      final supabase = Supabase.instance.client;
      await supabase
          .from('user_settings')
          .update({'pin': newPin}).eq('child_id', user!.childId);

      // Update locally in Hive (following your exact pattern)
      final userBox = Hive.box<UserSettings>('settingsBox');
      final localUser = userBox.get('user');
      if (localUser != null) {
        final updatedUser = UserSettings(
          parentId: localUser.parentId,
          username: localUser.username,
          pin: newPin, // Updated PIN
          alarmSound: localUser.alarmSound,
          securityQuestion: localUser.securityQuestion,
          securityAnswer: localUser.securityAnswer,
          phone: localUser.phone,
          parentEmail: localUser.parentEmail,
          childId: localUser.childId,
        );
        await userBox.put('user', updatedUser);

        // Update the current user reference
        setState(() {
          user = updatedUser;
        });
      }

      // Close the dialog first
      if (mounted) Navigator.of(context).pop();

      // Show success dialog (following your pattern)
      _showFlush("PIN updated successfully");
    } catch (e) {
      print('Error updating PIN: $e');
      AppSnackbar.show(context,
          message: "Failed to update PIN", success: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

//update name methods and popup dialog
  void _editName() {
    final nameController = TextEditingController(text: user?.username ?? '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Name",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: "New Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _updateName(nameController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Update Name"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateName(String newName) async {
    if (newName.trim().isEmpty || newName.length < 3) {
      AppSnackbar.show(context, message: "Enter a valid name", success: false);
      return;
    }
    if (newName.trim() == user!.username) {
      AppSnackbar.show(context,
          message: "Name is same as previous", success: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update on Supabase
      if (user?.childId != null) {
        final supabase = Supabase.instance.client;
        await supabase
            .from('user_settings')
            .update({'username': newName.trim()}).eq('child_id', user!.childId);
      }

      // Update locally in Hive
      final userBox = Hive.box<UserSettings>('settingsBox');
      final localUser = userBox.get('user');
      if (localUser != null) {
        final updatedUser = UserSettings(
          parentId: localUser.parentId,
          username: newName.trim(), // Updated name
          pin: localUser.pin,
          alarmSound: localUser.alarmSound,
          securityQuestion: localUser.securityQuestion,
          securityAnswer: localUser.securityAnswer,
          phone: localUser.phone,
          parentEmail: localUser.parentEmail,
          childId: localUser.childId,
        );
        await userBox.put('user', updatedUser);
        setState(() {
          user = updatedUser;
        });
      }

      if (mounted) Navigator.of(context).pop();

      _showFlush("Name updated successfully");
    } catch (e) {
      AppSnackbar.show(context,
          message: "Failed to update name", success: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green[600],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No profile found",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[800]!, Colors.green[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user!.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Medicine Reminder User",
                          style: TextStyle(
                            color: Colors.blue[100],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Profile Details Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "Personal Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        _buildProfileTile(
                          icon: Icons.person_outline,
                          title: user!.username,
                          subtitle: "Full Name",
                          iconColor: Colors.green[700]!,
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 215, 250, 255),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: _isLoading ? null : _editName,
                              child: Icon(
                                Icons.edit,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        _buildDivider(),
                        _buildProfileTile(
                          icon: Icons.email_outlined,
                          title: user!.parentEmail ?? "Not provided",
                          subtitle: "Prent Email Address",
                          iconColor: Colors.green[700]!,
                        ),
                        _buildDivider(),
                        _buildProfileTile(
                          icon: Icons.phone_outlined,
                          title: user!.phone ?? "Not provided",
                          subtitle: "Phone Number",
                          iconColor: Colors.orange[700]!,
                        ),
                        _buildDivider(),
                        _buildProfileTile(
                          icon: Icons.lock_outline,
                          title: "• • • •",
                          subtitle: "Security PIN",
                          iconColor: Colors.red[700]!,
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: _changePin,
                              child: Icon(
                                Icons.edit,
                                color: Colors.red[700],
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(Icons.settings, color: Colors.grey[700]),
                              const SizedBox(width: 12),
                              Text(
                                "Actions",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showFlush(
                                    "Profile update feature coming soon!");
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text("Edit Profile"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
      indent: 68,
      endIndent: 20,
    );
  }
}
