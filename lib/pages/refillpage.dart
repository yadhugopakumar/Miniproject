import 'package:flutter/material.dart';

class RefillTrackerPage extends StatelessWidget {
  const RefillTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample static data for UI preview
    final List<Map<String, dynamic>> medicines = [
      {
        'name': 'Paracetamol',
        'quantityLeft': 5,
        'totalQuantity': 20,
      },
      {
        'name': 'Vitamin C',
        'quantityLeft': 15,
        'totalQuantity': 30,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Refill Tracker",
          style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView.separated(
          itemCount: medicines.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final med = medicines[index];
            final lowStock = med['quantityLeft'] <= med['totalQuantity'] * 0.25;

            return Card(
              color: Colors.teal[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.medication, color: Color(0xFF166D5B)),
                      ),
                      title: Text(
                        med['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${med['quantityLeft']} of ${med['totalQuantity']} left",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: med['quantityLeft'] / med['totalQuantity'],
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              lowStock ? Colors.red : Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                      trailing: _statusChip(
                        lowStock ? "Refill Soon" : "Sufficient",
                        lowStock ? Colors.red[400]! : Colors.green[100]!,
                        textColor: lowStock ? Colors.white : Colors.green[800]!,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            // Edit placeholder
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text("Edit",
                              style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            // Delete placeholder
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text("Delete",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statusChip(String text, Color color, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
