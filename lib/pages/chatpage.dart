import 'package:flutter/material.dart';

import '../bottomnavbar.dart';

class Chatpage extends StatelessWidget {
  final List<Map<String, String>> messages = [
    {'role': 'user', 'text': 'Hi there!'},
    {'role': 'ai', 'text': 'Hello! How can I assist you today?'},
    {'role': 'user', 'text': 'Tell me a joke.'},
    {
      'role': 'ai',
      'text':
          'Why don’t scientists trust atoms? Because they make up everything!'
    },
  ];

  Chatpage({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("AI Chat"),
        backgroundColor: Colors.green[800],
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => Bottomnavbar(initialIndex: 0)),
    (route) => false,
  );
},

        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.teal[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text'] ?? ''),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // This is dummy — no actual sending
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Message sent (not really)")),
                    );
                  },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
