import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 7)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String role; // 'user' or 'bot'

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  bool isAnimating;

  @HiveField(4)
  bool hasImage;

  @HiveField(5)
  String? imagePath;

  @HiveField(6)
  String messageId;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isAnimating = false,
    this.hasImage = false,
    this.imagePath,
    String? messageId,
  }) : messageId = messageId ?? timestamp.millisecondsSinceEpoch.toString();

  // Convert from Map (for backward compatibility)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      role: map['role'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] ?? DateTime.now(),
      isAnimating: map['isAnimating'] ?? false,
      hasImage: map['hasImage'] ?? false,
      imagePath: map['imagePath'],
      messageId: map['messageId'],
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp,
      'isAnimating': isAnimating,
      'hasImage': hasImage,
      'imagePath': imagePath,
      'messageId': messageId,
    };
  }
}
