
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiProvider {
  final String apiKey;
  GeminiProvider({required this.apiKey});

  // For text-only queries
  Future<String> generateContent(String prompt) async {
    return await _makeApiCall([
      {
        'parts': [{'text': prompt}]
      }
    ]);
  }

  // For prescription image analysis
  Future<String> analyzePrescriptionImage(File imageFile) async {
    final String base64Image = await _fileToBase64(imageFile);
    final String mimeType = _getMimeType(imageFile.path);

    final prompt = """Extract prescription details in this format ONLY:

Medicine Name: [name]
Dosage: [amount]  
Frequency: [times per day]
Duration: [days/weeks]

For each medicine found. If more than 5 medicines, group by category (Heart, Diabetes, etc.). 
No additional explanations needed. END""";

    return await _makeApiCall([
      {
        'parts': [
          {'text': prompt},
          {
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Image
            }
          }
        ]
      }
    ], maxTokens: 400);
  }

  // For health report analysis with image
  Future<String> analyzeHealthReportWithImage(File imageFile, String? additionalData) async {
    final String base64Image = await _fileToBase64(imageFile);
    final String mimeType = _getMimeType(imageFile.path);

    final prompt = """Analyze this health report image and provide:
1. Key values (BP, cholesterol, blood sugar, etc.)
2. Compare with normal ranges
3. 2-3 actionable suggestions
Maximum 5 sentences.

${additionalData != null ? 'Additional context: $additionalData' : ''}
END""";

    return await _makeApiCall([
      {
        'parts': [
          {'text': prompt},
          {
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Image
            }
          }
        ]
      }
    ], maxTokens: 300);
  }

  // Core API call method
  Future<String> _makeApiCall(List<Map<String, dynamic>> contents, {int maxTokens = 200}) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=$apiKey'
    );

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
          return data['candidates'][0]['content']['parts'][0]['text'] 
              ?? 'No response generated';
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
