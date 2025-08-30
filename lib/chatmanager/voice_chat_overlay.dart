
// voice_chat_overlay.dart
import 'package:flutter/material.dart';
import 'chat_manager.dart';

class VoiceChatOverlay extends StatefulWidget {
  final VoidCallback onClose;
  
  const VoiceChatOverlay({Key? key, required this.onClose}) : super(key: key);
  
  @override
  _VoiceChatOverlayState createState() => _VoiceChatOverlayState();
}

class _VoiceChatOverlayState extends State<VoiceChatOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  final VoiceChatManager _voiceManager = VoiceChatManager();
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _waveController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
    
    // Listen to state changes
    _voiceManager.onStateChanged = () {
      if (mounted) setState(() {});
    };
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _voiceManager.reset();
        widget.onClose();
      },
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping center
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App title
                Text(
                  'MedRemind Voice Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 40),
                
                // Fixed container for animations - this prevents layout shifts
                Container(
                  width: 180, // Fixed width to contain largest animation
                  height: 180, // Fixed height to contain largest animation
                  child: Center(
                    child: _buildCurrentAnimation(),
                  ),
                ),
                
                SizedBox(height: 30),
                
                // Status Text
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 20),
                
                // Transcript Display - Fixed height container
                Container(
                  height: 60, // Fixed height
                  margin: EdgeInsets.symmetric(horizontal: 40),
                  child: _voiceManager.currentTranscript.isNotEmpty
                      ? Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _voiceManager.currentTranscript,
                              style: TextStyle(fontSize: 16, color: Colors.black),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      : SizedBox(), // Empty space when no transcript
                ),
                
                SizedBox(height: 40),
                
                // Control buttons - Fixed position
                Container(
                  height: 60, // Fixed height for buttons
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Stop/Retry button
                      if (_voiceManager.isListening || _voiceManager.isProcessing)
                        ElevatedButton(
                          onPressed: () {
                            _voiceManager.reset();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(16),
                            fixedSize: Size(60, 60), // Fixed size
                          ),
                          child: Icon(Icons.stop, color: Colors.white, size: 30),
                        ),
                      
                      // Restart listening button (when idle)
                      if (!_voiceManager.isListening && !_voiceManager.isProcessing)
                        ElevatedButton(
                          onPressed: () {
                            _voiceManager.startListening();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 93, 255, 101),
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(16),
                            fixedSize: Size(60, 60), // Fixed size
                          ),
                          child: Icon(Icons.mic, color: Colors.black, size: 30),
                        ),
                      
                      // Close button
                      ElevatedButton(
                        onPressed: () {
                          _voiceManager.reset();
                          widget.onClose();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          fixedSize: Size(80, 50), // Fixed size
                        ),
                        child: Text('Close', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // New method to handle different animation states
  Widget _buildCurrentAnimation() {
    if (_voiceManager.isListening) {
      return _buildListeningAnimation();
    } else if (_voiceManager.isProcessing) {
      return _buildProcessingAnimation();
    } else {
      return _buildIdleAnimation();
    }
  }
  
  String _getStatusText() {
    if (_voiceManager.isListening) {
      return "🎤 Listening... Speak now!";
    } else if (_voiceManager.isProcessing) {
      return "🧠 Processing your request...";
    } else {
      return "Tap the mic to start talking";
    }
  }
  
  Widget _buildListeningAnimation() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 120 + (30 * _pulseController.value),
          height: 120 + (30 * _pulseController.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromARGB(255, 93, 255, 101).withOpacity(0.3),
            border: Border.all(
              color: Color.fromARGB(255, 93, 255, 101),
              width: 3,
            ),
          ),
          child: Icon(
            Icons.mic,
            size: 50,
            color: Colors.white,
          ),
        );
      },
    );
  }
  
  Widget _buildProcessingAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange.withOpacity(0.2),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      ),
    );
  }
  
  // New idle animation
  Widget _buildIdleAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withOpacity(0.2),
        border: Border.all(color: Colors.grey, width: 2),
      ),
      child: Icon(
        Icons.mic_off,
        size: 50,
        color: Colors.white,
      ),
    );
  }
}
