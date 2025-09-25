import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  static const String _apiKey = "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";
  static const String _apiUrl = "https://openrouter.ai/api/v1/chat/completions";
  static const String _model = "deepseek/deepseek-chat-v3.1:free";

  static Future<String> getHealthTips({
    required double bmi,
    required String category,
    double? height,
    double? weight,
    int? age,
    String? gender,
  }) async {
    try {
      // Create a prompt based on the user's BMI and profile
      String prompt = _generatePrompt(bmi, category, height, weight, age, gender);
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {
              "role": "user",
              "content": prompt
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          return choices[0]['message']['content'].toString().trim();
        } else {
          return "I couldn't generate health tips at the moment. Please try again later.";
        }
      } else {
        return "Sorry, I couldn't generate health tips right now. Please check your connection and try again.";
      }
    } catch (e) {
      // Consider using a proper logging solution in production
      // log('Error getting health tips: $e');
      return "Sorry, I couldn't generate health tips right now. Please try again later.";
    }
  }

  static String _generatePrompt(
    double bmi,
    String category,
    double? height,
    double? weight,
    int? age,
    String? gender,
  ) {
    String userProfile = "Your BMI is ${bmi.toStringAsFixed(1)} which is categorized as $category.";
    
    if (height != null) userProfile += " Your height is ${height}cm.";
    if (weight != null) userProfile += " Your weight is ${weight}kg.";
    if (age != null) userProfile += " You are $age years old.";
    if (gender != null) userProfile += " Your gender is $gender.";
    
    return '''
$userProfile

Based on this information, provide personalized health tips. Include specific recommendations for:
- Diet suggestions
- Exercise routines 
- Lifestyle changes
- Health monitoring advice

Keep the response concise, friendly, and actionable. Format as follows:
- Main health recommendation
- Specific diet advice
- Recommended exercises
- Additional tips

Make the advice age and BMI appropriate.
''';
  }
}