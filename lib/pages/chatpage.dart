import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medremind/pages/screens/chat_med_add.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

import '../Hivemodel/chat_message.dart';
import '../chatmanager/ai_chat/chat_service.dart';
import '../chatmanager/ai_chat/chat_storage_service.dart';
import '../chatmanager/ai_chat/extractedmedicine.dart';
import '../chatmanager/ai_chat/extractedmedicine_storage.dart';
import '../chatmanager/ai_chat/gemini_provider.dart';
import '../bottomnavbar.dart';
import '../utils/customsnackbar.dart';

class Chatpage extends StatefulWidget {
  const Chatpage({super.key});

  @override
  State<Chatpage> createState() => _ChatpageState();
}

class _ChatpageState extends State<Chatpage> with TickerProviderStateMixin {
  late String apiKey;
  final TextEditingController controller = TextEditingController();
  late GeminiProvider provider;
  final ScrollController _scrollController = ScrollController();
  bool isThinking = false;
  final ImagePicker _picker = ImagePicker();
  bool _showWelcomeMessage = true; // Add this line
  bool _isFirstLoad = true; // Add this line
  // TTS related variables
  late FlutterTts flutterTts;
  bool isSpeaking = false;
  String currentSpeakingMessageId = '';
  late AnimationController _dotsController;
  // Auto-scroll related variables
  bool _shouldAutoScroll = true;
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    // apiKey = dotenv.env['API_KEY'] ?? "";
    apiKey = "AIzaSyDT1NimstllZmAz-mX56tFC03V4lOZp0OY";

    provider = GeminiProvider(apiKey: apiKey);
    _initTts();

    // _loadInitialMessages();
    _setupScrollListener();
    _showWelcomeMessage = true;
    // Call scroll after a delay to ensure everything is built
    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollToBottomAfterBuild();
    });

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(); // keeps looping
  }

  void _hideWelcomeMessage() {
    if (_showWelcomeMessage) {
      setState(() {
        _showWelcomeMessage = false;
      });
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final currentPosition = _scrollController.position.pixels;
      final maxPosition = _scrollController.position.maxScrollExtent;
      final distanceFromBottom = maxPosition - currentPosition;

      final showButton = distanceFromBottom > 100;
      if (showButton != _showScrollButton) {
        setState(() {
          _showScrollButton = showButton;
        });
      }

      _shouldAutoScroll = distanceFromBottom < 100;
    });
  }

  void _scrollToBottomAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients && mounted) {
          final double maxExtent = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(maxExtent);
          print("Scrolled to: $maxExtent"); // Debug print
        }
      });
    });
  }

  void _scrollToBottom(
      {bool animate = true, bool force = false, double extraOffset = 100}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        if (force || _shouldAutoScroll) {
          final double maxExtent = _scrollController.position.maxScrollExtent;
          final double targetPosition = maxExtent + extraOffset;

          if (animate) {
            _scrollController.animateTo(
              targetPosition,
              duration: const Duration(milliseconds: 50),
              curve: Curves.fastOutSlowIn,
            );
          } else {
            _scrollController.jumpTo(targetPosition);
          }
        }
      }
    });
  }

  void _loadInitialMessages() {
    if (_isFirstLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients && mounted) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
            _isFirstLoad = false;
            _shouldAutoScroll = true;
          }
        });
      });
    }
  }

  void _initTts() {
    flutterTts = FlutterTts();
    _configureTts();

    flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
        currentSpeakingMessageId = '';
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        isSpeaking = false;
        currentSpeakingMessageId = '';
      });
    });
  }

  Future<void> _configureTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.6);
    await flutterTts.setVolume(0.8);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speakText(String text, String messageId) async {
    if (isSpeaking && currentSpeakingMessageId == messageId) {
      await flutterTts.stop();
      return;
    } else if (isSpeaking) {
      await flutterTts.stop();
    }

    setState(() {
      currentSpeakingMessageId = messageId;
    });

    String cleanText = _cleanTextForTts(text);
    await flutterTts.speak(cleanText);
  }

  String _cleanTextForTts(String text) {
    return text
        .replaceAll('mg', ' milligrams')
        .replaceAll('ml', ' milliliters')
        .replaceAll('°C', ' degrees Celsius')
        .replaceAll('°F', ' degrees Fahrenheit')
        .replaceAll('BP', 'blood pressure')
        .replaceAll('HR', 'heart rate')
        .replaceAll('&', ' and ')
        .replaceAll('/', ' per ')
        .replaceAll(RegExp(r'[📄📊💊🩺]'), '');
  }

  Future<void> _processImage(File imageFile, String analysisType) async {
    _shouldAutoScroll = true;
    _hideWelcomeMessage();

    final userMessage = ChatMessage(
      role: 'user',
      content: analysisType == 'prescription'
          ? "📄 Prescription Image"
          : "📊 Health Report Image",
      timestamp: DateTime.now(),
      isAnimating: true,
      hasImage: true,
      imagePath: imageFile.path,
    );

    await ChatStorageService.addMessage(userMessage);

    setState(() {
      isThinking = true;
    });

    _scrollToBottom(force: true, extraOffset: 120.0);

    Future.delayed(const Duration(milliseconds: 500), () async {
      final messages = ChatStorageService.getAllMessages();
      if (messages.isNotEmpty) {
        final lastIndex = messages.length - 1;
        await ChatStorageService.updateMessageAnimation(lastIndex, false);
      }
    });

    try {
      String response;

      if (analysisType == 'prescription') {
        // Get structured data for prescription analysis
        Map<String, dynamic> analysisResult =
            await provider.analyzePrescriptionWithStructuredData(imageFile);

        // Extract medicines and store in session storage
        if (analysisResult['medicines'] != null) {
          List<ExtractedMedicine> medicines =
              (analysisResult['medicines'] as List)
                  .map((m) => ExtractedMedicine(
                        name: m['name']?.toString() ?? '',
                        dosage: m['dosage']?.toString() ?? '',
                        duration: m['duration']?.toString() ?? '',
                        instructions: m['instructions']?.toString() ?? '',
                        dailyIntakeTimes: m['dailyIntakeTimes'] != null
                            ? List<String>.from(m['dailyIntakeTimes'])
                            : [], // ✅ FIXED
                      ))
                  .toList();

          // ✅ Store extracted medicines
          ExtractedMedicineStorage.setExtractedMedicines(medicines);
        }

        // Use the structured response
        response =
            analysisResult['response'] ?? 'Prescription analyzed successfully.';
      } else {
        // Health report analysis (no structured data needed)
        response = await provider.analyzeHealthReportWithImage(imageFile, null);
      }

      final botMessage = ChatMessage(
        role: 'bot',
        content: response,
        timestamp: DateTime.now(),
        isAnimating: true,
      );

      await ChatStorageService.addMessage(botMessage);

      setState(() {
        isThinking = false;
      });

      _scrollToBottom(animate: true, extraOffset: 120.0);

      Future.delayed(const Duration(milliseconds: 800), () async {
        final messages = ChatStorageService.getAllMessages();
        if (messages.isNotEmpty) {
          final lastIndex = messages.length - 1;
          await ChatStorageService.updateMessageAnimation(lastIndex, false);
        }
      });
    } catch (e) {
      print('Image processing error: $e');

      final errorMessage = ChatMessage(
        role: 'bot',
        content: "Sorry, I couldn't analyze the image. Please try again.",
        timestamp: DateTime.now(),
        isAnimating: false,
      );

      await ChatStorageService.addMessage(errorMessage);

      setState(() {
        isThinking = false;
      });

      _scrollToBottom(animate: true, extraOffset: 120.0);
    }
  }

  final ChatService _chatService = ChatService();

  void _sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    if (isSpeaking) {
      await flutterTts.stop();
    }

    _shouldAutoScroll = true;
    _hideWelcomeMessage();

    final userMessage = ChatMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
      isAnimating: true,
    );

    await ChatStorageService.addMessage(userMessage);
    controller.clear();

    // Smooth scroll after user message
    _scrollToBottom(force: true, animate: true, extraOffset: 100);

    // Animate user message appearance
    Future.delayed(const Duration(milliseconds: 500), () async {
      final messages = ChatStorageService.getAllMessages();
      if (messages.isNotEmpty) {
        final lastIndex = messages.length - 1;
        await ChatStorageService.updateMessageAnimation(lastIndex, false);
        setState(() {}); // Trigger rebuild for animation
      }
    });

    // Set thinking state AFTER user message is added
    setState(() {
      isThinking = true; // show thinking bubble
    });

    // Keep the thinking bubble visible at least 2s
    final thinkingMinDuration = Future.delayed(const Duration(seconds: 2));

    try {
      // Request and min-delay run in parallel
      final results = await Future.wait([
        _chatService.getPersonalizedResponse(text),
        thinkingMinDuration,
      ]);

      final response = results[0] as String;

      final botMessage = ChatMessage(
        role: 'bot',
        content: response,
        timestamp: DateTime.now(),
        isAnimating: true,
      );

      await ChatStorageService.addMessage(botMessage);

      setState(() {
        isThinking = false; // hide thinking bubble
      });

      // Smooth scroll after bot message
      _scrollToBottom(force: true, animate: true, extraOffset: 80);

      // Animate bot message appearance
      Future.delayed(const Duration(milliseconds: 500), () async {
        final messages = ChatStorageService.getAllMessages();
        if (messages.isNotEmpty) {
          final lastIndex = messages.length - 1;
          await ChatStorageService.updateMessageAnimation(lastIndex, false);
          setState(() {}); // Trigger rebuild for animation
        }
      });
    } catch (e) {
      print('Error in _sendMessage: $e');
      final errorMessage = ChatMessage(
        role: 'bot',
        content: "Sorry, I couldn't process your request. Please try again.",
        timestamp: DateTime.now(),
        isAnimating: false,
      );

      await ChatStorageService.addMessage(errorMessage);
      setState(() {
        isThinking = false;
      });
      _scrollToBottom(force: true, animate: true, extraOffset: 80);
    }
  }

  Future<void> _pickImage(ImageSource source, String analysisType) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status != PermissionStatus.granted) {
          AppSnackbar.show(context,
              message: "Camera permission required", success: true);
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        await _processImage(imageFile, analysisType);
      }
    } catch (e) {
      AppSnackbar.show(context,
          message: "Error picking image: $e", success: true);
    }
  }

//   Future<void> _requestMedicineDetailsFromGemini(
//       List<ExtractedMedicine> medicines) async {
//     if (medicines.isEmpty) return;

//     // Prepare medicine names list
//     final medNames = medicines.map((m) => m.name).join(", ");

//     final prompt = """
// You are a medical assistant. Provide details for these medicines:

// Medicines: $medNames

// For each medicine, include:
// - Name
// - Usage / purpose
// - Possible side effects
// - Recommendations
// Keep it short, clear, and easy to understand.
// """;

//     // Add a temporary thinking message
//     final tempMessage = ChatMessage(
//       role: 'bot',
//       content: 'Fetching medicine details...',
//       timestamp: DateTime.now(),
//       isAnimating: true,
//     );
//     await ChatStorageService.addMessage(tempMessage);
//     _scrollToBottom(force: true);

//     try {
//       // Send prompt to Gemini API
//       final response = await provider.sendMessage(prompt);

//       // Replace tempMessage with actual response
//       await ChatStorageService.updateMessageContent(
//         tempMessage
//             .key, // Assuming your ChatStorageService allows updating by key
//         response,
//       );

//       _scrollToBottom(force: true);
//     } catch (e) {
//       await ChatStorageService.updateMessageContent(
//         tempMessage.key,
//         "⚠️ Error fetching medicine details: $e",
//       );
//       _scrollToBottom(force: true);
//     }
//   }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: const Icon(Icons.photo_camera, color: Colors.green),
                  ),
                  title: const Text(
                    'Take Prescription Photo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera, 'prescription');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: const Icon(Icons.photo_library, color: Colors.green),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery, 'prescription');
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollToBottomButton() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: _showScrollButton ? 80 : -60,
      right: 16,
      child: FloatingActionButton.small(
        onPressed: () {
          _shouldAutoScroll = true;
          _scrollToBottom(force: true);
          setState(() {
            _showScrollButton = false;
          });
        },
        backgroundColor: Colors.green[800],
        child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF64B5F6), Color(0xFF2196F3)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.staggeredDotsWave(
                  color: const Color(0xFF2196F3),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Analyzing...",
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(ChatMessage msg, bool isAnimating) {
    return AnimatedOpacity(
      opacity: 1.0, // Safe value
      duration: const Duration(milliseconds: 500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: AnimatedScale(
              scale: isAnimating ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 193, 247, 198),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2), // Safe opacity
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (msg.hasImage && msg.imagePath != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(msg.imagePath!),
                            height: 150,
                            width: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                width: 200,
                                color: Color.fromARGB(255, 200, 255, 250),
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                        ),
                      ),
                    Text(
                      msg.content,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotMessage(ChatMessage msg, bool isAnimating) {
    final String messageId = msg.messageId;
    final bool isCurrentlySpeaking =
        isSpeaking && currentSpeakingMessageId == messageId;

    return AnimatedOpacity(
      opacity: 1.0, // Always visible
      duration: const Duration(milliseconds: 300),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot Avatar with safe animation
          AnimatedScale(
            scale: 1.0, // No scaling issues
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.green[400]!],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3), // Safe opacity
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.assistant,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedScale(
                  scale: isAnimating ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 248, 248, 248),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isAnimating
                        ? TypewriterText(
                            text: msg.content,
                            duration: const Duration(milliseconds: 30),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : MarkdownBody(
                            data: msg.content,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500),
                              strong:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              listBullet: const TextStyle(fontSize: 15),
                            ),
                          ),
                  ),
                ),
                // Medicine buttons (if extracted medicines exist)
                if (!isAnimating && _shouldShowMedicineButtons(msg))
                  _buildMedicineButtons(),
                if (!isAnimating) const SizedBox(height: 8),
                if (!isAnimating)
                  GestureDetector(
                    onTap: () => _speakText(msg.content, messageId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCurrentlySpeaking
                            ? Colors.red[400]
                            : Colors.green[800],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCurrentlySpeaking ? Icons.stop : Icons.volume_up,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCurrentlySpeaking ? 'Stop' : 'Speak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Check if medicine buttons should be shown
  bool _shouldShowMedicineButtons(ChatMessage msg) {
    return msg.content.contains("prescription") &&
        ExtractedMedicineStorage.hasExtractedMedicines();
  }

// Build medicine buttons widget
  // Widget _buildMedicineButtons() {
  //   final medicines = ExtractedMedicineStorage.getExtractedMedicines();

  //   if (medicines.isEmpty) return const SizedBox.shrink();

  //   return Container(
  //     margin: const EdgeInsets.only(top: 2),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //           decoration: BoxDecoration(
  //             color: Colors.green[50],
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: Colors.green[200]!),
  //           ),
  //           child: const Row(
  //             children: [
  //               Icon(Icons.medical_services, color: Colors.green, size: 16),
  //               SizedBox(width: 8),
  //               Text(
  //                 "Medicines found - Click to add:",
  //                 style: TextStyle(
  //                   fontSize: 13,
  //                   fontWeight: FontWeight.w600,
  //                   color: Colors.green,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         ...medicines
  //             .map((medicine) => Container(
  //                 width: double.infinity,
  //                 margin: const EdgeInsets.only(bottom: 2),
  //                 child: InkWell(
  //                   onTap: () => _navigateToAddMedicine(medicine),
  //                   child: Container(
  //                     padding: const EdgeInsets.symmetric(
  //                         horizontal: 10, vertical: 4),
  //                     decoration: BoxDecoration(
  //                       color: Color.fromARGB(255, 255, 254, 179),
  //                       borderRadius: BorderRadius.circular(8),
  //                       border: Border.all(color: Colors.green[300]!),
  //                     ),
  //                     child: Row(
  //                       crossAxisAlignment:
  //                           CrossAxisAlignment.center, // center vertically
  //                       children: [
  //                         Icon(Icons.add_circle_outline,
  //                             size: 18, color: Colors.green[800]),
  //                         const SizedBox(width: 8),
  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             mainAxisSize: MainAxisSize.min,
  //                             children: [
  //                               Text(
  //                                 medicine.name,
  //                                 style: const TextStyle(
  //                                   fontSize: 14,
  //                                   fontWeight: FontWeight.w600,
  //                                 ),
  //                               ),

  //                               if (medicine.dosage.isNotEmpty ||
  //                                   medicine.instructions.isNotEmpty ||
  //                                   medicine.dailyIntakeTimes.isNotEmpty)
  //                                 Text(
  //                                   [
  //                                     if (medicine.dosage.isNotEmpty)
  //                                       medicine.dosage,
  //                                     if (medicine.instructions.isNotEmpty)
  //                                       medicine.instructions,
  //                                     if (medicine.dailyIntakeTimes.isNotEmpty)
  //                                       medicine.dailyIntakeTimes.join(", ")
  //                                   ].join(" • "),
  //                                   style: const TextStyle(
  //                                     fontSize: 12,
  //                                     color: Colors.black87,
  //                                   ),
  //                                 ),
  //                             ],
  //                           ),
  //                         ),
  //                         ElevatedButton(
  //                           onPressed: () async {
  //                             // 1️⃣ Add user message
  //                             final detailMsg = ChatMessage(
  //                               role: 'user',
  //                               content: "Details about - 💊 ${medicine.name}",
  //                               timestamp: DateTime.now(),
  //                             );
  //                             ChatStorageService.addMessage(detailMsg);

  //                             // 2️⃣ Add "thinking" placeholder message
  //                             final thinkingMsg = ChatMessage(
  //                               role: 'bot',
  //                               content: "💭 Thinking...",
  //                               timestamp: DateTime.now(),
  //                             );
  //                             ChatStorageService.addMessage(thinkingMsg);

  //                             setState(
  //                                 () {}); // Refresh chat to show "thinking"

  //                             // 3️⃣ Fetch response from Gemini
  //                             String response = await ChatService()
  //                                 .fetchDetailedMedicineInfo(medicine.name);

  //                             // 4️⃣ Replace the "thinking" message with actual response
  //                             thinkingMsg.content = response;
  //                             thinkingMsg.timestamp = DateTime.now();
  //                             await thinkingMsg.save(); // if using Hive

  //                             setState(
  //                                 () {}); // Refresh chat to show actual answer
  //                           },
  //                           child: Text("Show Details"),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 )))
  //             .toList(),
  //         const SizedBox(height: 10),
  //       ],
  //     ),
  //   );
  // }
// Build medicine buttons widget
Widget _buildMedicineButtons() {
  final medicines = ExtractedMedicineStorage.getExtractedMedicines();

  if (medicines.isEmpty) return const SizedBox.shrink();

  return Container(
    margin: const EdgeInsets.only(top: 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: const Row(
            children: [
              Icon(Icons.medical_services, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text(
                "Medicines found - Click to add:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...medicines
            .map((medicine) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 2),
                child: InkWell(
                  onTap: () => _navigateToAddMedicine(medicine),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 254, 179),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 18, color: Colors.green[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                medicine.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (medicine.dosage.isNotEmpty ||
                                  medicine.instructions.isNotEmpty ||
                                  medicine.dailyIntakeTimes.isNotEmpty)
                                Text(
                                  [
                                    if (medicine.dosage.isNotEmpty)
                                      medicine.dosage,
                                    if (medicine.instructions.isNotEmpty)
                                      medicine.instructions,
                                    if (medicine.dailyIntakeTimes.isNotEmpty)
                                      medicine.dailyIntakeTimes.join(", ")
                                  ].join(" • "),
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            // 1️⃣ Add user message
                            final detailMsg = ChatMessage(
                              role: 'user',
                              content: "Details about - 💊 ${medicine.name}",
                              timestamp: DateTime.now(),
                            );
                            ChatStorageService.addMessage(detailMsg);

                            // 2️⃣ Add "thinking" placeholder message
                            final thinkingMsg = ChatMessage(
                              role: 'bot',
                              content: "💭 Thinking...",
                              timestamp: DateTime.now(),
                            );
                            ChatStorageService.addMessage(thinkingMsg);

                            setState(() {}); // Refresh chat to show "thinking"

                            // 3️⃣ Fetch response from Gemini
                            String response = await ChatService()
                                .fetchDetailedMedicineInfo(medicine.name);

                            // 4️⃣ Replace the "thinking" message with actual response
                            thinkingMsg.content = response;
                            thinkingMsg.timestamp = DateTime.now();
                            await thinkingMsg.save(); // if using Hive

                            setState(() {}); // Refresh chat to show actual answer
                          },
                          child: const Text("Show Details"),
                        ),
                      ],
                    ),
                  ),
                )))
            .toList(),
        const SizedBox(height: 10),
      ],
    ),
  );
}

  void _showMedicineDetails(List<ExtractedMedicine> medicines) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Medicine Details"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final med = medicines[index];
                return ListTile(
                  title: Text(med.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    [
                      if (med.dosage.isNotEmpty) "Dosage: ${med.dosage}",
                      if (med.instructions.isNotEmpty)
                        "Instructions: ${med.instructions}",
                      if (med.dailyIntakeTimes.isNotEmpty)
                        "Times: ${med.dailyIntakeTimes.join(", ")}",
                    ].join("\n"),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

// Navigate to add medicine page with prefilled data
  void _navigateToAddMedicine(ExtractedMedicine medicine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedAddPage(
          medicine: medicine,
        ),
      ),
    ).then((result) {
      if (result == true) {
        AppSnackbar.show(context,
            message: "${medicine.name} added successfully!", success: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Updated background color from MedicalChatScreen
      backgroundColor: Color.fromARGB(255, 231, 243, 255),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("AI Chat"),
        backgroundColor: Colors.green[800],
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => const Bottomnavbar(initialIndex: 0)),
              (route) => false,
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Updated container with gradient background like MedicalChatScreen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green[800]!.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              children: [
                Expanded(
                    child: ValueListenableBuilder<Box<ChatMessage>>(
                  valueListenable: ChatStorageService.getMessagesListenable(),
                  builder: (context, box, _) {
                    final messages = ChatStorageService.getAllMessages();
                    // Call load initial messages here to ensure it runs after build
                    if (_isFirstLoad) {
                      _loadInitialMessages();
                    }
                    // Calculate total items including welcome message (only if flag is true)
                    final totalItems = messages.length +
                        (isThinking ? 1 : 0) +
                        (_showWelcomeMessage ? 1 : 0);
                    // Schedule scroll to bottom after this build completes
                    if (_showWelcomeMessage && messages.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (_scrollController.hasClients && mounted) {
                            _scrollController.jumpTo(
                                _scrollController.position.maxScrollExtent);
                          }
                        });
                      });
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                          top: 10,
                          bottom: 120), // Increased bottom padding
                      itemCount: totalItems,

                      itemBuilder: (context, index) {
                        // Show actual chat messages first
                        if (index < messages.length) {
                          final msg = messages[index];
                          final isUser = msg.role == "user";
                          final isAnimating = msg.isAnimating;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: isUser
                                ? _buildUserMessage(msg, isAnimating)
                                : _buildBotMessage(msg, isAnimating),
                          );
                        }

                        // Show thinking indicator AFTER all messages
                        if (isThinking && index == messages.length) {
                          return _buildThinkingIndicator();
                        }

                        // Show welcome message ONLY if flag is true and at the very end
                        if (_showWelcomeMessage &&
                            index == messages.length + (isThinking ? 1 : 0)) {
                          return _buildWelcomeMessage();
                        }

                        return const SizedBox.shrink();
                      },
                    );
                  },
                )),
                const Divider(height: 1),
                // Updated input section with MedicalChatScreen styling
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color.fromARGB(255, 224, 177, 255),
                        radius: 25,
                        child: IconButton(
                          icon: const Icon(Icons.photo_camera_back_outlined,
                              color: Colors.black),
                          onPressed: _showImagePickerOptions,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.green[800]!.withOpacity(0.2),
                              ),
                            ),
                            child: TextField(
                              controller: controller,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: "Type a message",
                                hintStyle: TextStyle(color: Colors.grey),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 25,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: isThinking ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildScrollToBottomButton(),
        ],
      ),
    );
  }

  // Move this INSIDE your _ChatpageState class
  Widget _buildWelcomeMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 15, left: 10, right: 10, bottom: 200),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 35,
                  height: 35,
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
                  child: const Icon(
                    Icons.assistant,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 248, 248, 248),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Hello! 👋 Welcome Back to MedRemind AI Assistant!\nI'm here to help you with:\n💊 Medicine management\n📊 Health reports\n❓ Health questions\n👤 Personal assistance\nHow can I assist you today?",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    _dotsController.dispose();
    flutterTts.stop();
    super.dispose();
  }
}

// TypewriterText widget
class TypewriterText extends StatefulWidget {
  final String text;
  final Duration duration;
  final TextStyle style;

  const TypewriterText({
    Key? key,
    required this.text,
    required this.duration,
    required this.style,
  }) : super(key: key);

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(
        milliseconds: widget.duration.inMilliseconds * widget.text.length,
      ),
      vsync: this,
    );

    _characterCount = IntTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        final String visibleText =
            widget.text.substring(0, _characterCount.value);
        return Text(
          visibleText,
          style: widget.style,
        );
      },
    );
  }
}
