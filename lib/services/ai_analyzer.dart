import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AiAnalyzer {
  // IMPORTANT: Replace with your actual Gemini API Key
  // For better security, use --dart-define to pass this key during build
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  static const String _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=$_apiKey';

  static Future<String> analyzeImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Analyze this image. Is it a garbage dump, a dirty area, or a place with significant litter? Provide a one-sentence verification."
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ]
      });

      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return decodedResponse['candidates'][0]['content']['parts'][0]['text'] ??
            "Analysis complete.";
      } else {
        return "Error: Could not analyze the image. Status code: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: An exception occurred during analysis: $e";
    }
  }
}
