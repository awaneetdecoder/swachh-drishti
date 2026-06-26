import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// WHY this class exists:
// Flutter calls Gemini directly (not through your backend) 
// ONLY for the initial issue analysis before submission.
// This gives instant feedback to the user (3 seconds) 
// without waiting for your server.
class GeminiService {
  
  // WHY --dart-define and not hardcoded:
  // Hardcoded keys end up in your git repo.
  // --dart-define passes the key at BUILD time only.
  // Run: flutter run --dart-define=GEMINI_KEY=your_key_here
  static const String _apiKey = 
      String.fromEnvironment('GEMINI_KEY', defaultValue: '');
  
  // gemini-1.5-flash — WHY this model:
  // 1. It handles images (multimodal)  
  // 2. It's fast (flash = optimized for speed)
  // 3. It's free tier (1500 requests/day)
  static const String _url = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

  // WHY return a Map and not a String:
  // We need structured data (issue type, severity, department)
  // A String gives you one blob of text you can't parse reliably
  // A Map gives you individual fields you can store in your DB
  static Future<Map<String, dynamic>> analyzeIssue(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                // WHY this prompt structure:
                // 1. "Return ONLY valid JSON" — prevents Gemini adding 
                //    markdown ```json``` wrappers that break parsing
                // 2. Specific field names — you control exactly what 
                //    comes back so your Dart code can rely on it
                // 3. Enum values listed — Gemini stays within your 
                //    expected values instead of inventing new ones
                "text": """You are a municipal AI officer analyzing a civic issue photo.
Return ONLY valid JSON with no markdown, no explanation, just the JSON object.

{
  "issueType": "POTHOLE|GARBAGE|BROKEN_LIGHT|WATER_LEAKAGE|ENCROACHMENT|OTHER",
  "severity": "LOW|MEDIUM|HIGH|CRITICAL",
  "urgencyScore": <integer 1-10>,
  "responsibleDepartment": "PWD|MUNICIPAL_CORPORATION|ELECTRICITY_BOARD|WATER_BOARD|TRAFFIC_POLICE",
  "isActuallyCivicIssue": <true|false>,
  "citizenAdvisory": "<one sentence what citizen should know>",
  "estimatedResolutionDays": <integer>,
  "description": "<one sentence describing what you see>"
}"""
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          // WHY temperature 0.1:
          // Lower temperature = more deterministic output
          // We want consistent JSON structure, not creative variation
          "temperature": 0.1,
          "maxOutputTokens": 500
        }
      });

      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final text = decoded['candidates'][0]['content']['parts'][0]['text'] as String;
        
        // WHY trim and clean:
        // Sometimes Gemini adds whitespace or newlines around the JSON
        // jsonDecode fails on ANY extra character outside the braces
        final cleanText = text.trim();
        return jsonDecode(cleanText) as Map<String, dynamic>;
        
      } else {
        // Return a safe fallback so the app doesn't crash
        // The user can still submit, just without AI analysis
        return {
          "issueType": "OTHER",
          "severity": "MEDIUM", 
          "urgencyScore": 5,
          "responsibleDepartment": "MUNICIPAL_CORPORATION",
          "isActuallyCivicIssue": true,
          "citizenAdvisory": "Issue recorded. Manual review will follow.",
          "estimatedResolutionDays": 7,
          "description": "Unable to analyze image automatically."
        };
      }
    } catch (e) {
      return {
        "issueType": "OTHER",
        "severity": "MEDIUM",
        "urgencyScore": 5,
        "responsibleDepartment": "MUNICIPAL_CORPORATION", 
        "isActuallyCivicIssue": true,
        "citizenAdvisory": "Issue recorded.",
        "estimatedResolutionDays": 7,
        "description": "Analysis error: $e"
      };
    }
  }
}