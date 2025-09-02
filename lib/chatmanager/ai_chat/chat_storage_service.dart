import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import '../../Hivemodel/chat_message.dart';

class ChatStorageService {
  static const String _boxName = 'chatMessages';

  // Get the chat messages box
  static Box<ChatMessage> get _box => Hive.box<ChatMessage>(_boxName);

  // Add a message to storage
  static Future<void> addMessage(ChatMessage message) async {
    await _box.add(message);
  }

  // Get all messages
  static List<ChatMessage> getAllMessages() {
    return _box.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // Update message animation status
  static Future<void> updateMessageAnimation(
      int index, bool isAnimating) async {
    if (index < _box.length) {
      final message = _box.getAt(index);
      if (message != null) {
        message.isAnimating = isAnimating;
        await message.save();
      }
    }
  }

  // Get box listenable for real-time updates
  static ValueListenable<Box<ChatMessage>> getMessagesListenable() {
    return _box.listenable();
  }

  // Clear all messages
  static Future<void> clearAllMessages() async {
    await _box.clear();
  }
}
