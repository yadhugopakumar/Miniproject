// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;

// class GeminiProvider {
//   final String apiKey;
//   GeminiProvider({required this.apiKey});

//   // For text-only queries
//   Future<String> generateContent(String prompt) async {
//     return await _makeApiCall([
//       {
//         'parts': [
//           {'text': prompt}
//         ]
//       }
//     ]);
//   }

//   // For prescription image analysis
//   Future<String> analyzePrescriptionImage(File imageFile) async {
//     final String base64Image = await _fileToBase64(imageFile);
//     final String mimeType = _getMimeType(imageFile.path);

//     final prompt = """Extract prescription details in this format ONLY:

// Medicine Name: [name]
// Dosage: [amount]
// Frequency: [times per day]
// Duration: [days/weeks]

// For each medicine found. If more than 5 medicines, group by category (Heart, Diabetes, etc.).
// No additional explanations needed. END""";

//     return await _makeApiCall([
//       {
//         'parts': [
//           {'text': prompt},
//           {
//             'inline_data': {'mime_type': mimeType, 'data': base64Image}
//           }
//         ]
//       }
//     ], maxTokens: 400);
//   }

// // ✅ Frequency parser
// List<String> parseFrequency(String freq) {
//   final mapping = {
//     "morning": "08:00",
//     "afternoon": "14:00",
//     "evening": "18:00",
//     "night": "20:00",
//   };

//   final results = <String>[];

//   // Handle patterns like "2 times daily" / "thrice a day"
//   final lower = freq.toLowerCase();
//   if (lower.contains("2 times") || lower.contains("twice")) {
//     return ["08:00", "20:00"];
//   } else if (lower.contains("3 times") || lower.contains("thrice")) {
//     return ["08:00", "14:00", "20:00"];
//   } else if (lower.contains("4 times")) {
//     return ["06:00", "12:00", "18:00", "22:00"];
//   }

//   // Otherwise map based on words (Morning, Night, etc.)
//   for (final part in freq.split(RegExp(r'[,\s]+'))) {
//     final normalized = part.trim().toLowerCase();
//     if (mapping.containsKey(normalized)) {
//       results.add(mapping[normalized]!);
//     }
//   }

//   return results;
// }

// // ✅ Your main function
// Future<Map<String, dynamic>> analyzePrescriptionWithStructuredData(
//     File imageFile) async {
//   final String base64Image = await _fileToBase64(imageFile);
//   final String mimeType = _getMimeType(imageFile.path);

//  final prompt = """
// Analyze this prescription image and extract medicine information.

// IMPORTANT RULES:
// 1. Always return JSON only (no markdown/code blocks).
// 2. For each medicine, you MUST include:
//    - name (string)
//    - dosage (string)
//    - frequency (string, e.g. "Morning, Night" or "2 times daily")
//    - duration (string, e.g. "7 days" or "6 months")
//    - instructions (string, e.g. "After meals", "As prescribed")
// 3. If any field is not visible, put "As prescribed".

// Return ONLY this JSON:

// {
//   "medicines": [
//     {
//       "name": "Medicine Name",
//       "dosage": "1",
//       "frequency": "Morning, Night",
//       "instructions": "After meals"
//     }
//   ],
//   "response": "I found X medicines in your prescription. Click the buttons below to add them to your medicine list."
// }

// If no medicines found, return empty medicines array and appropriate message.
// END
// """;

//   String responseText = "";

//   try {
//     responseText = await _makeApiCall([
//       {
//         'parts': [
//           {'text': prompt},
//           {
//             'inline_data': {'mime_type': mimeType, 'data': base64Image}
//           }
//         ]
//       }
//     ], maxTokens: 500);

//     print('Raw AI Response: $responseText');

//     // Clean AI response
//     String cleanedResponse = responseText
//         .replaceAll(RegExp(r'```json', caseSensitive: false), '')
//         .replaceAll('```', '')
//         .trim();

//     print('Cleaned Response: $cleanedResponse');

//     final jsonData = json.decode(cleanedResponse);

//     // ✅ Convert medicines
//     final List medicines = (jsonData['medicines'] ?? []).map((m) {
//       final freq = m['frequency'] ?? "";
//       final intakeTimes = parseFrequency(freq);

//       return {
//         "name": m['name'] ?? "",
//         "dosage": m['dosage'] ?? "",
//         "dailyIntakeTimes": intakeTimes,
//         "instructions": m['instructions'] ?? "",
//       };
//     }).toList();

//     return {
//       "medicines": medicines,
//       "response": jsonData['response'] ?? "Prescription analyzed successfully."
//     };
//   } catch (e) {
//     print('JSON parsing error: $e');
//     print('Response text was: $responseText');

//     return {
//       "medicines": [],
//       "response":
//           "I analyzed your prescription but could not extract structured medicines. Please verify manually."
//     };
//   }
// }

//   // For health report analysis with image
//   Future<String> analyzeHealthReportWithImage(
//       File imageFile, String? additionalData) async {
//     final String base64Image = await _fileToBase64(imageFile);
//     final String mimeType = _getMimeType(imageFile.path);

//     final prompt = """Analyze this health report image and provide:
// 1. Key values (BP, cholesterol, blood sugar, etc.)
// 2. Compare with normal ranges
// 3. 2-3 actionable suggestions
// Maximum 5 sentences.

// ${additionalData != null ? 'Additional context: $additionalData' : ''}
// END""";

//     return await _makeApiCall([
//       {
//         'parts': [
//           {'text': prompt},
//           {
//             'inline_data': {'mime_type': mimeType, 'data': base64Image}
//           }
//         ]
//       }
//     ], maxTokens: 300);
//   }

//   // Core API call method
//   Future<String> _makeApiCall(List<Map<String, dynamic>> contents,
//       {int maxTokens = 200}) async {
//     final url = Uri.parse(
//         'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=$apiKey');

//     final headers = {
//       'Content-Type': 'application/json',
//     };

//     final body = jsonEncode({
//       'contents': contents,
//       'generationConfig': {
//         'temperature': 0.4,
//         'maxOutputTokens': maxTokens,
//         'stopSequences': ['END', 'Note:', 'Disclaimer:']
//       }
//     });

//     try {
//       final response = await http.post(url, headers: headers, body: body);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         if (data['candidates'] != null && data['candidates'].isNotEmpty) {
//           return data['candidates'][0]['content']['parts'][0]['text'] ??
//               'No response generated';
//         }
//         return 'No candidates found';
//       } else {
//         print('API Error: ${response.statusCode} - ${response.body}');
//         return 'Sorry, I couldn\'t process the image.';
//       }
//     } catch (e) {
//       print('Exception: $e');
//       return 'Connection error. Please try again.';
//     }
//   }

//   // Convert file to base64
//   Future<String> _fileToBase64(File file) async {
//     List<int> imageBytes = await file.readAsBytes();
//     return base64Encode(imageBytes);
//   }

//   // Get MIME type from file extension
//   String _getMimeType(String filePath) {
//     final extension = filePath.split('.').last.toLowerCase();
//     switch (extension) {
//       case 'jpg':
//       case 'jpeg':
//         return 'image/jpeg';
//       case 'png':
//         return 'image/png';
//       case 'webp':
//         return 'image/webp';
//       case 'pdf':
//         return 'application/pdf';
//       default:
//         return 'image/jpeg';
//     }
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'extractedmedicine.dart';
import 'extractedmedicine_storage.dart';

class GeminiProvider {
  final String apiKey;
  GeminiProvider({required this.apiKey});

  // For text-only queries
  Future<String> generateContent(String prompt) async {
    return await _makeApiCall([
      {
        'parts': [
          {'text': prompt}
        ]
      }
    ]);
  }

//   // ✅ Prescription Analysis with structured JSON
//   Future<Map<String, dynamic>> analyzePrescriptionWithStructuredData(
//       File imageFile) async {
//     final String base64Image = await _fileToBase64(imageFile);
//     final String mimeType = _getMimeType(imageFile.path);

//     const prompt = """
// Analyze this prescription image and extract medicine information.

// IMPORTANT RULES:
// 1. Always return JSON only (no markdown/code blocks).
// 2. For each medicine, you MUST include:
//    - name (string)
//    - dosage (string)
//    - dailyIntakeTimes (array of times in 24hr format "HH:mm", e.g. ["08:00","14:00","21:00"])
//    - duration (string, e.g. "7 days" or "6 months")
//    - instructions (string, e.g. "After meals", "As prescribed")
// 3. If frequency is written as words (Morning, Night, Twice daily, etc.), convert them into specific times in HH:mm format.
//    Example:
//      - "Morning, Night" → ["08:00","21:00"]
//      - "2 times daily" → ["08:00","20:00"]
//      - "3 times daily" → ["08:00","14:00","20:00"]
// 4. If any field is not visible, put "As prescribed".

// Return ONLY this JSON:

// {
//   "medicines": [
//     {
//       "name": "Medicine Name",
//       "dosage": "1",
//       "dailyIntakeTimes": ["08:00","21:00"],
//       "duration": "7 days",
//       "instructions": "After meals"
//     }
//   ],
//   "response": "I found X medicines in your prescription. Click the buttons below to add them to your medicine list."
// }

// If no medicines found, return empty medicines array and appropriate message.
// END
// """;

//     String responseText = "";

//     try {
//       responseText = await _makeApiCall([
//         {
//           'parts': [
//             {'text': prompt},
//             {
//               'inline_data': {'mime_type': mimeType, 'data': base64Image}
//             }
//           ]
//         }
//       ], maxTokens: 500);

//       print('Raw AI Response: $responseText');

//       // Clean AI response
//       String cleanedResponse = responseText
//           .replaceAll(RegExp(r'```json', caseSensitive: false), '')
//           .replaceAll('```', '')
//           .trim();

//       print('Cleaned Response: $cleanedResponse');

//       final jsonData = json.decode(cleanedResponse);

// // Safely map JSON -> ExtractedMedicine
//       final List<dynamic> rawList = (jsonData['medicines'] as List?) ?? [];
//       final extractedList = rawList
//           .map((m) => ExtractedMedicine.fromJson(Map<String, dynamic>.from(m)))
//           .toList();

// // Save globally for your chat UI buttons
//       ExtractedMedicineStorage.setExtractedMedicines(extractedList);

// // If you return a Map, you can still return plain JSON for the caller:
//       return {
//         "medicines": extractedList.map((m) => m.toJson()).toList(),
//         "response":
//             jsonData['response'] ?? "Prescription analyzed successfully."
//       };
    

//       return {
//         "medicines": medicines,
//         "response":
//             jsonData['response'] ?? "Prescription analyzed successfully."
//       };
//     } catch (e) {
//       print('JSON parsing error: $e');
//       print('Response text was: $responseText');

//       return {
//         "medicines": [],
//         "response":
//             "I analyzed your prescription but could not extract structured medicines. Please verify manually."
//       };
//     }
//   }
// ✅ Prescription Analysis with structured JSON
Future<Map<String, dynamic>> analyzePrescriptionWithStructuredData(
    File imageFile) async {
  final String base64Image = await _fileToBase64(imageFile);
  final String mimeType = _getMimeType(imageFile.path);

  const prompt = """
Analyze this prescription image and extract medicine information.

IMPORTANT RULES:
1. Always return JSON only (no markdown/code blocks).
2. For each medicine, you MUST include:
   - name (string)
   - dosage (string)
   - dailyIntakeTimes (array of times in 24hr format "HH:mm", e.g. ["08:00","14:00","21:00"])
   - duration (string, e.g. "7 days" or "6 months")
   - instructions (string, e.g. "After meals", "As prescribed")
3. If frequency is written as words (Morning, Night, Twice daily, etc.), convert them into specific times in HH:mm format.
   Example:
     - "Morning, Night" → ["08:00","21:00"]
     - "2 times daily" → ["08:00","20:00"]
     - "3 times daily" → ["08:00","14:00","20:00"]
4. If any field is not visible, put "As prescribed".

Return ONLY this JSON:

{
  "medicines": [
    {
      "name": "Medicine Name",
      "dosage": "1",
      "dailyIntakeTimes": ["08:00","21:00"],
      "duration": "7 days",
      "instructions": "After meals"
    }
  ],
  "response": "I found X medicines in your prescription. Click the buttons below to add them to your medicine list."
}

If no medicines found, return empty medicines array and appropriate message.
END
""";

  String responseText = "";

  try {
    responseText = await _makeApiCall([
      {
        'parts': [
          {'text': prompt},
          {
            'inline_data': {'mime_type': mimeType, 'data': base64Image}
          }
        ]
      }
    ], maxTokens: 500);

    print('Raw AI Response: $responseText');

    // Clean AI response
    String cleanedResponse = responseText
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();

    print('Cleaned Response: $cleanedResponse');

    final jsonData = json.decode(cleanedResponse);

    // Safely map JSON -> ExtractedMedicine
    final List<dynamic> rawList = (jsonData['medicines'] as List?) ?? [];
    final extractedList = rawList
        .map((m) => ExtractedMedicine.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    // Save globally for your chat UI buttons
    ExtractedMedicineStorage.setExtractedMedicines(extractedList);

    // ✅ Return properly
    return {
      "medicines": extractedList.map((m) => m.toJson()).toList(),
      "response": jsonData['response'] ?? "Prescription analyzed successfully."
    };
  } catch (e) {
    print('JSON parsing error: $e');
    print('Response text was: $responseText');

    return {
      "medicines": [],
      "response":
          "I analyzed your prescription but could not extract structured medicines. Please verify manually."
    };
  }
}

  // For health report analysis with image
  Future<String> analyzeHealthReportWithImage(
      File imageFile, String? additionalData) async {
    final String base64Image = await _fileToBase64(imageFile);
    final String mimeType = _getMimeType(imageFile.path);

    final prompt = """Analyze this health report image and provide:
1. Key values (BP, cholesterol, blood sugar, etc.)
2. Compare with normal ranges
3. 1-2 actionable suggestions
Maximum 5 sentences.

${additionalData != null ? 'Additional context: $additionalData' : ''}
END""";

    return await _makeApiCall([
      {
        'parts': [
          {'text': prompt},
          {
            'inline_data': {'mime_type': mimeType, 'data': base64Image}
          }
        ]
      }
    ], maxTokens: 300);
  }

  // ✅ Core API call method
  Future<String> _makeApiCall(List<Map<String, dynamic>> contents,
      {int maxTokens = 200}) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=$apiKey');

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'contents': contents,
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': maxTokens,
        'stopSequences': ['END', 'Note:', 'Disclaimer:']
      }
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ??
              'No response generated';
        }
        return 'No candidates found';
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return 'Sorry, I couldn\'t process the image.';
      }
    } catch (e) {
      print('Exception: $e');
      return 'Connection error. Please try again.';
    }
  }

  // Convert file to base64
  Future<String> _fileToBase64(File file) async {
    List<int> imageBytes = await file.readAsBytes();
    return base64Encode(imageBytes);
  }

  // Get MIME type from file extension
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }
}
