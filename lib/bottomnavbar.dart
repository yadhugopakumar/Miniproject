import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:medremind/Hivemodel/alarm_model.dart';
import 'package:medremind/Hivemodel/chat_message.dart';
import 'package:medremind/pages/auth/loginpage.dart';
import 'package:medremind/pages/chatpage.dart';
import 'package:medremind/pages/homepage.dart';
import 'package:medremind/pages/innerpages/profilepage.dart';
import 'package:medremind/pages/innerpages/reportpage.dart';
import 'package:medremind/pages/refillpage.dart';
import 'package:medremind/pages/historypage.dart';
import 'package:medremind/utils/customsnackbar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chatmanager/chat_manager.dart';
import '../chatmanager/voice_chat_overlay.dart';

import 'Hivemodel/health_report.dart';
import 'Hivemodel/history_entry.dart';
import 'Hivemodel/medicine.dart';
import 'Hivemodel/user_settings.dart';

class Bottomnavbar extends StatefulWidget {
  final int initialIndex;
  const Bottomnavbar({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<Bottomnavbar> createState() => _BottomnavbarState();
}

class _BottomnavbarState extends State<Bottomnavbar>
    with TickerProviderStateMixin {
  late int _selectedIndex;
  DateTime? _lastBackPressTime;

// Use childId for further queries, navigation, etc.
  final session = Hive.box('session');
//for chat
  final VoiceChatManager _voiceManager = VoiceChatManager();
  bool _showVoiceOverlay = false;
  //for chatpage
  final AudioPlayer _player = AudioPlayer();
  late AnimationController _bottomBarController;
  late Animation<Offset> _bottomBarAnimation;

  final List<String> availableSounds = [
    "alarm1.mp3",
    "alarm2.mp3",
    "alarm3.mp3",
  ];
  String? _selectedSound;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Initialize animation controller
    _bottomBarController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this, // Add TickerProviderStateMixin to your class
    );

    _bottomBarAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0.0, 2.5), // Move down by 1.5x its height
    ).animate(CurvedAnimation(
      parent: _bottomBarController,
      curve: Curves.easeInOut,
    ));

    _voiceManager.initialize();
    _voiceManager.onStateChanged = () {
      setState(() {
        bool shouldShowOverlay =
            _voiceManager.isListening || _voiceManager.isProcessing;

        if (_showVoiceOverlay != shouldShowOverlay) {
          _showVoiceOverlay = shouldShowOverlay;

          if (_showVoiceOverlay) {
            _bottomBarController.forward();
          } else {
            _bottomBarController.reverse();
          }
        }
      });
    };

    getSelectedSound().then((value) {
      setState(() => _selectedSound = value);
    });
    _requestPermissions();
  }

  Future<void> saveSelectedSound(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("selectedSound", path);
  }

  Future<String> getSelectedSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("selectedSound") ?? availableSounds.first;
  }

  Future _requestPermissions() async {
    await Permission.notification.request();
    await Permission.ignoreBatteryOptimizations.request();
    await Permission.ignoreBatteryOptimizations.request();

    // Check and request exact alarm permission specifically
    final status = await Permission.scheduleExactAlarm.status;
    print('Schedule exact alarm permission: $status.');
    if (status.isDenied) {
      print('Requesting schedule exact alarm permission...');
      final res = await Permission.scheduleExactAlarm.request();
      print(
          'Schedule exact alarm permission ${res.isGranted ? '' : 'not'} granted.');
    }
  }

  bool _vibrationEnabled = true; // default

  void _chooseSound() async {
    String? sound = await showDialog<String>(
      context: context,
      builder: (context) {
        String? selectedSound = _selectedSound;
        bool tempVibration = _vibrationEnabled;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Choose Notification Sound"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // List of sounds with preview on tap
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableSounds.length,
                  itemBuilder: (context, index) {
                    final soundFile = availableSounds[index];
                    return RadioListTile<String>(
                      title: Text(soundFile),
                      value: soundFile,
                      groupValue: selectedSound,
                      onChanged: (value) async {
                        setState(() => selectedSound = value);

                        // play preview
                        await _player.stop();
                        await _player.play(AssetSource("sounds/$soundFile"));
                        print("Playing $soundFile");
                      },
                    );
                  },
                ),
                const Divider(),
                // Vibration toggle
                SwitchListTile(
                  title: const Text("Vibration"),
                  secondary: const Icon(Icons.vibration),
                  value: tempVibration,
                  onChanged: (val) {
                    setState(() => tempVibration = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _player.stop();
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _vibrationEnabled = tempVibration;
                    _selectedSound = selectedSound;
                  });
                  saveSelectedSound(_selectedSound!);
                  saveVibrationPref(_vibrationEnabled);

                  _player.stop();
                  Navigator.pop(context, selectedSound);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Save vibration preference
  Future<void> saveVibrationPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("vibrationEnabled", value);
  }

  /// Load vibration preference
  Future<bool> getVibrationPref() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("vibrationEnabled") ?? true;
  }

  void _handleMicPressed() {
    print("Mic button pressed"); // Debug log

    // Reset the manager state first
    _voiceManager.reset();

    // Clear any existing callbacks and set new ones
    _voiceManager.onStateChanged = () {
      if (mounted) {
        print(
            "State changed - listening: ${_voiceManager.isListening}, processing: ${_voiceManager.isProcessing}"); // Debug log
        setState(() {
          bool shouldShowOverlay =
              _voiceManager.isListening || _voiceManager.isProcessing;

          if (_showVoiceOverlay != shouldShowOverlay) {
            _showVoiceOverlay = shouldShowOverlay;
            print(
                "Overlay visibility changed to: $_showVoiceOverlay"); // Debug log

            if (_showVoiceOverlay) {
              _bottomBarController.forward();
            } else {
              _bottomBarController.reverse();
            }
          }
        });
      }
    };

    // Set error and answer callbacks
    _voiceManager.onShowError = (error) {
      if (mounted) {
        AppSnackbar.show(context, message: error, success: false);
      }
    };
    void _showAnswer(String text) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.green[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated AI icon
                    TweenAnimationBuilder(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 800),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[400]!, Colors.green[400]!],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.assistant,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 16),

                    Text(
                      'MedRemind Assistant',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Response with subtle background
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blue[100]!,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),

                    SizedBox(height: 24),

                    // Single action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Got it! 👍',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    _voiceManager.onShowAnswer = (response) {
      if (mounted) {
        _showAnswer(response);
      }
    };

    // Start listening
    _voiceManager.startListening();
  }

  void _closeVoiceOverlay() {
    print("Closing voice overlay"); // Debug log
    _voiceManager.reset();
    if (mounted) {
      setState(() {
        _showVoiceOverlay = false;
      });
      _bottomBarController.reverse();
    }
  }

  @override
  void dispose() {
    _bottomBarController.dispose();
    _voiceManager.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    const Homepage(),
    Chatpage(),
    const HistoryPage(),
    const RefillTrackerPage()
  ];
  bool isNotificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        DateTime now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          Fluttertoast.showToast(
            msg: "Press back again to exit",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
          return false; // Don't exit yet
        }
        return true; // Exit app
      },
      child: Scaffold(
        drawer: _buildDrawer(), // << Add this here
        extendBody: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _selectedIndex != 1
            ? AnimatedContainer(
                duration: Duration(milliseconds: 300),
                transform: Matrix4.translationValues(
                    0,
                    _showVoiceOverlay
                        ? 200
                        : 0, // Move FAB down when overlay is active
                    0),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Material(
                    color: const Color.fromARGB(255, 93, 255, 101),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                    elevation: 20,
                    child: Container(
                      height: 65.0,
                      width: 65.0,
                      child: FloatingActionButton(
                        // backgroundColor: Color.fromARGB(255, 75, 44, 90),
                        backgroundColor: const Color.fromARGB(255, 16, 59, 65),

                        onPressed: _handleMicPressed,
                        child: const Icon(
                          Icons.mic_none_sharp,
                          size: 33,
                          color: Color.fromARGB(255, 174, 233, 156),
                          // color: Color.fromARGB(255, 255, 216, 42),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        bottomNavigationBar: _selectedIndex != 1
            ? SlideTransition(
                position: _bottomBarAnimation,
                child: AbsorbPointer(
                  absorbing: _showVoiceOverlay,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 10, right: 10, bottom: 15),
                    child: BottomAppBar(
                      color: Colors.transparent,
                      shape: const CircularNotchedRectangle(),
                      notchMargin: 6.0,
                      elevation: 0,
                      child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green[900]!.withOpacity(0.85),
                            // color: Colors.purple[900]!.withOpacity(0.8),

                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.green[900]!,
                              width: 0.1,
                            ),
                          ),
                          height: kToolbarHeight + 5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildNavItem(
                                  icon: Icons.home_outlined,
                                  index: 0,
                                  label: "Home"),
                              _buildNavItem(
                                icon: Icons.message_outlined,
                                index: 1,
                                label: "Chat",
                              ),
                              Stack(
                                alignment: Alignment.topCenter,
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 8,
                                    height: 50,
                                    color: Colors
                                        .transparent, // optional background placeholder
                                  ),
                                  Positioned(
                                    top:
                                        -48, // half of height to make it overlap nicely
                                    child: Container(
                                      width: 75,
                                      height: 75,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              _buildNavItem(
                                  icon: Icons.history_rounded,
                                  index: 2,
                                  label: "History"),
                              _buildNavItem(
                                  icon: Icons.recycling_outlined,
                                  index: 3,
                                  label: "Refill"),
                            ],
                          )),
                    ),
                  ),
                ),
              )
            : null,
        body: Stack(
          // Wrap body in Stack
          children: [
            _pages[_selectedIndex],

            // Voice Chat Overlay
            if (_showVoiceOverlay)
              VoiceChatOverlay(
                onClose: _closeVoiceOverlay,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          // Navigate only for Chat
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Chatpage()),
          );
        } else {
          // Bottom bar behavior for others
          setState(() => _selectedIndex = index);
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 5.4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: isSelected
              ? const Color.fromARGB(255, 165, 255, 123)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: isSelected
                  ? const TextStyle(fontSize: 12, color: Colors.black)
                  : const TextStyle(
                      fontSize: 12, color: Color.fromARGB(255, 240, 240, 240)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box<UserSettings>('settingsBox').listenable(),
      builder: (context, box, widget) {
        String username = 'Guest User';

        final user = box.get('user');
        if (user != null) {
          username = user.username;
        }

        return Drawer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.green[800],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 32,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green,
                        child: Icon(
                          Icons.person_2,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      username,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Notification Sound
                    ListTile(
                      leading: const Icon(Icons.notifications_active,
                          color: Colors.orange),
                      title: const Text("Sound and Vibration"),
                      subtitle: Text(_selectedSound ?? "Default"),
                      onTap: _chooseSound,
                    ),
                    // Vibration

                    const Divider(),
                    // Profile
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: ListTile(
                          leading:
                              const Icon(Icons.person_pin, color: Colors.green),
                          title: const Text('Profile',
                              style: TextStyle(color: Colors.green)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Profilepage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Health Reports
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.favorite_rounded,
                              color: Colors.red),
                          title: const Text(
                            'Health Reports',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Reportspage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Logout
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[400]!),
                    color: const Color.fromARGB(255, 182, 182, 182),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.black),
                    title: const Text("Logout",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor:
                              const Color.fromARGB(255, 227, 255, 227),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: const Text(
                            "Confirm Logout",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color.fromARGB(255, 61, 13, 1),
                            ),
                          ),
                          content: const Text(
                            "Are you sure you want to logout?",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await Hive.box<UserSettings>('settingsBox')
                                    .clear();
                                await Hive.box<Medicine>('medicinesBox')
                                    .clear();
                                await Hive.box<HistoryEntry>('historyBox')
                                    .clear();
                                await Hive.box<ChatMessage>('chatMessages')
                                    .clear();
                                await Hive.box<HealthReport>('healthReportsBox')
                                    .clear();
                                await Hive.box<AlarmModel>('alarms').clear();
                                await Hive.box('session').clear();

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginPage()),
                                );
                              },
                              child: const Text(
                                "Logout",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
