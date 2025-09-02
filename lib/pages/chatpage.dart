import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

import '../Hivemodel/chat_message.dart';
import '../chatmanager/ai_chat/chat_service.dart';
import '../chatmanager/ai_chat/chat_storage_service.dart';
import '../chatmanager/ai_chat/gemini_provider.dart';
import '../bottomnavbar.dart';

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

  // Auto-scroll related variables
  bool _shouldAutoScroll = true;
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    apiKey = dotenv.env['API_KEY'] ?? "";
    provider = GeminiProvider(apiKey: apiKey);
    _initTts();
    // _loadInitialMessages();
    _setupScrollListener();

    // Call scroll after a delay to ensure everything is built
    Future.delayed(const Duration(milliseconds: 500), () {
      _scrollToBottomAfterBuild();
    });
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
          final double maxExtent =
              _scrollController.position.maxScrollExtent ;
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
                .jumpTo(_scrollController.position.maxScrollExtent );
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
        response = await provider.analyzePrescriptionImage(imageFile);
      } else {
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
    setState(() {
      isThinking = true;
    });

    // Smooth scroll after user message with animation
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

    try {
      final response = await _chatService.getPersonalizedResponse(text);

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

      // Smooth scroll after bot message
      _scrollToBottom(force: true, animate: true, extraOffset: 80);

      // Animate bot message appearance (typewriter effect)
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission required')),
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

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

//  Widget _buildThinkingIndicator() {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF64B5F6), Color(0xFF2196F3)],
//               ),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: const Icon(
//               Icons.psychology,
//               color: Colors.white,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 LoadingAnimationWidget.staggeredDotsWave(
//                   color: const Color(0xFF2196F3),
//                   size: 20,
//                 ),
//                 const SizedBox(width: 8),
//                 const Text(
//                   "Analyzing...",
//                   style: TextStyle(
//                     color: Color(0xFF2196F3),
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
Widget _buildThinkingIndicator() {
  if (!isThinking) return const SizedBox.shrink();
  
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    color: Colors.red, // Should be clearly visible
    child: const Text(
      "THINKING ANIMATION TEST",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}

//   Widget _buildThinkingIndicator() {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 400),
//       child: isThinking
//           ? Container(
//               key: const ValueKey('thinking'),
//               margin: const EdgeInsets.only(bottom: 16),
//               child: Row(
//                 children: [
//                   // Continuously Pulsing Avatar
//                   TweenAnimationBuilder<double>(
//                     tween: Tween(begin: 0.8, end: 1.2),
//                     duration: const Duration(milliseconds: 1000),
//                     builder: (context, scale, child) {
//                       return TweenAnimationBuilder<double>(
//                         tween: Tween(begin: 1.2, end: 0.8),
//                         duration: const Duration(milliseconds: 1000),
//                         builder: (context, reverseScale, child) {
//                           return Transform.scale(
//                             scale: scale,
//                             child: Container(
//                               width: 40,
//                               height: 40,
//                               decoration: BoxDecoration(
//                                 gradient: const LinearGradient(
//                                   colors: [
//                                     Color(0xFF64B5F6),
//                                     Color(0xFF2196F3)
//                                   ],
//                                 ),
//                                 borderRadius: BorderRadius.circular(20),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: const Color(0xFF2196F3)
//                                         .withOpacity(0.4),
//                                     blurRadius: 8 * scale,
//                                     spreadRadius: 2 * scale,
//                                   ),
//                                 ],
//                               ),
//                               child: const Icon(
//                                 Icons.psychology,
//                                 color: Colors.white,
//                                 size: 20,
//                               ),
//                             ),
//                           );
//                         },
//                         onEnd: () {
//                           // This will restart the animation
//                           if (mounted && isThinking) {
//                             setState(() {});
//                           }
//                         },
//                       );
//                     },
//                     onEnd: () {
//                       // This will restart the animation
//                       if (mounted && isThinking) {
//                         setState(() {});
//                       }
//                     },
//                   ),
//                   const SizedBox(width: 12),
//                   // Message Bubble
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         LoadingAnimationWidget.staggeredDotsWave(
//                           color: const Color(0xFF2196F3),
//                           size: 20,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text(
//                           "Analyzing...",
//                           style: TextStyle(
//                             color: Color(0xFF2196F3),
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           : const SizedBox.shrink(key: ValueKey('empty')),
//     );
//   }

  Widget _buildUserMessage(ChatMessage msg, bool isAnimating) {
    return AnimatedOpacity(
      opacity: 1.0, // Safe value
      duration: const Duration(milliseconds: 300),
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
                        : Text(
                            msg.content,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
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

                        // Show thinking indicator
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
                "Hello! 👋 Welcome to MedRemind AI Assistant!\n\nI'm here to help you with:\n\n💊 Medicine management: Today's doses, missed medications, refill alerts\n\n📊 Health reports: Blood pressure, cholesterol readings\n\n❓ Health questions: Symptoms, medicine information, general health tips\n\n👤 Personal assistance: Your profile and health history\n\nHow can I assist you today?",
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
